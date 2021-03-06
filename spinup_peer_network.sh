#!/bin/bash

set -e

ARCH=`uname -m`
echo "ARCH value is" $ARCH
if [ $ARCH = "ppc64le" ]
then
    PEER_IMAGE=hyperledger/fabric-peer-ppc64le
    MEMBERSRVC_IMAGE=hyperledger/fabric-membersrvc-ppc64le
    docker pull hyperledger/fabric-ppc64le-baseimage:ppc64le-0.2.0
    docker tag hyperledger/fabric-ppc64le-baseimage:ppc64le-0.2.0 hyperledger/fabric-baseimage:latest
fi

if [ "$ARCH" == "x86_64" ]
then
    PEER_IMAGE=hyperledger/fabric-peer
    MEMBERSRVC_IMAGE=hyperledger/fabric-membersrvc
    docker pull hyperledger/fabric-baseimage:x86_64-0.2.0
    docker tag hyperledger/fabric-baseimage:x86_64-0.2.0 hyperledger/fabric-baseimage:latest
fi

if [ "$ARCH" == "s390x" ]
then
    PEER_IMAGE=hyperledger/fabric-peer-s390x
    MEMBERSRVC_IMAGE=hyperledger/fabric-membersrvc-s390x
    docker pull hyperledger/fabric-s390x-baseimage:s390x-0.0.10
    docker tag hyperledger/fabric-s390x-baseimage:s390x-0.0.10 hyperledger/fabric-baseimage:latest
fi

REST_PORT=7050
USE_PORT=30000
CA_PORT=7054
PEER_gRPC=7051
EVENT_PORT=40000
PBFT_MODE=batch
WORKDIR=$(pwd)

# Membersrvc
membersrvc_setup()
{
curl -L https://raw.githubusercontent.com/hyperledger/fabric/v0.6/membersrvc/membersrvc.yaml -o membersrvc.yaml
local NUM_PEERS=$1
local IP=$2
local PORT=$3
echo "--------> Starting membersrvc Server"

docker run -d --name=caserver -p $CA_PORT:$CA_PORT -e MEMBERSRVC_CA_LOGGING_SERVER=$LOG_LEVEL --volume=/tmp/docker:/tmp/docker -p 50052:7051 -it $MEMBERSRVC_IMAGE:$COMMIT membersrvc

sleep 10

CA_CONTAINERID=$(docker ps | awk '{print $1}' | awk 'NR==2')
CA_IP_ADDRESS=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CA_CONTAINERID)

echo "--------> Starting PEER0"

docker run -d --name=PEER0 -it \
                -e CORE_VM_ENDPOINT="http://$IP:$PORT" \
                -e CORE_PEER_ID="vp0" \
                -e CORE_SECURITY_ENABLED=true \
                -e CORE_SECURITY_PRIVACY=true \
                -e CORE_PEER_ADDRESSAUTODETECT=true -p $REST_PORT:7050 -p `expr $USE_PORT + 1`:$PEER_gRPC -p `expr $EVENT_PORT + 1`:7053 \
                -e CORE_PEER_PKI_ECA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_PKI_TCA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_PKI_TLSCA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_LISTENADDRESS=0.0.0.0:$PEER_gRPC \
                -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=$CONSENSUS_MODE \
                -e CORE_PBFT_GENERAL_MODE=$PBFT_MODE \
                -e CORE_PBFT_GENERAL_N=$NUM_PEERS \
                -e CORE_PBFT_GENERAL_F=$F \
                -e CORE_PBFT_GENERAL_BATCHSIZE=$PBFT_BATCHSIZE \
                -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s \
                -e CORE_PEER_LOGGING_LEVEL=$LOG_LEVEL \
                -e CORE_LOGGING_LEVEL=$LOG_LEVEL \
                -e CORE_VM_DOCKER_TLS_ENABLED=false \
                --volume=/tmp/docker:/tmp/docker \
                -e CORE_PEER_PROFILE_ENABLED=true \
                -e CORE_SECURITY_ENROLLID=test_vp0 \
                -e CORE_SECURITY_ENROLLSECRET=MwYpmSRjupbT $PEER_IMAGE:$COMMIT peer node start

CONTAINERID=$(docker ps | awk '{print $1}' | awk 'NR==2')
echo $CONTAINERID
PEER_IP_ADDRESS=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CONTAINERID)
echo $PEER_IP_ADDRESS
for (( peer_id=1; $peer_id<"$NUM_PEERS"; peer_id++ ))
do
# Storing USER_NAME and SECRET_KEY Values from membersrvc.yaml file:

USER_NAME=$(awk '/users:/,/^[^ ]/' membersrvc.yaml | egrep "test_vp$((peer_id)):" | cut -d ":" -f 1 | tr -d " ")
echo $USER_NAME
SECRET_KEY=$(awk '/users:/,/^[^ ]/' membersrvc.yaml | egrep "test_vp$((peer_id)):" | cut -d ":" -f 2 | cut -d " " -f 3)
echo $SECRET_KEY
REST_PORT=`expr $REST_PORT + 10`
USE_PORT=`expr $USE_PORT + 2`
EVENT_PORT=`expr $EVENT_PORT + 2`

echo "--------> Starting PEER$peer_id <-----------"
docker run  -d --name=PEER$peer_id -it \
                -e CORE_VM_ENDPOINT="http://$IP:$PORT" \
                -e CORE_PEER_ID="vp"$peer_id \
                -e CORE_SECURITY_ENABLED=true \
                -e CORE_SECURITY_PRIVACY=true \
                -e CORE_PEER_ADDRESSAUTODETECT=true -p $REST_PORT:7050 -p `expr $USE_PORT + 1`:$PEER_gRPC -p `expr $EVENT_PORT + 1`:7053 \
                -e CORE_PEER_DISCOVERY_ROOTNODE=$PEER_IP_ADDRESS:$PEER_gRPC \
                -e CORE_PEER_PKI_ECA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_PKI_TCA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_PKI_TLSCA_PADDR=$CA_IP_ADDRESS:$CA_PORT \
                -e CORE_PEER_LISTENADDRESS=0.0.0.0:$PEER_gRPC \
                -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=$CONSENSUS_MODE \
                -e CORE_PBFT_GENERAL_MODE=$PBFT_MODE \
                -e CORE_PBFT_GENERAL_N=$NUM_PEERS \
                -e CORE_PBFT_GENERAL_F=$F \
                -e CORE_PBFT_GENERAL_BATCHSIZE=$PBFT_BATCHSIZE \
                -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s \
                -e CORE_PEER_LOGGING_LEVEL=$LOG_LEVEL \
                -e CORE_LOGGING_LEVEL=$LOG_LEVEL \
                --volume=/tmp/docker:/tmp/docker \
                -e CORE_VM_DOCKER_TLS_ENABLED=false \
                -e CORE_PEER_PROFILE_ENABLED=true \
                -e CORE_SECURITY_ENROLLID=$USER_NAME \
                -e CORE_SECURITY_ENROLLSECRET=$SECRET_KEY $PEER_IMAGE:$COMMIT peer node start
done
}
# Peer Setup without security and privacy
peer_setup()
{
    local  NUM_PEERS=$1
    local  IP=$2
    local  PORT=$3
echo "--------> Starting hyperledger PEER0 <-----------"
docker run -d  -it --name=PEER0 \
                -e CORE_VM_ENDPOINT="http://$IP:$PORT" \
                -e CORE_PEER_ID="vp0" \
                -p $REST_PORT:7050 -p `expr $USE_PORT + 1`:$PEER_gRPC -p `expr $EVENT_PORT + 1`:7053 \
                -e CORE_PEER_ADDRESSAUTODETECT=true \
                -e CORE_PEER_LISTENADDRESS=0.0.0.0:$PEER_gRPC \
                -e CORE_PEER_LOGGING_LEVEL=$LOG_LEVEL \
                -e CORE_LOGGING_LEVEL=$LOG_LEVEL \
                --volume=/tmp/docker:/tmp/docker \
                -e CORE_VM_DOCKER_TLS_ENABLED=false $PEER_IMAGE:$COMMIT peer node start

CONTAINERID=$(docker ps | awk 'NR>1 && $NF!~/caserv/ {print $1}')
PEER_IP_ADDRESS=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CONTAINERID)

for (( peer_id=1; peer_id<"$NUM_PEERS"; peer_id++ ))
do
echo "--------> Starting hyperledger PEER$peer_id <------------"
REST_PORT=`expr $REST_PORT + 10`
USE_PORT=`expr $USE_PORT + 2`
EVENT_PORT=`expr $EVENT_PORT + 2`

docker run -d -it --name=PEER$peer_id \
                -e CORE_VM_ENDPOINT="http://$IP:$PORT" \
                -e CORE_PEER_ID="vp"$peer_id \
                -p $REST_PORT:7050 -p `expr $USE_PORT + 1`:$PEER_gRPC -p `expr $EVENT_PORT + 1`:7053 \
                -e CORE_PEER_DISCOVERY_ROOTNODE=$PEER_IP_ADDRESS:$PEER_gRPC \
                -e CORE_PEER_ADDRESSAUTODETECT=true \
                -e CORE_PEER_ADDRESS=$IP:`expr $USE_PORT + 1` \
                -e CORE_PEER_LISTENADDRESS=0.0.0.0:$PEER_gRPC \
                -e CORE_PEER_LOGGING_LEVEL=$LOG_LEVEL \
                -e CORE_LOGGING_LEVEL=$LOG_LEVEL \
                --volume=/tmp/docker:/tmp/docker \
                -e CORE_VM_DOCKER_TLS_ENABLED=false $PEER_IMAGE:$COMMIT peer node start
done
}

function usage()
{
        echo "USAGE :  spinup_peer_network -n <number of Peers> -s <for enabling security and privacy> -c <commit number> -l <logging level> -m <consensus mode> -f <faulty peers tolerated> -b <batchsize>"
        echo "ex: ./spinup_peer_network -n 4 -s -c x86_64-0.6.0-SNAPSHOT-f3c9a45 -l debug -m pbft -f 1 -b 500"
}

while getopts "\?hsn:c:l:m:b:f:" option; do
  case "$option" in
     s)   SECURITY="Y"     ;;
     n)   NUM_PEERS="$OPTARG" ;;
     c)   COMMIT="$OPTARG"  ;;
     l)   PEER_LOG="$OPTARG" ;;
     m)   CONSENSUS_MODE="$OPTARG" ;;
     b)   PBFT_BATCHSIZE="$OPTARG" ;;
     f)   F="$OPTARG" ;;
   \?|h)  usage
          exit 1
          ;;
  esac
done

# kill all running containers and LOGFILES...Yet to implement Log rotate logic

docker ps -aq -f status=paused | xargs docker unpause  1>/dev/null 2>&1
docker kill $(docker ps -q) 1>/dev/null 2>&1
docker ps -aq -f status=exited | xargs docker rm 1>/dev/null 2>&1
rm -f LOGFILE_*
docker rm -f $(docker ps -aq)
rm -rf /var/hyperledger/*

# echo "--------> Setting default Arg values that were not specified on the command line"
: ${SECURITY:="N"}
: ${NUM_PEERS="4"}
: ${COMMIT="latest"}
: ${LOG_LEVEL="debug"}
: ${CONSENSUS_MODE="pbft"}
: ${PBFT_BATCHSIZE="500"}
: ${F:=$((($NUM_PEERS-1)/3))} # set F default to max possible F value (N-1)/3 here when F was not specified in the command line
SECURITY=$(echo $SECURITY | tr a-z A-Z)

echo "Number of PEERS (N): $NUM_PEERS"
if [ $NUM_PEERS -le 0 ] ; then
        echo "Must enter valid number of PEERS"
        exit 1
fi

echo "Number of Faulty Peers Tolerated (F): $F"
if [ $NUM_PEERS -le $F ] ; then
        echo "Warning: F should be <= (N-1)/3 for pbft, and certainly must be less than N. Test proceeding anyways to see what the code does with it..."
fi

echo "Is Security and Privacy enabled: $SECURITY"

echo "--------> Pulling Base Docker Images from Docker Hub"

# Fetching docker environment details

docker_setup()

{
        docker -v
 if [ "$(echo $?)" == "127" ]; then
        echo "Docker is not installed. Install docker-engine"
 else
         echo "--------> Fetching IP address"
         IP="$(ifconfig docker0 | grep "inet" | awk '{print $2}' | cut -d ':' -f 2)"
         echo "Docker0 interface IP Address $IP"
         echo "--------> Fetching PORT number"
         PORT="$(sudo netstat -tunlp | grep docker | awk '{print $4'} | cut -d ":" -f 4)"
         echo "Docker Interface PORT number $PORT"
           
           if [ $PORT != "2375" ]; then
              echo "DOCKER_OPTS=\"-s=aufs -r=true --api-cors-header='*' -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock \"" > /etc/default/docker
              source /etc/default/docker
              if [ $? -ne 0 ]; then
                 echo "error in sourcing /etc/default/docker... Try with sudo"
                 exit 1
              fi
              echo "Restarting Docker"
              sudo service docker restart
              sleep 5
              PORT="$(sudo netstat -tunlp | grep docker | awk '{print $4'} | cut -d ":" -f 4)"
              if [ $PORT != "2375" ]; then
                 echo "Unable to set the Docker port. Do it manually"
                 exit 1
              fi
           fi
   fi
}

if [ "$SECURITY" == "Y" ] ; then
           echo "--------> Spinup peer and membersrvc network"
           docker_setup
           membersrvc_setup $NUM_PEERS $IP $PORT
else
           echo "--------> Spinup peer network without security and Privary"
           docker_setup
           peer_setup $NUM_PEERS $IP $PORT
fi

echo "--------> Printing list of Docker Containers"
CONTAINERS=$(docker ps | awk 'NR>1 && $NF!~/caserv/ {print $1}')
echo CONTAINERS: $CONTAINERS
NUM_CONTAINERS=$(echo $CONTAINERS | awk '{FS=" "}; {print NF}')
echo NUM_CONTAINERS: $NUM_CONTAINERS
if [ $NUM_CONTAINERS -lt $NUM_PEERS ]
then
    echo "ERROR: NOT ALL THE CONTAINERS ARE RUNNING!!! Displaying debug info..."
    echo "docker ps -a"
    docker ps -a
fi

# Printing Log files
for (( container_id=1; $container_id<="$((NUM_CONTAINERS))"; container_id++ ))
do
        CONTAINER_ID=$(echo $CONTAINERS | awk -v con_id=$container_id '{print $con_id}')
        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID |  sed 's/\///')
        docker logs -f $CONTAINER_ID > "LOGFILE_$CONTAINER_NAME"_"$CONTAINER_ID" &
done

# Writing Peer data into networkcredentails file

cd $WORKDIR
echo "creating networkcredentials file"
touch networkcredentials
echo "{" > $WORKDIR/networkcredentials
echo "   \"PeerData\" :  [" >> $WORKDIR/networkcredentials
echo " "
echo "PeerData : "

echo "----------> Printing Container ID's with IP Address and PORT numbers"
REST_PORT=7050

for (( container_id=$NUM_CONTAINERS; $container_id>=1; container_id-- ))
do

        CONTAINER_ID=$(echo $CONTAINERS | awk -v con_id=$container_id '{print $con_id}')
        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID |  sed 's/\///')
        echo "Container ID $CONTAINER_ID   Peer Name: $CONTAINER_NAME"
        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID |  sed 's/\///')
        peer_http_ip=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CONTAINER_ID)
        api_host=$peer_http_ip
        api_port=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "7050/tcp") 0).HostPort}}' $CONTAINER_ID)
        echo "   { \"name\" : \"$CONTAINER_NAME\", \"api-host\" : \"$api_host\", \"api-port\" : \"$REST_PORT\" } , " >> $WORKDIR/networkcredentials

        echo " REST_EndPoint : $api_host:$api_port"
        api_port_grpc=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "7051/tcp") 0).HostPort}}' $CONTAINER_ID)
        echo " GRPC_EndPoint : $api_host:$api_port_grpc"
        api_port_event=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "7053/tcp") 0).HostPort}}' $CONTAINER_ID)
        echo " EVENT_EndPoint : $api_host:$api_port_event"
        echo " "

done
        sed  -i '$s/,[[:blank:]]*$//' $WORKDIR/networkcredentials

        echo "   ],"  >> $WORKDIR/networkcredentials

# Writing UserData into networkcredentails file
if [ "$SECURITY" == "Y" ] ; then

echo "   \"UserData\" :  [" >> $WORKDIR/networkcredentials

        echo " "

echo "Client Credentials : "
echo " "
        for ((i=0; i<=$NUM_CONTAINERS-1;i++))
        do
        CLIENT_USER=$(awk '/users:/,/^[^ #]/' membersrvc.yaml | egrep "test_user$((i)):" | cut -d ":" -f 1 | tr -d " ")
        CLIENT_SECRET_KEY=$(awk '/users:/,/^[^ #]/' membersrvc.yaml | egrep "test_user$((i)):" | cut -d ":" -f 2 | cut -d " " -f 3)
        echo "username: $CLIENT_USER  secretkey : $CLIENT_SECRET_KEY"
        echo "   { \"username\" : \"$CLIENT_USER\", \"secret\" : \"$CLIENT_SECRET_KEY\" } , " >> $WORKDIR/networkcredentials

done

        sed  -i '$s/,[[:blank:]]*$//' $WORKDIR/networkcredentials

        echo "   ],"  >> $WORKDIR/networkcredentials
fi
# Writing PeerGrpc Data into networkcredential file for go SDK

if [ "$SECURITY" == "Y" ] ; then

echo "   \"EventPorts\" :  [" >> $WORKDIR/networkcredentials
        echo " "
for (( container_id=$NUM_CONTAINERS; $container_id>=1; container_id-- ))
do

        CONTAINER_ID=$(echo $CONTAINERS | awk -v con_id=$container_id '{print $con_id}')
        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID |  sed 's/\///')
        peer_http_ip=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CONTAINER_ID)
        api_host=$peer_http_ip
        api_port_event=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "7053/tcp") 0).HostPort}}' $CONTAINER_ID)
        echo "   { \"api-host\" : \"$api_host\", \"api-port-event\" : \"$api_port_event\" } , " >> $WORKDIR/networkcredentials
done
        sed  -i '$s/,[[:blank:]]*$//' $WORKDIR/networkcredentials

        echo "   ],"  >> $WORKDIR/networkcredentials
fi
# Writing Grpc details into networkcredentials file
echo "   \"PeerGrpc\" :  [" >> $WORKDIR/networkcredentials
        echo " "

for (( container_id=$NUM_CONTAINERS; $container_id>=1; container_id-- ))
do

        CONTAINER_ID=$(echo $CONTAINERS | awk -v con_id=$container_id '{print $con_id}')
        CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID |  sed 's/\///')
        peer_http_ip=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $CONTAINER_ID)
        api_host=$peer_http_ip
        api_port_grpc=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "7051/tcp") 0).HostPort}}' $CONTAINER_ID)
        echo "   { \"api-host\" : \"$api_host\", \"api-port\" : \"$api_port_grpc\" } , " >> $WORKDIR/networkcredentials
done
        sed  -i '$s/,[[:blank:]]*$//' $WORKDIR/networkcredentials

        echo "   ],"  >> $WORKDIR/networkcredentials

        echo " \"Name\": \"spinup_peer_network\" " >> $WORKDIR/networkcredentials
        echo "} "  >> $WORKDIR/networkcredentials
