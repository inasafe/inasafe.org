A Docker-Compose project for running wordpress

Tim Sutton, 2015

# Purpose

This is a docker project for running worpress in a clean and persistent way.

It is based on work I did for our kartoza internal web site - and builds on 
docker images from tutum.

I wanted clean separation between:

* mysql
* wp apache container

And:

* optional mysql file based storage on host volume
* wp-content in host volume
* db password configured at run time using an environment variable when you first spin up an instance
* a way to easily generate a backup or restore a backup of your database

# Configuration

1. Edit the top the Make file and change the PROJECT_ID as needed
2. Edit the top the Make file and change the PASSWORD as needed
3. Optionally,  Also edit docker-compose.yml and change the port number for the
   web service to a port of your choice (default is to run on host port 2080)..

# Run the container:

```
make web

```

You should have an empty, default installation if wordpress running.


# Loading an existing site

To load an existing site you need:

1. Set up a default empty site as described above.
2. A recent sql dump of the wordpress database from the site, saved under backups/wordpress.sql
3. Optionally the wp-content directory from the original site. The wp-content dir should be unpacked in the root of this repo.

Now restore the backup (your old db will be dropped destroying any old data):

```
make dbrestore
```


