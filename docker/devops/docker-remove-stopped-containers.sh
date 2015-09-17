#docker rm $(docker ps -a | grep Exited | awk '{print $1}')
docker rm -v $(docker ps -a -q -f status=exited)
