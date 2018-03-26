# Docker environment
Prerequisites
-----
You will require:

- Docker engine for your platfom ([Windows](https://docs.docker.com/docker-for-windows/) [Linux](https://docs.docker.com/engine/installation/#/on-linux) [Mac](https://docs.docker.com/docker-for-mac/install/))
- [Docker-compose](https://docs.docker.com/compose/install/)
- Git client
- [Make](https://en.wikipedia.org/wiki/Make_(software))

Deployment steps
-----
 * Clone the Docker repo:

```
git clone \
git@github.com:ASDAlexey/todo-lists-docker.git todo-lists-docker \
&& cd todo-lists-docker
```

 * create .env file from dist: `cp .env.dist .env` 
 * Replace ALL values in `.env` file;
 * Start spinup scenario

```
make docker-env
```
 
 * For additional commands
 
```
make help
```


 * Your app available here [https://todo-lists.local](https://api.sportdiary.local)
 
 
 # Change remote origin 
 ```
 git remote set-url origin git@github.com:...git
 ```
 
### [Update ssl on dev server](https://certbot.eff.org/all-instructions/#ubuntu-16-10-yakkety-nginx)
sudo certbot certonly --standalone -d sportdiary.com -d www.sportdiary.com -d api.sportdiary.com -d www.sportdiary.com

### Rebuild docker container node in the file docker-compose-local.yml
docker-compose -f docker-compose-local.yml up -d --no-deps --build nginx

### Stop all docker containers
docker stop $(docker ps -a -q)

### Add global proxy nginx config
sudo cp -i ./nginx/bee-inbound-dev.conf /etc/nginx/conf.d/
