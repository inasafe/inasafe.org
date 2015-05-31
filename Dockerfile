FROM tutum/wordpress-stackable
MAINTAINER Tim Sutton <tim@kartoza.com>

# We will be replacing with our own app dir since
# we already have a running wp
RUN mv /app /app_org
