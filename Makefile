
setup-server: 

	#install docker
	sudo curl -sL https://get.docker.io/ | sh
	echo `sudo docker --version`

	#Add our user (won't take effect until next login)
	sudo usermod -aG docker ${USER}

	#get log directories setup
	sudo mkdir -p /opt/logs/web
	sudo mkdir -p /opt/logs/esproxy

	#Add in the static and other data directories
	sudo mkdir -p /opt/data/web/media
	sudo mkdir -p /opt/data/web/static
	sudo mkdir -p /opt/data/elasticsearch

	#postgresql 
	#add in repo for postgresql client 9.3 for db dumps
	echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /tmp/pgdg.list
	sudo cp /tmp/pgdg.list /etc/apt/sources.list.d/
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	sudo apt-get install -y postgresql-client-9.3 postgresql-9.3 postgresql-contrib-9.3
	pg_dropcluster --stop 9.3 main
	pg_createcluster --datadir=/opt/data/postgresql 9.3 main
	sudo rm -f /etc/postgresql/9.3/main/postgresql.conf
	sudo rm -f /etc/postgresql/9.3/main/pg_hba.conf
	sudo ln -s `pwd`/config/postgresql/postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
	sudo ln -s `pwd`/config/postgresql/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
	
	#sudo -u postgres /usr/lib/postgresql/9.3/bin/initdb -D /opt/data/postgresql
	sudo service postgresql start

	#Add in the secret key file
	sudo test -s /opt/data/web/secret_key || date +%s | sha256sum | base64 | head -c 32 > /opt/data/web/secret_key

	#install packages needed on the server to run the docker containers
	sudo apt-get install -y supervisor nginx redis-server

	#link the configuration files
	rm -f /etc/nginx/sites-enabled/globallometree
	rm -f /etc/supervisor/conf.d/globallometree.conf

	sudo ln -s `pwd`/config/supervisor/globallometree.conf /etc/supervisor/conf.d/globallometree.conf 
	sudo ln -s `pwd`/config/nginx/globallometree /etc/nginx/sites-enabled/globallometree 
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
	sudo service nginx stop
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
	sudo service nginx start

all-status:
	sudo supervisorctl status

###################### STATIC FILES #######################

collect-static:
	./manage.sh collectstatic --noinput

###################### DATABASE MANAGEMENT #######################


PSQL_ADMIN = sudo -u postgres psql
PSQL = PGPASSWORD=globallometree psql -U globallometree 

psql-shell: 
	$(PSQL) globallometree

#make psql-import-db PSQL_DUMP_FILE=globallometree.dump.2014_04_17.sql.gz
psql-import: 
	gunzip -c $(PSQL_DUMP_FILE) | $(PSQL)

psql-drop:
	echo "DROP DATABASE  IF EXISTS globallometree;" | $(PSQL) postgres 

psql-create:
	echo "CREATE USER globallometree;" | $(PSQL_ADMIN)
	echo "ALTER USER globallometree WITH PASSWORD 'globallometree';" | $(PSQL_ADMIN)
	echo "CREATE DATABASE globallometree OWNER globallometree ENCODING 'UTF8' TEMPLATE template0; " | $(PSQL_ADMIN) 

psql-reset: psql-drop psql-create psql-import

psql-dump:
	PGPASSWORD=globallometree pg_dump -U globallometree -h 127.0.0.1 globallometree | gzip > ../globallometree.dump.`date +'%Y_%m_%d'`.sql.gz
	@echo "database exported to globallometree.`date +'%Y_%m_%d'`.sql.gz"




