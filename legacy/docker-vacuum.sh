#!/bin/bash
echo '# Remove all containers'
echo 'docker ps -q -a | xargs docker rm -f'
echo
echo '# Remove only the desired containers'
echo "docker ps -a | grep -e _postgresql | awk '{print \$1}' | xargs docker rm -f"
echo
echo '# Remove all images'
echo 'docker images -q -a | xargs docker rmi -f'
echo
echo '# Remove desired images'
echo "docker images -a | grep -e '<none>' -e cave_ | awk '{print \$3}' | xargs docker rmi -f"

# http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers
# Old containers
# docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm

# Stopped
# docker ps -a | grep Exited | awk '{print $1}' | xargs --no-run-if-empty docker rm

# By status
# docker ps -aq -f status=exited
