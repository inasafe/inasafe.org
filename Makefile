# ------------------------------------------------------------------------
# Set this to the name of your project / website
# ------------------------------------------------------------------------
PROJECT_ID := inasafe
PASSWORD := foobar

# ------------------------------------------------------------------------
# Should not normally need to change anything below this point....
# ------------------------------------------------------------------------

SHELL := /bin/bash

default: web

run: build web


build:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Building "
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) build

web:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Running "
	@echo "------------------------------------------------------------------"
	@DB_PASS=$(PASSWORD) MYSQL_PASS=$(PASSWORD) docker-compose -p $(PROJECT_ID) up -d wordpress


webwithrestore: kill rm web 
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Running the restoring dump from backups/wordpress.sql "
	@echo "------------------------------------------------------------------"
	@sleep 10
	@docker exec -t -i $(PROJECT_ID)_db_1 /backups/db-restore.sh


kill:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Killing all containers!"
	@echo "------------------------------------------------------------------"

	@docker-compose -p $(PROJECT_ID) kill

rm: kill
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Removing all containers!!! "
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) rm

wplogs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing wordpress logs "
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) logs wordpress

dblogs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing mysql logs "
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) logs db

wpshell:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Shelling in to wordpress (press enter to activate shell)"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) run wordpress /bin/bash

dbshell:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Shelling in to mysql (press enter to activate shell)"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_db_1 /bin/bash

dbbackup:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up mysql database"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_db_1 /backups/db-backup.sh
	@ls -lahtr `find ./backups -name *.sql` | tail -1

dbrestore:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restoring wordpress.sql over current wordpress database"
	@echo "You must ensure that the ./backups/wordpress.sql exists and is valid"
	@echo "the existing wordpress database will be lost!"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_db_1 /backups/db-restore.sh


wpbackup:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up wordpress files"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_db_1 /backups/wp-backup.sh

