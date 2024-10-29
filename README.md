# gwyneth-mono

## To Run
Spin up a local network:
```
$ make install
```
This will setup 2 CL nodes with 2 EL nodes. The EL nodes each sync for two Gwyneth L2 networks, which synchronousely compose with each other, in addition to a rbuilder instance that builds both L2 chains. The rbuilder attaches to the first EL node similar to the MEV setup (without relays).
```
========================================== User Services ==========================================
UUID           Name                                             Ports                                                  Status
4d67bb4dd33e   blockscout-gwyneth-160010-postgres               postgresql: 5432/tcp -> postgresql://127.0.0.1:56603   RUNNING
d9b8ef46debb   cl-1-lighthouse-gwyneth                          http: 4000/tcp -> http://127.0.0.1:56584               RUNNING
                                                                metrics: 5054/tcp -> http://127.0.0.1:56585            
                                                                tcp-discovery: 9000/tcp -> 127.0.0.1:56586             
                                                                udp-discovery: 9000/udp -> 127.0.0.1:55988             
0768a915bb82   cl-2-teku-gwyneth                                http: 4000/tcp -> http://127.0.0.1:56588               RUNNING
                                                                metrics: 8008/tcp -> http://127.0.0.1:56589            
                                                                tcp-discovery: 9000/tcp -> 127.0.0.1:56587             
                                                                udp-discovery: 9000/udp -> 127.0.0.1:56075             
abb6e99b8769   el-1-gwyneth-lighthouse                          engine-rpc: 8551/tcp -> 127.0.0.1:32001                RUNNING
                                                                l2-rpc-160010: 10110/tcp -> 127.0.0.1:32005            
                                                                l2-rpc-160011: 10111/tcp -> 127.0.0.1:32006            
                                                                metrics: 9001/tcp -> http://127.0.0.1:32004            
                                                                rpc: 8545/tcp -> 127.0.0.1:32002                       
                                                                tcp-discovery: 32000/tcp -> 127.0.0.1:32000            
                                                                udp-discovery: 32000/udp -> 127.0.0.1:32000            
                                                                ws: 8546/tcp -> 127.0.0.1:32003                        
07d64b0239ec   el-2-gwyneth-teku                                engine-rpc: 8551/tcp -> 127.0.0.1:32008                RUNNING
                                                                l2-rpc-160010: 10110/tcp -> 127.0.0.1:32012            
                                                                l2-rpc-160011: 10111/tcp -> 127.0.0.1:32013            
                                                                metrics: 9001/tcp -> http://127.0.0.1:32011            
                                                                rpc: 8545/tcp -> 127.0.0.1:32009                       
                                                                tcp-discovery: 32007/tcp -> 127.0.0.1:32007            
                                                                udp-discovery: 32007/udp -> 127.0.0.1:32007            
                                                                ws: 8546/tcp -> 127.0.0.1:32010                        
bdcf74e73990   rbuilder-el-1-gwyneth-lighthouse                 <none>                                                 RUNNING
14176943d20d   validator-key-generation-cl-validator-keystore   <none>                                                 RUNNING
42f77bc618f6   vc-1-gwyneth-lighthouse                          metrics: 8080/tcp -> http://127.0.0.1:56602            RUNNING
```
Then deploy Gwyneth protocol and proceed proposing blocks for both L2s. This will also deploy helper contracts and several examples to call the `XCallOptions` precompiles, enabling synchronous composibility.
```
$ make deploy
```
Btw sometimes L1 regorgs and we don't have implementation to hanle that on L2s, so just relaunch the whole thing.
Have fun 🍻.
## To Build
If you change something and want to rebuild the images:
```
$ docker build . -t gwyneth-reth -f reth/Dockerfile
$ docker build . -t gwyneth-rbuilder -f rbuilder/Dockerfile
```
