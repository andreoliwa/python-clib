#!/bin/bash
echo '# Remove all containers'
echo 'docker ps -q -a | xargs docker rm -f'
echo
echo '# Remove all images'
echo 'docker images -q -a | xargs docker rmi -f'
echo
echo '# Remove desired images'
echo 'docker images | grep -e none -e cave_cave | awk '{print $3}' | xargs docker rmi -f'
