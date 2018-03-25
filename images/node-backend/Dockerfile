FROM node:8.10.0

#Install packages required
RUN apt-get update && \
	apt-get install -y \
	curl \
	apt-transport-https

#Install libs
RUN npm i -g npm
RUN npm i -g typescript && tsc -v
RUN npm i -g sequelize-cli

EXPOSE 3000
CMD [ "node" ]
