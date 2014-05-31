#/bin/bash

#This is used to run manage.py using the docker container as context
# "$@" just passes all of the arguments along
# uses port 8083 if a runserver is needed

#Make sure any volume changes here are also done in config/supervisor/globallometree.conf

sudo docker run -i -t \
	-v /opt/data/web:/opt/data/web \
	-v /opt/logs/web:/opt/logs/web \
	-p 8083:8083 \
	--net="host" \
	tomgruner/globallometree:latest \
	/opt/code/manage.py "$@"