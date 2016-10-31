# Spinup Local Peer Network

The purpose of this script is to spinup N number of peers on docker environment. This script spins up the peer and membersrvc in docker containers and uses stable peer, membersrvc & base images from https://hub.docker.com/u/hyperledger/

Before execute spinup_peer_network.sh script in your system, make sure your system satisfies the below requirements.

1. Install and configure docker https://github.com/hyperledger/fabric/blob/master/devenv/setup.sh

2. If applicable, verify ufw firewall status in non-vagrant environment. Disable firewall if it is enabled.

  - `sudo ufw status`
  - `sudo ufw disable`

3. Clear `iptables` rules (if firewall rules are rejecting docker requests) and re-start docker daemon.

  - `iptables -L` (to view iptable rules)
  - `iptables -D INPUT 4` (ex: to delete Reject rules from INPUT policy. 4 is the row number to delete)

4. If you do not want to build images manually, skip this step and simply take the image name for the specific commit from above mentioned docker hub account. Build peer and membersrvc images in your local machine using makefile and provide the image name and commit number to spinup_peer_network.sh script.

   Move to directory where the makefile is located (root of the fabric directory) 

    - `cd $GOPATH/src/github.com/hyperledger/fabric`
    - `make images`

###Spinup peers in local network:

Use below script to spinup peers on gerrit code base:

curl [spinup_peer_network.sh](https://raw.githubusercontent.com/hyperledger/fabric/scripts/spinup_peer_network.sh) file into local machine and follow below instructions to run the script.

Example:

`curl -L https://raw.githubusercontent.com/hyperledger/fabric/scripts/spinup_peer_network.sh -o spinup_peer_network.sh`

####Follow below steps:

  - `chmod +x spinup_peer_network.sh`
  - `./spinup_peer_network.sh -n 4 -s -c x86_64-0.6.1-preview -l debug -m pbft` (Check here [Hyperledger Docker hub account](https://hub.docker.com/u/hyperledger/) for gerrit commit tags)
  
####USAGE:
```
./spinup_peer_network.sh -n <number of peers, N> -s -c <specific Commit> -l <Logging detail level> -m <consensus Mode> -f <number of faulty peers, F> -b <batch size>

OPTIONS:

-h/? - Print a usage message
-n   - Number of peers to launch
-s   - Enable Security and Privacy, and start memberservices (caserver)
-c   - Provide Specific peer and membersrvc docker image commit
-l   - Select logging method detail level
-m   - Select consensus mode
-f   - Number of faulty peers allowed in a pbft network (default is max possible value (N-1)/3)
-b   - batch size
 Example: 
./spinup_peer_network.sh -n 4 -s -c x86_64-0.6.1-preview -l debug -m pbft
```
**Reference:**
![4 peer network](peers.PNG)

###Useful Docker Commands:

1. Kill all containers
  - **docker rm $(docker kill $(docker ps -aq))** (user rm -f to force kill)
2. Remove all exited containers
  - **docker ps -aq -f status=exited | xargs docker rm**
3. Remove all Images except 'openblockchain/baseimage'
  - **docker rmi $(docker images | grep -v 'hyperledger/fabric-baseimage:latest' | awk {'print $3'})**
4. Stop Docker container
  - **docker stop Container ID**
5. Start Docker container
  - **docker start Container ID**
6. To know running containers
  - **docker ps**
7. To know all containers (Including active and non-active)
  - **docker ps -a**
9. To view NetworkSettings of a Container
  - **docker inspect Container ID**
10. To View Logs of a Container
  - **docker logs -f Container ID**

## Testing Chaincode in CLI mode:

Execute below command to get into PEER0 docker container `docker exec -it PEER0 bash` and execute below commands to **Register** an user, **Deploy** chaincode, **Invoke** transaction and **Query** transaction commands from container CLI.

### Registering user inside PEER0 container:

`peer network login test_user0` or `peer network login test_user0 -p MS9qrN8hFjlE`

```
root@7efbae933829:/opt/gopath/src/github.com/hyperledger/fabric# peer network login test_user0
2016/07/23 00:51:09 Load docker HostConfig: %+v &{[] [] []  [] false map[] [] false [] [] [] [] host    { 0} [] { map[]} false []  0 0 0 false 0    0 0 0 []}
00:51:09.492 [crypto] main -> INFO 002 Log level recognized 'info', set to INFO
00:51:09.493 [main] networkLogin -> INFO 003 CLI client login...
00:51:09.493 [main] networkLogin -> INFO 004 Local data store for client loginToken: /var/hyperledger/production/client/
Enter password for user 'test_user0': ************
00:51:14.863 [main] networkLogin -> INFO 005 Logging in user 'test_user0' on CLI interface...
00:51:15.374 [main] networkLogin -> INFO 006 Storing login token for user 'test_user0'.
00:51:15.374 [main] networkLogin -> INFO 007 Login successful for user 'test_user0'.
00:51:15.374 [main] main -> INFO 008 Exiting.....
```

### Deploy Chaincode:

Once user is registered, execute the below command to deploy chaincode on PEER0. Below command is to deploy chaincode on PEER0 where peer is running with security & privacy enabled.

```
peer chaincode deploy -u test_user0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Args": ["init","a", "100", "b", "200"]}'
```
After deploy is successfully executed it creates a chaincode ID.
```
ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539
```
### Invoke Chaincode:

Submit Invoke transaction using the above chaincode ID:

```
peer chaincode invoke -u test_user0 -n ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539 -c '{"Args": ["invoke", "a", "b", "10"]}'
```
### Query Chaincode:

Submit Query Transaction using chaincode

```
peer chaincode query -u test_user0 -n ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539 -c '{"Args": ["query", "a"]}'
```

### Modify existing configuration settings of core.yaml in peer docker image:

## 1. Pull images from DockerHub:

First, pull latest peer and membersrvc images or pull specific commit docker images from [Docker Hub](https://hub.docker.com/u/hyperledger/)

```
  docker pull hyperledger/fabric-peer
  docker pull hyperledger/fabric-membersrvc
```

Once the images are pulled from dockerhub, follow below process to modify configuration files of peer image.

List out all the docker images whcih are available in your system:

**docker images**

```
dev-vp3-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539   latest                 16ae0dc9c15a        3 minutes ago       1.353 GB
dev-vp1-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539   latest                 7760a29b05cc        3 minutes ago       1.353 GB
dev-vp0-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539   latest                 49785a72adcf        3 minutes ago       1.353 GB
dev-vp2-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539   latest                 686ee915990b        3 minutes ago       1.353 GB
hyperledger/fabric-baseimage                                                                                                               latest                 5073cec7e9eb        10 days ago         1.318 GB
hyperledger/fabric-baseimage                                                                                                               x86_64-0.2.0           5073cec7e9eb        10 days ago         1.318 GB
hyperledger/fabric-membersrvc                                                                                                              x86_64-0.6.1-preview   b3654d32e4f9        12 days ago         1.417 GB
hyperledger/fabric-peer                                                                                                                    x86_64-0.6.1-preview   21cb00fb27f4        12 days ago         1.424 GB
busybox                                                                                                                                    latest                 e02e811dd08f        3 weeks ago         1.093 MB
```

### 2. Run Docker Image

Specify the ImageID or Imagename from the output of the above command

`docker run -it <imageID> or <image name> bash`

ex: `docker run -it hyperledge/fabric bash` or `docker run -it 895b42b528a6 bash`

### 3. Saving changes inside Container

Above command takes you to the container, modify any file inside container ex: `core.yaml` file and press `CTRL + P + Q`. In docker, CTRL + P + Q runs the container in background mode or detached mode and automatically exit from the container.

Execute `docker ps` command to see the container running in detached mode. Take the container ID or container name and execute the below command

`docker commit <ContainerID> <NewImageName>`

Keep the above new Imagename in spinup_peer_network.sh script and execute the script.
