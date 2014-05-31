#/bin/bash

#This script installs all the needed configuration for the site
#and links the config files that we have in this repository to 
#the required locations on the server

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
sudo ln -s `pwd`/config/elasticsearch/scripts /usr/local/bin/elasticsearch/config/scripts

#redis
sudo apt-get install -y redis-server

#nginx
sudo apt-get install -y nginx 
sudo rm -f /etc/nginx/sites-enabled/default 
sudo ln -s `pwd`/config/nginx/globallometree /etc/nginx/sites-enabled/globallometree 

#supervisor
sudo apt-get install -y supervisor
sudo ln -s `pwd`/config/supervisor/globallometree.conf /etc/supervisor/conf.d/globallometree.conf 
	
