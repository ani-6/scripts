#!/bin/bash

# get all running docker container names
containers=$(sudo docker ps | awk '{if(NR>1) print $NF}')
host=$(hostname)

for container in $containers
    do
        echo "Container: $container"
        id=$(docker inspect --format="{{.Id}}" $container)
        echo $id
        docker export $id > $container.tar
    done