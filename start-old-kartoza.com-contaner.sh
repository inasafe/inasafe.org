#!/bin/bash

# Note this will be defunct soon -replacing with docker compose
docker run -d -p 2080:80 --name=kartoza.com --hostname=kartoza.com timlinux/kartoza-wordpress supervisord -n
