

status:
	sudo supervisorctl status
	sudo service postgresql status
	sudo service redis-server status
	sudo service nginx status


deploy:

	sudo docker pull tomgruner/globallometree-web

	sudo service nginx stop
	sudo supervisorctl stop all
	-sudo docker stop `sudo docker ps -q`
	-sudo docker rm `sudo docker ps -a -q`

	#Backup 
	$(MAKE) psql-dump

	#Collect static and migrate with the new container
	./manage.sh collectstatic --noinput
	./manage.sh migrate --noinput

	sudo supervisorctl reload
	sudo service nginx start

rebuild-elasticsearch-indices:
	./manage.sh rebuild_equation_index

setup-server: 

	#install docker
	sudo curl -sL https://get.docker.io/ | sh
	echo `sudo docker --version`

	#Add our user (won't take effect until next login)
	sudo usermod -aG docker ${USER}

	#get log directories setup
	sudo mkdir -p /opt/logs/web
	sudo mkdir -p /opt/logs/esproxy

	#database dump diretory for backups
	sudo mkdir -p /opt/dbdumps
	sudo chmod og+rw /opt/dbdumps

	#Add in the static and other data directories
	#These directories are mounted from docker to the host in the supervidord conf
	sudo mkdir -p /opt/data/web/media
	sudo mkdir -p /opt/data/web/static
	
	#Create the secret key file for django sessions
	sudo test -s /opt/data/web/secret_key || date +%s | sha256sum | base64 | head -c 32 > /tmp/secret_key
	sudo mv /tmp/secret_key /opt/data/web/secret_key

	#postgresql 
	echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /tmp/pgdg.list
	sudo cp /tmp/pgdg.list /etc/apt/sources.list.d/
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	sudo apt-get update
	sudo apt-get install -y postgresql-client-9.3 postgresql-9.3 postgresql-contrib-9.3
	sudo test -s /opt/data/postgresql/PG_VERSION || sudo pg_dropcluster --stop 9.3 main
	sudo pg_createcluster --datadir=/opt/data/postgresql 9.3 main
	sudo rm -f /etc/postgresql/9.3/main/pg_hba.conf
	sudo cp `pwd`/config/postgresql/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
	sudo chown postgres.postgres /etc/postgresql/9.3/main/pg_hba.conf
	sudo service postgresql start

	#elasticsearch
	sudo apt-get install -y openjdk-7-jdk
	cd /tmp && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.0.tar.gz
	cd /tmp && tar xvzf /tmp/elasticsearch-1.2.0.tar.gz
	rm -f /tmp/elasticsearch-1.2.0.tar.gz
	sudo mv /tmp/elasticsearch-1.2.0 /usr/local/bin/elasticsearch
	sudo mkdir -p /opt/data/elasticsearch	
	sudo rm -f /usr/local/bin/elasticsearch/config/elasticsearch.yml
	sudo ln -s `pwd`/config/elasticsearch/elasticsearch.yml /usr/local/bin/elasticsearch/config/elasticsearch.yml

	#redis
	sudo apt-get install -y redis-server

	#nginx
	sudo apt-get install -y nginx 
	sudo rm -f /etc/nginx/sites-enabled/default 
	sudo ln -s `pwd`/config/nginx/globallometree /etc/nginx/sites-enabled/globallometree 

	#supervisor
	sudo apt-get install -y supervisor
	sudo ln -s `pwd`/config/supervisor/globallometree.conf /etc/supervisor/conf.d/globallometree.conf 
	

###################### DATABASE MANAGEMENT #######################


PSQL_ADMIN = sudo -u postgres psql
PSQL = PGPASSWORD=globallometree psql -U globallometree 

psql-shell: 
	$(PSQL) globallometree

#make psql-import-db PSQL_DUMP_FILE=globallometree.dump.2014_04_17.sql.gz
psql-import: 
	gunzip -c $(PSQL_DUMP_FILE) | $(PSQL)

psql-drop:
	echo "DROP DATABASE IF EXISTS globallometree;" | $(PSQL_ADMIN) 
	echo "DROP USER globallometree;" | $(PSQL_ADMIN) 

psql-create:
	echo "CREATE USER globallometree;" | $(PSQL_ADMIN)
	echo "ALTER USER globallometree WITH PASSWORD 'globallometree';" | $(PSQL_ADMIN)
	echo "CREATE DATABASE globallometree OWNER globallometree ENCODING 'UTF8' TEMPLATE template0; " | $(PSQL_ADMIN) 

psql-dump:
	PGPASSWORD=globallometree pg_dump -U globallometree -h 127.0.0.1 globallometree | gzip > /opt/dbdumps/globallometree.dump.`date +'%Y_%m_%d'`.sql.gz
	@echo "database exported to  /opt/dbdumps/globallometree.`date +'%Y_%m_%d'`.sql.gz"




