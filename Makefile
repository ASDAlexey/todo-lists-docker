#!make
include .env
export $(shell sed 's/=.*//' .env)

END_COLOR='\033[0m'		#  ${END_COLOR}
RED='\033[0;31m'        #  ${RED}
GREEN='\033[0;32m'      #  ${GREEN}
BOLD='\n\033[1;m'		#  ${BOLD}
WARNING=\033[37;1;41m	#  ${WARNING}

EXEC = docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec

.PHONY: help docker-env clone rebuild build-frontend up stop restart status clean clean-docker-repo clean-frontend-repo clean-backend-repo console-nginx console-node console-elasticsearch console-kibana console-logstash logs-nginx logs-node logs-elasticsearch logs-kibana logs-logstash generate-nginx-config generate-httpauth generate-ssl generate-configs generate-elk-configs hosts warning

db-update-user-password:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make db-update-user-password-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make db-update-user-password-self; fi"
db-update-user-password-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec db psql -Upostgres -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"
db-update-user-password-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-env-server-self.yml exec db psql -Upostgres -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"

db-create:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make db-drop db-create-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make db-drop db-create-self; fi"
db-create-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec db bash -c "psql -Upostgres -c 'CREATE DATABASE ${POSTGRES_DB};'"
db-create-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-env-server-self.yml exec db bash -c "psql -Upostgres -c 'CREATE DATABASE ${POSTGRES_DB};'"

db-drop:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make db-drop-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make db-drop-self; fi"
db-drop-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec db bash -c "psql -Upostgres -c 'DROP DATABASE IF EXISTS ${POSTGRES_DB};'"
db-drop-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-env-server-self.yml exec db bash -c "psql -Upostgres -c 'DROP DATABASE IF EXISTS ${POSTGRES_DB};'"

docker-env:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make docker-env-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make docker-env-server-self; fi"
docker-env-local: clone generate-httpauth generate-nginx-config generate-ssl generate-configs db-create up hosts
docker-env-server-self: clone generate-nginx-config generate-configs db-create up

clone:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make clone-all; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make clone-all; fi"
clone-all:
	@echo "\n\033[1;mCloning (${BRANCH_NODE} branch from backend repository) \033[0m"
	@bash -c "if cd src/${PATH_NODE} 2> /dev/null; then git pull origin ${BRANCH_NODE}; else git clone -b ${BRANCH_NODE} ${GIT_NODE} src/${PATH_NODE}; fi"
	@bash -c "if cd src/${PATH_FRONTEND} 2> /dev/null; then git pull origin ${BRANCH_FRONTEND}; else git clone -b ${BRANCH_FRONTEND} ${GIT_NODE} src/${PATH_FRONTEND}; fi"
clone-backend:
	@echo "\n\033[1;mCloning (${BRANCH_NODE} branch from backend repository) \033[0m"
	@bash -c "if cd src/${PATH_NODE} 2> /dev/null; then git pull origin ${BRANCH_NODE}; else git clone -b ${BRANCH_NODE} ${GIT_NODE} src/${PATH_NODE}; fi"
clone-frontend:
	@echo "\n\033[1;mCloning (${BRANCH_NODE} branch from backend repository) \033[0m"
	@bash -c "if cd src/${PATH_FRONTEND} 2> /dev/null; then git pull origin ${BRANCH_FRONTEND}; else git clone -b ${BRANCH_FRONTEND} ${GIT_NODE} src/${PATH_FRONTEND}; fi"
clone-docker: clean-docker-repo-force
	@bash -c "git pull"

rebuild: stop
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make rebuild-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make rebuild-server-self; fi"
rebuild-local:
	@echo "\n\033[1;mRebuilding containers... \033[0m"
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml build --no-cache
rebuild-server-self:
	@echo "\n\033[1;mRebuilding containers... \033[0m"
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml build --no-cache

up:
	@echo "\n\033[1;mSpinning up containers... \033[0m"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make up-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make up-server-self; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'frontend' ]; then make up-server-frontend; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'backend' ]; then make up-server-backend; fi"
	@$(MAKE) --no-print-directory status
up-local:
	@echo "- COMPOSE_ENVIRONMENT: ${COMPOSE_ENVIRONMENT}"
	@echo "- ENVIRONMENT: ${ENVIRONMENT}"
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml up -d
up-server-self:
	@echo "- COMPOSE_ENVIRONMENT: ${COMPOSE_ENVIRONMENT}"
	@echo "- CLUSTER: ${CLUSTER}"
	@echo "- ENVIRONMENT: ${ENVIRONMENT}"
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml up -d

stop:
	@echo "\n\033[1;mHalting containers... \033[0m"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make stop-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make stop-server-self; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'frontend' ]; then make stop-server-frontend; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'backend' ]; then make stop-server-backend; fi"
	@$(MAKE) --no-print-directory status
stop-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml stop
stop-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml stop

restart:
	@echo "\n\033[1;mRestarting containers... \033[0m"
	@$(MAKE) --no-print-directory stop up

restart-node:
	@echo "\n\033[1;mRestarting node container \033[0m"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make restart-node-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make restart-node-server-self; fi"
restart-node-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml restart node
restart-node-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml restart node

restart-nginx:
	@echo "\n\033[1;mRestarting nginx container \033[0m"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make restart-nginx-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make restart-nginx-server-self; fi"
restart-nginx-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml restart nginx
restart-nginx-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml restart nginx

status:
	@echo "\n\033[1;mContainers statuses \033[0m"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make status-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make status-server-self; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'frontend' ]; then make status-server-frontend; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'backend' ]; then make status-server-backend; fi"
	@echo "\n\033[1;mNetwork information \033[0m"
	@bash ./bin/network-status.sh
status-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml ps
status-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml ps

clean:
	@echo "\n\033[1;31m\033[5m*** Removing containers and application repositories ***\033[0m"
	@echo "\033[1;31m\033[5m*** Ensure that you commited changes ***\033[0m\n"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make clean-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make clean-server-self; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'frontend' ]; then make clean-server-frontend; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'backend' ]; then make clean-server-backend; fi"
clean-local:
	@bash -c "while true; do bash ./bin/dialog.sh || break; docker-compose -p ${COMPOSE_PROJECT_NAME} -f ./docker-compose-local.yml down --rmi all 2> /dev/null; git reset --hard; rm -rf ./src/*; break; done"
clean-server-self:
	@bash -c "while true; do bash ./bin/dialog.sh || break; docker-compose -p ${COMPOSE_PROJECT_NAME} -f ./docker-server-self.yml down --rmi all 2> /dev/null; git reset --hard; rm -rf ./src/*; break; done"

clean-docker-repo:
	@bash -c "while true; do echo -ne \"\n\033[1;31m\033[5m*** Resetting docker repository ***\033[0m\n\"; echo -ne \"\033[1;31m\033[5m*** Ensure that you commited changes ***\033[0m\n\"; bash ./bin/dialog.sh || break; git reset --hard; break; done"
clean-docker-repo-force:
	@bash -c "if [ ${USER} == 'jenkins' ]; then git reset --hard; fi"

console-nginx:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make console-nginx-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make console-nginx-server-self; fi"
console-nginx-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec nginx sh
console-nginx-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml exec nginx sh

console-node:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make console-node-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make console-node-server-self; fi"
console-node-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec node bash
console-node-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml exec node bash

console-pg:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make console-pg-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make console-pg-server-self; fi"
console-pg-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml exec db bash
console-pg-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml exec db bash

logs-nginx:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make logs-nginx-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make logs-nginx-server-self; fi"
logs-nginx-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml logs --tail=100 -f nginx
logs-nginx-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml logs --tail=100 -f nginx

logs-node:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make logs-node-local; fi"
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make logs-node-server-self; fi"
logs-node-local:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml logs --tail=100 -f node
logs-node-server-self:
	@docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml logs --tail=100 -f node

logs-pg:
    @bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make logs-pg-local; fi"
    @bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then make logs-pg-server-self; fi"
logs-pg-local:
    @docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-local.yml logs --tail=100 -f db
logs-pg-server-self:
    @docker-compose -p ${COMPOSE_PROJECT_NAME} -f docker-compose-server-self.yml logs --tail=100 -f db

generate-nginx-config:
	@bash ./bin/nginx-config.sh

generate-httpauth:
	@bash ./bin/httpauth.sh

generate-ssl:
	@echo "\n\033[1;mGenerating SSL certificates...\033[0m"
	@bash ./bin/openssl.sh

generate-configs:
	@bash ./bin/config.sh

hosts:
	@bash -c "if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then make hosts-local; else make warning; fi"

hosts-local:
	@echo "\n\033[1;mAdding record in to your local hosts file...\033[0m"
	@echo "\033[1;mPlease use your local sudo password if requested\033[0m"
	@bash ./bin/hosts-upsert.sh

warning:
	@echo "Depricated action! You can't run this command on your current configuration:"
	@echo "- COMPOSE_ENVIRONMENT: ${COMPOSE_ENVIRONMENT}"
	@echo "- CLUSTER: ${CLUSTER}"
	@echo "- ENVIRONMENT: ${ENVIRONMENT}"

help:
	@echo "\n\033[1mMain section\033[0m"
	@echo "\033[1;32mdocker-env\t\t- main scenario, used by default\033[0m"
	@echo "clone\t\t\t- clone application repositories"
	@echo "rebuild\t\t\t- build containers without cache"
	@echo "build-frontend\t\t- compile frontend assets"
	@echo "up\t\t\t- start project containers"
	@echo "stop\t\t\t- stop project containers"
	@echo "restart\t\t\t- restart containers"
	@echo "status\t\t\t- show status of containers"
	@echo "\033[1;31m\033[5mclean\t\t\t- reset project. all Local application data will be lost!\033[0m"
	@echo "\033[1;31m\033[5mclean-docker-repo\t- reset docker repository (git reset --hard)\033[0m"
	@echo "\033[1;31m\033[5mclean-frontend-repo\t- reset frontend repository (git reset --hard)\033[0m"
	@echo "\033[1;31m\033[5mclean-backend-repo\t- reset backend repository (git reset --hard)\033[0m"

	@echo "\n\033[1mConsole section\033[0m"
	@echo "console-nginx\t\t- run console for nginx container"
	@echo "console-node\t\t- run console for node container"
	@echo "console-elasticsearch\t- run console for elasticsearch container"
	@echo "console-kibana\t\t- run console for elasticsearch container"
	@echo "console-logstash\t- run console for elasticsearch container"

	@echo "\n\033[1mLogs section\033[0m"
	@echo "logs-nginx\t\t- show nginx container logs"
	@echo "logs-node\t\t- show node container logs"
	@echo "logs-elasticsearch\t- show elasticsearch container logs"
	@echo "logs-kibana\t\t- show kibana container logs"
	@echo "logs-logstash\t\t- show logstash container logs"

	@echo "\n\033[1mConfig generators section\033[0m"
	@echo "generate-nginx-config\t- generates nginx config file based on .env parameters"
	@echo "generate-httpauth\t- generates .htpasswd file based on .env parameters"
	@echo "generate-ssl\t\t- generates self-sign SSL certificates based on .env parameters"
	@echo "generate-configs\t- generates node application config based on .env parameters"
	@echo "generate-elk-configs\t- generates ELK application config based on .env parameters"
	@echo "hosts\t\t\t- add domain and aliases to /etc/hosts file"
	@echo "\033[0;33mhelp\t\t\t- show this menu\033[0m"

