#/bin/bash

#This is used to run manage.py using the docker container as context
# "$@" just passes all of the arguments along
# uses port 8083 if a runserver is needed

sudo docker run -i -t \
	-v /opt/data/web:/opt/data \
	-p 8083:8083 \
	--net="host" \
	tomgruner/globallometree-web \
	/opt/code/manage.py "$@"