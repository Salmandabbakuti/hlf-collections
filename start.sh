echo 'Cloning Test network...'

git clone https://github.com/Salmandabbakuti/hlf-testnet.git


echo "Removing Previous keys from key store..."

rm -rf hfc-key-store


echo 'Clearing  docker containers..'


# DELETE THE OLD DOCKER VOLUMES
sudo docker volume prune

# DELETE OLD DOCKER NETWORKS (OPTIONAL: seems to restart fine without)
sudo docker network prune

echo 'Mounting chaincode..'
cd hlf-testnet
rm -rf chaincode
cd ..
cp -r chaincode hlf-testnet

cd hlf-testnet
chmod a+x generate.sh
chmod a+x start.sh

./generate.sh
./start.sh

sudo docker ps -a


echo 'Installing chaincode..'
sudo docker exec -it cli peer chaincode install -n mycc -v 1.0 -p "/opt/gopath/src/github.com/chaincode/newcc" -l "node"

sudo docker exec -it cli2 peer chaincode install -n mycc -v 1.0 -p "/opt/gopath/src/github.com/chaincode/newcc" -l "node"
sudo docker exec -it cli3 peer chaincode install -n mycc -v 1.0 -p "/opt/gopath/src/github.com/chaincode/newcc" -l "node"


echo 'Instanitating chaincode..'
sudo docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -l "node" -v 1.0 -c '{"Args":[]}' --collections-config "/opt/gopath/src/github.com/chaincode/newcc/collection-config.json" -P "OR ('Org1MSP.member','Org2MSP.member')"

echo 'Getting things ready for Chaincode Invocation..should take only 10 seconds..'
sleep 10
echo 'Adding Product on public ledger..'

sudo docker exec -it cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"addProduct","Args":["publicCollection","MSFTP3","Microsoft Surface Pro3","EliteStores"]}'

echo 'Adding Product on private ledger..'
PRICE=`openssl enc -base64 <<< '228'`

sudo docker exec -it cli2 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"addProduct","Args":["privateCollection","MSFTP3V","Microsoft Surface Pro3","EliteStores"]}' --transient "{\"price\":\"$PRICE\"}"


sleep 6
echo 'Querying Public Product..'
echo 'on Org1..'
sudo docker exec -it cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["publicCollection","MSFTP3"]}'
echo 'on Org2..'
sudo docker exec -it cli2 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["publicCollection","MSFTP3"]}'
echo 'on Org3..'
sudo docker exec -it cli3 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["publicCollection","MSFTP3"]}'

sleep 5
echo 'Querying on Org1 Peer  Private Product..'

sudo docker exec -it cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["privateCollection","MSFTP3V"]}'

echo 'Querying on Org2 Peer  Private Product..'

sudo docker exec -it cli2 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["privateCollection","MSFTP3V"]}'

echo 'Querying on Org3 peer..'
sudo docker exec -it cli3 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"function":"queryProduct","Args":["privateCollection","MSFTP3V"]}'


#Starting docker logs of chaincode container

sudo docker logs -f dev-peer0.org1.example.com-mycc-1.0
