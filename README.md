# shinobi-docker
Another docker image for Shinobi Video

```bash
$ docker run --name db --network shinobi -e MYSQL_ROOT_PASSWORD=dbpasswd -d mariadb:latest
$ docker run --name shinobi --network shinobi -p 8080:8080 -d shinobi-docker:1.0
$ docker exec -ti shinobi /home/shinobi/entry.sh initialize
```

## TODO

* Too big! Trim down the image. Some ideas:
  * Compile ffmpeg with only the necessary libraries enabled.
* Improve health checking.
  * Verify status of processes instead of just counting them.
* Install process should detect if the db is already initialized

