#!/bin/bash

mysqladmin -u root drop wordpress
mysqladmin -u root create wordpress
cat /backups/wordpress.sql | mysql wordpress
mysqlshow
