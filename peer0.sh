REST_PORT=7050
USE_PORT=30000
CA_PORT=7054
PEER_gRPC=7051
CONSENSUS_MODE=pbft
PBFT_MODE=batch


echo "--------> Fetching IP address"
IP="$(ifconfig eth0 | grep "inet" | awk '{print $2}' | cut -d ':' -f 2)"
echo "Docker0 interface IP Address $IP"
echo "--------> Fetching PORT number"
PORT="$(sudo netstat -tunlp | grep docker | awk '{print $4'} | cut -d ":" -f 4)"
echo "PORT NUMBER IS $PORT"
docker rm -f $(docker ps -aq)
#echo "--------> Starting membersrvc Server"

#docker run -d --name=caserver -p 7054:7054 -p 50052:7051 -it rameshthoomu/membersrvc:7e20032 membersrvc

echo "--------> Starting hyperledger PEER0"

docker run -d --name=PEER0 -it \
                -e CORE_VM_ENDPOINT="http://$IP:2375" \
                -e CORE_PEER_ID="vp0" \
                -e CORE_SECURITY_ENABLED=true \
                -e CORE_SECURITY_PRIVACY=true \
                -e CORE_PEER_ADDRESSAUTODETECT=false -p $REST_PORT:7050 -p `expr $USE_PORT + 1`:$PEER_gRPC \
                -e CORE_PEER_ADDRESS=$IP:30001 \
                -e CORE_PEER_PKI_ECA_PADDR=172.31.119.241:$CA_PORT \
                -e CORE_PEER_PKI_TCA_PADDR=172.31.119.241:$CA_PORT \
                -e CORE_PEER_PKI_TLSCA_PADDR=172.31.119.241:$CA_PORT \
                -e CORE_PEER_LISTENADDRESS=0.0.0.0:7051 \
                -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=$CONSENSUS_MODE \
                -e CORE_PBFT_GENERAL_N=4 \
                -e CORE_PBFT_GENERAL_K=10 \
                -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=20s \
                -e CORE_LOGGING_LEVEL=debug \
                -e CORE_VM_DOCKER_TLS_ENABLED=false \
                -e CORE_SECURITY_ENROLLID=test_vp0 \
                -e CORE_SECURITY_ENROLLSECRET=MwYpmSRjupbT rameshthoomu/peer:adc1600 peer node start

