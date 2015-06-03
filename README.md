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

# Backups

Most of the point of this project is to have a wordpress site that 
you can backup and upgrade easily. To do backups you can use these 
make targets:

```
make dbbackup
make wpbackup
```

For nightly backups you can add a line like this to your crontab:

```
0 22 * * * cd /home/web/inasafe.org && make dbbackup && make wpbackup
```

# Additional make targets

## Running the site

* **build** - builds / fetches docker images       
* **web** - Brings up the site. Mysql data wil be persisted in db folder, wp-content in wp-content folder.
* **run** - executes build then web targets
* **default** - alias for web target

## Log viewing

* **dblogs** - tails the logs from teh mysql container
* **wplogs** - tails the wordpress containers logs

## Shelling in to containers

* **dbshell** - gives you a bash shell in the mysql container
* **wpshell** - gives you a bash shell in the context of the wp container


## Backup and restore

* **webwithrestore** - executes web then dbrestore. This is a shortcut for restoring an existing site.
* **dbbackup** - perform a backup of the mysql database. Backup placed in /backups/<year>/<month>
* **dbrestore** - perform a restore of the wordpress mysql database. Restore file should exist as backups/wordpress.sql
* **wpbackup** - performs a backup of the wp-content folder. Backup placed in /backups/<year>/<month>

## Container management

* **kill** - killas all containers (but does not remove them)
* **rm** - Implies kill target. Kills then removes all containers
