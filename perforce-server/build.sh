set -e

docker-compose down

sudo rm -rf  ./../tmp

docker rmi shukriadams/perforce-server:latest -f
docker rmi shukriadams/perforce-server:latest-2020 -f

docker build -t shukriadams/perforce-server .
docker tag shukriadams/perforce-server:latest shukriadams/perforce-server:latest-2020
docker-compose up -d
sleep 5
docker logs perforce-test