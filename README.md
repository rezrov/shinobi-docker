# shinobi-docker
Another docker image for Shinobi Video

```bash
$ docker build --tag shinobi-docker:1.0 .
$ docker network create shinobi
$ docker run --name db --network shinobi --restart=always -e MYSQL_ROOT_PASSWORD=dbpasswd -d mariadb:latest
$ docker run -d --name shinobi --network shinobi --restart=always -p 8080:8080 [-v /path/to/video:/home/shinobi/Shinobi/videos] [-e PUID=1001] [-e PGID=1001] shinobi-docker:1.0
$ docker exec -ti shinobi /home/shinobi/entry.sh initialize
```

## NOTES
Compared to most other Dockerized versions of Shinobi, this image is focused on improved security and ease of setup. All passwords are randomized on initialization and visible only inside the containers. The MariaDB root password is also changed to a random value during initialization. Processes inside the Shinobi container run as an unprivileged user (UID/GID 1001 by default, configurable with -e as above). When created with the above commands, the MariaDB instance is only visible to the Shinobi container on a new docker network named 'shinobi'.

To store the video files outside the container, use the -v option to map an external volume as shown above. Make sure that the external volume is writable by the UID/GID specified when the container is created.

When the initialize command is run, the admin user and password will be displayed. Go to http://localhost:8080/super to change the admin password and to create a regular user, then log in as the regular user at http://localhost:8080 to get started. See https://shinobi.video/docs/ for full documentation.

## TODO
* Too big! Trim down the image. Some ideas:
  * Compile ffmpeg with only the necessary libraries enabled
* Install process should detect if the db is already initialized
* Upgrade procedure should be implemented to retain configuration
