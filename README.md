# shinobi-docker
Another docker image for Shinobi Video

docker run --name mariadb --network shinobi -e MYSQL_ROOT_PASSWORD=password -d mariadb:latest

docker run -ti --network shinobi -p 8080:8080 --name shinobi shinobi-docker:1.0
