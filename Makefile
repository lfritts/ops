
setup-server: 
	#add in repo for postgresql client 9.3 for db dumps
	echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /tmp/pgdg.list
	sudo cp /tmp/pgdg.list /etc/apt/sources.list.d/
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	#the docker install does an update - so we depend on that to update the above repo

	#install docker
	sudo curl -sL https://get.docker.io/ | sh
	echo `sudo docker --version`

	#Add our user (won't take effect until next login)
	sudo usermod -aG docker ${USER}

	#get log directories setup
	sudo mkdir -p /opt/logs/web
	sudo mkdir -p /opt/logs/postgresql
	sudo mkdir -p /opt/logs/esproxy

	#Add in the static and other data directories
	sudo mkdir -p /opt/data/web/media
	sudo mkdir -p /opt/data/web/static
	sudo mkdir -p /opt/data/postgresql
	sudo mkdir -p /opt/data/elasticsearch

	#Add in the secret key file
	sudo test -s /opt/data/web/secret_key || date +%s | sha256sum | base64 | head -c 32 > secret_key > /opt/data/web/secret_key

	#install packages needed on the server to run the docker containers
	sudo apt-get install -y supervisor nginx postgresql-client-9.3 

	#link the configuration files
	test -s /etc/supervisor/conf.d/globallometree.conf || sudo ln -s `pwd`/config/supervisor/globallometree.conf /etc/supervisor/conf.d/globallometree.conf 
	test -s /etc/nginx/sites-enabled/globallometree || sudo ln -s `pwd`/config/nginx/globallometree /etc/nginx/sites-enabled/globallometree 
	sudo rm -f /etc/nginx/sites-enabled/default 
	sudo service nginx restart

web-deploy:
	#pull images relevant to deploy just the web container
	sudo docker pull tomgruner/globallometree-web
	#restart the web container
	sudo supervisorctl restart webgunicorn
	$(MAKE) collect-static
	
all-deploy: all-pull all-restart
	$(MAKE) collect-static
	
all-restart: all-stop-and-clean all-start

all-stop-and-clean:
	#Stop supervisor
	sudo supervisorctl stop all
	#Remove and stop any remaining containers 
	#there should not acutally be any
	-sudo docker stop `docker ps -q`
	-sudo docker rm `docker ps -a -q`


all-pull:
	#pull the docker images we need
	sudo docker pull tomgruner/globallometree-redis
	sudo docker pull tomgruner/globallometree-postgresql
	sudo docker pull tomgruner/globallometree-elasticsearch
	sudo docker pull tomgruner/globallometree-web

all-start:
	#Start supervisor
	sudo supervisorctl reload


###################### STATIC FILES #######################

collect-static:
	./manage.sh collectstatic

###################### DATABASE MANAGEMENT #######################

PSQL = PGPASSWORD=globallometree psql -U globallometree -h 127.0.0.1

#make psql-import-db PSQL_DUMP_FILE=globallometree.dump.2014_04_17.sql.gz
psql-import-db: 
	gunzip -c $(PSQL_DUMP_FILE) | $(PSQL)

psql-drop-db:
	echo "DROP DATABASE  IF EXISTS globallometree;" | $(PSQL) postgres 

psql-create-db:
	echo "CREATE DATABASE globallometree OWNER globallometree ENCODING 'UTF8' TEMPLATE template0; " | $(PSQL) postgres

psql-reset-db: psql-drop-db psql-create-db psql-import-db

psql-dump-db:
	PGPASSWORD=globallometree pg_dump -U globallometree -h 127.0.0.1 globallometree | gzip > ../globallometree.dump.`date +'%Y_%m_%d'`.sql.gz
	@echo "database exported to globallometree.`date +'%Y_%m_%d'`.sql.gz"

	


