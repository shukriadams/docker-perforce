# fail on all errors
set -e

DOCKERPUSH=0
SMOKETEST=0
BUILD=1
BRANCH=2020

while [ -n "$1" ]; do 
    case "$1" in
    --dockerpush) DOCKERPUSH=1 ;;
    --test) SMOKETEST=1 ;;
    --nobuild) BUILD=0 ;;
    esac 
    shift
done

if [ $BUILD -eq 1 ]; then
    cd perforce-server
    docker-compose down
    sudo rm -rf  ./../tmp

    # force remove existing image to all layers rebuild, this is for local environments only. on github 
    # build environment is reset by default
    docker rmi shukriadams/perforce-server:latest -f
    docker rmi shukriadams/perforce-server:latest-$BRANCH -f

    docker build -t shukriadams/perforce-server .
    docker tag shukriadams/perforce-server:latest shukriadams/perforce-server:latest-$BRANCH
    cd -
fi

if [ $SMOKETEST -eq 1 ]; then
    cd perforce-server
    docker-compose down
    docker-compose up -d
    sleep 5
    docker logs perforce-test
    cd -
fi

if [ $DOCKERPUSH -eq 1 ]; then
    TAG=$(git describe --tags --abbrev=0) 
    docker login -u $DOCKER_USER -p $DOCKER_PASS 
    docker tag shukriadams/perforce-server:latest-$BRANCH shukriadams/perforce-server:$BRANCH-$TAG 
    docker push shukriadams/perforce-server:$BRANCH-$TAG

    echo "Push complete"
fi
