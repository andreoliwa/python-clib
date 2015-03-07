#!/bin/bash
echo '# Remove all containers'
echo 'docker rm -f $(docker ps -q -a)'
echo
echo '# Remove all images'
echo 'docker rmi -f $(docker images -q -a)'
