
status:
	sudo supervisorctl status
	sudo service postgresql status
	sudo service redis-server status
	sudo service nginx status

deploy: pull-docker-images stop-web psql-dump collectstatic migrate start-web

#Deploy an image id
#make deploy-image-id IMAGE_ID=8852ac715366
deploy-image-id: set-latest stop-web psql-dump collectstatic migrate start-web

#Set and image id as latest
#the image id with the tag "latest" is the one that will be run
#make set-latest IMAGE_ID=8852ac715366
set-latest:
	docker tag ${IMAGE_ID} tomgruner/globallometree:latest 

pull-docker-images:
	sudo docker pull tomgruner/globallometree

collectstatic:
	#Collect static and migrate with the new container
	./manage.sh collectstatic --noinput

migrate:
	./manage.sh migrate --all --noinput

stop-web:
	sudo service nginx stop
	sudo supervisorctl stop all
	#Clean up left over images - useful when running inside virtual box
	-sudo docker stop `sudo docker ps -q`
	-sudo docker rm `sudo docker ps -a -q`

start-web:
	sudo supervisorctl reload
	sudo service nginx start

stop-db:
	sudo service postgresql stop

start-db:
	sudo service postgresql start

restart-all: stop-web stop-db start-db start-web status

rebuild-elasticsearch-indices:
	./manage.sh rebuild_equation_index

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




