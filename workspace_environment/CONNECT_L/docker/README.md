1. Build docker image
* docker build --rm --build-arg UID=`id -u` --build-arg GID=`id -g` --tag workspace:`date "+%y%m%d"` ./
2. Run the workspace container
* docker run --privileged -it --name docker_connect_s --env HOME=${HOME} -w ${HOME} -v /mnt:/mnt -v ${HOME}:${HOME} --hostname "docker_connect-s" --user `id -u`:`id -g` workspace:latest bash
3. Execute the terminal
* docker exec -it workspace /bin/bash
