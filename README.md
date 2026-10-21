# InaSAFE website & documentation

This repo is now a MkDocs (Material theme) site, built and deployed to
GitHub Pages automatically on every merge to `main` (see
`.github/workflows/Docs.yml`). Local dev: `nix develop`, then
`nix run .#docs-serve`.

## DNS setup for the inasafe.org custom domain

GitHub Pages custom domains are free on every GitHub plan, including the
free tier — no GitHub Enterprise needed. The repo's `docs/CNAME` file
already declares `inasafe.org` as the custom domain; the rest is DNS
configuration at your registrar/DNS provider:

Since `inasafe.org` is an apex/root domain (not a subdomain), point it at
GitHub Pages with **A records**:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Optional, for IPv6 — **AAAA records**:

```
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

If you also want `www.inasafe.org` to work, add a **CNAME record**:
`www` → `inasafe.github.io`.

Once DNS propagates, go to the repo's Settings → Pages to verify the
domain and enable "Enforce HTTPS" (free Let's Encrypt certificate,
issued automatically).

Note: a plain CNAME record on the apex domain does **not** create a
redirect by itself — it's DNS aliasing, invisible to the browser's
address bar, and GitHub Pages won't serve anything for a Host header
it doesn't recognize as a configured custom domain. The A/AAAA records
above plus the CNAME file in this repo are what actually make
`inasafe.org` resolve to and serve this site.

The DNS cutover should only happen once the migrated site (manual +
training + website content merged here) has been reviewed and the old
WordPress server's final backup cycle has run — see `SPECIFICATION.md`
in the top-level workspace for the full migration plan.

---

## Legacy: WordPress Docker setup (being retired)

The notes below describe the old WordPress hosting this repo used to
run before the MkDocs migration above. Kept for historical reference
until the WordPress server is decommissioned.

A Docker-Compose project for running wordpress


Tim Sutton, 2015


# NOTE

In May 2019 I moved the site content to a static site

InaSAFE.org - Static Site

General setup:

Wordpress deployed on the host directly (no docker).
Several other sites there :

https://manual.inasafe.org (static)
https://docs.inasafe.org (static, deprecated by above)

Nightly and experimental builds disabled

I have Wordpress disabled by default for security. When you want to update the site you need to do these steps:

1. Disable static version of the site
2. Enable WP version of the site
3. Restart Nginx
4. Make any needed changes
5. Scrape the site using wget
6. Disable WP version
7. Enable static
8. Restart nginx

This is the command to make the mirror

```
wget --recursive --no-clobber --page-requisites --html-extension --convert-links --restrict-file-names=windows https://inasafe.org
```

TODO move manual, docs and static site into github pages and shut down this server

I have backups of the WP dump and dynamic site on my personal machines static dir


Original notes for docker based instance now follow:

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
