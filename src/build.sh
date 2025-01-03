# fail on all errors
set -e

DOCKERPUSH=0
SMOKETEST=0
BUILD=0
BRANCH=2020

while [ -n "$1" ]; do 
    case "$1" in
    --push) DOCKERPUSH=1 ;;
    --test) SMOKETEST=1 ;;
    --build) BUILD=1 ;;
    esac 
    shift
done

if [ $BUILD -eq 1 ]; then
    docker-compose down
    sudo rm -rf  ./../tmp

    # force remove existing image to all layers rebuild, this is for local environments only. on github 
    # build environment is reset by default
    docker rmi shukriadams/perforce-server:latest -f
    docker rmi shukriadams/perforce-server:latest-$BRANCH -f

    docker build -t shukriadams/perforce-server .
    docker tag shukriadams/perforce-server:latest shukriadams/perforce-server:latest-$BRANCH
    echo "build complete"
else
    echo "build skipped, use --build to enable"
fi

if [ $SMOKETEST -eq 1 ]; then
    docker-compose down
    docker-compose up -d
    sleep 5
    docker logs perforce-test
    echo "test complete, note that this script doesn't yet read for explicit pass flag from container logs"
else
    echo "test skipped, use --test to enable"
fi

if [ $DOCKERPUSH -eq 1 ]; then
    TAG=$(git describe --tags --abbrev=0) 
    docker login -u $DOCKER_USER -p $DOCKER_PASS 
    docker tag shukriadams/perforce-server:latest-$BRANCH shukriadams/perforce-server:$BRANCH-$TAG 
    docker push shukriadams/perforce-server:$BRANCH-$TAG
    echo "Push complete"
else
    echo "push to docker skipped, use --push to enable"
fi

echo "Done!"