docker rm -f caserver
docker run -d --name=caserver -p 7054:7054 -p 50052:7051 -it rameshthoomu/membersrvc:adc1600 membersrvc

