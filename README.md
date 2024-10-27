# gwyneth-mono
To run this shit:
1. pull all submodules
2. build the images from the project directory
```
$ docker build . -t gwyneth-rbuilder -f rbuilder/Dockerfile
$ docker build . -t gwyneth-reth -f reth/Dockerfile 
```
3. run kurtosis
```
$ kurtosis run .  --args-file network_params_l2.yaml   
```
