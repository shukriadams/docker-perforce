set -e
sudo rm -rf  ./../tmp
docker-compose down
docker build -t shukriadams/perforce-server .
docker tag shukriadams/perforce-server:latest shukriadams/perforce-server:latest-2020
docker-compose up -d
docker logs perforce-test