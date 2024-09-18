use std::{sync::Arc, time::Duration};

use crate::{
    building::{
        builders::{
            BlockBuildingAlgorithm, BlockBuildingAlgorithmInput, UnfinishedBlockBuildingSinkFactory,
        },
        BlockBuildingContext,
    },
    live_builder::{payload_events::MevBoostSlotData, simulation::SlotOrderSimResults},
    utils::ProviderFactoryReopener,
};
use reth_db::database::Database;
use tokio::sync::{broadcast, mpsc};
use tokio_util::sync::CancellationToken;
use tracing::{debug, error, trace};

use super::{
    order_input::{
        self, order_replacement_manager::OrderReplacementManager, orderpool::OrdersForBlock,
    },
    payload_events,
    simulation::OrderSimulationPool,
};

use std::collections::HashMap;
use ethers::{
    prelude::*,
    types::{Bytes, H256, U256, Address as EthersAddress},
    providers::{Http as EthersHttp, Provider as EthersProvider},
};

#[derive(Debug)]
pub struct BlockBuildingPool<DB> {
    provider_factory: ProviderFactoryReopener<DB>,
    builders: Vec<Arc<dyn BlockBuildingAlgorithm<DB>>>,
    sink_factory: Box<dyn UnfinishedBlockBuildingSinkFactory>,
    orderpool_subscriber: order_input::OrderPoolSubscriber,
    order_simulation_pool: OrderSimulationPool<DB>,
}

impl<DB: Database + Clone + 'static> BlockBuildingPool<DB> {
    pub fn new(
        provider_factory: ProviderFactoryReopener<DB>,
        builders: Vec<Arc<dyn BlockBuildingAlgorithm<DB>>>,
        sink_factory: Box<dyn UnfinishedBlockBuildingSinkFactory>,
        orderpool_subscriber: order_input::OrderPoolSubscriber,
        order_simulation_pool: OrderSimulationPool<DB>,
    ) -> Self {
        BlockBuildingPool {
            provider_factory,
            builders,
            sink_factory,
            orderpool_subscriber,
            order_simulation_pool,
        }
    }

    /// Connects OrdersForBlock->OrderReplacementManager->Simulations and calls start_building_job
    pub fn start_block_building(
        &mut self,
        payload: payload_events::MevBoostSlotData,
        block_ctx: BlockBuildingContext,
        global_cancellation: CancellationToken,
        max_time_to_build: Duration,
    ) {
        let block_cancellation = global_cancellation.child_token();

        let cancel = block_cancellation.clone();
        tokio::spawn(async move {
            tokio::time::sleep(max_time_to_build).await;
            cancel.cancel();
        });

        let (orders_for_block, sink) = OrdersForBlock::new_with_sink();
        // add OrderReplacementManager to manage replacements and cancellations
        let order_replacement_manager = OrderReplacementManager::new(Box::new(sink));
        // sink removal is automatic via OrderSink::is_alive false
        let _block_sub = self.orderpool_subscriber.add_sink(
            block_ctx.block_env.number.to(),
            Box::new(order_replacement_manager),
        );

        let simulations_for_block = self.order_simulation_pool.spawn_simulation_job(
            block_ctx.clone(),
            orders_for_block,
            block_cancellation.clone(),
        );
        self.start_building_job(
            block_ctx,
            payload,
            simulations_for_block,
            block_cancellation,
        );
    }

    /// Per each BlockBuildingAlgorithm creates BlockBuildingAlgorithmInput and Sinks and spawn a task to run it
    fn start_building_job(
        &mut self,
        ctx: BlockBuildingContext,
        slot_data: MevBoostSlotData,
        input: SlotOrderSimResults,
        cancel: CancellationToken,
    ) {
        // Brecht: start building
        let builder_sink = self.sink_factory.create_sink(slot_data, cancel.clone());
        let (broadcast_input, _) = broadcast::channel(10_000);

        let block_number = ctx.block_env.number.to::<u64>();
        let provider_factory = match self
            .provider_factory
            .check_consistency_and_reopen_if_needed(block_number)
        {
            Ok(provider_factory) => provider_factory,
            Err(err) => {
                error!(?err, "Error while reopening provider factory");
                return;
            }
        };

        for builder in self.builders.iter() {
            let builder_name = builder.name();
            debug!(block = block_number, builder_name, "Spawning builder job");
            let input = BlockBuildingAlgorithmInput::<DB> {
                provider_factory: provider_factory.clone(),
                ctx: ctx.clone(),
                input: broadcast_input.subscribe(),
                sink: builder_sink.clone(),
                cancel: cancel.clone(),
            };
            let builder = builder.clone();
            tokio::task::spawn_blocking(move || {
                builder.build_blocks(input);
                debug!(block = block_number, builder_name, "Stopped builder job");
            });
        }

        tokio::spawn(multiplex_job(input.orders, broadcast_input));
    }
}

async fn multiplex_job<T>(mut input: mpsc::Receiver<T>, sender: broadcast::Sender<T>) {
    // we don't worry about waiting for input forever because it will be closed by producer job
    while let Some(input) = input.recv().await {
        // we don't create new subscribers to the broadcast so here we can be sure that err means end of receivers
        if sender.send(input).is_err() {
            return;
        }
    }
    trace!("Cancelling multiplex job");
}

pub struct Layer2Info {
    // chain_id to rpc_url mapping
    // Later can be reconfigured to use unix ipc socket
    rpc_urls: HashMap<U256, String>,
}

impl Layer2Info {
    pub async fn new(urls: Vec<String>) -> Result<Self, Box<dyn std::error::Error>> {
        let mut rpc_urls = HashMap::new();

        for url in urls {
            let provider = EthersProvider::<EthersHttp>::try_from(url.as_str())?;
            let chain_id = provider.get_chainid().await?;
            rpc_urls.insert(chain_id, url);
        }

        Ok(Self { rpc_urls })
    }

    pub async fn get_latest_block(&self, chain_id: U256) -> Result<Option<Block<H256>>, Box<dyn std::error::Error>> {
        if let Some(url) = self.rpc_urls.get(&chain_id) {
            let provider = EthersProvider::<EthersHttp>::try_from(url.as_str())?;
            println!("Dani debug: in get_latest_block before get_block");
            let latest_block = provider.get_block(BlockNumber::Latest).await?;
            println!("Dani debug: in get_latest_block after get_block");
            Ok(latest_block)
        } else {
            Ok(None)
        }
    }
}