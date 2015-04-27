#!/usr/bin/env bash
#
# Right now this will install php 5.4, and mysql 5.5
# I will need to change this to php 5.3 and mariadb
# we will also need to create the clone_dir inside of
# /vagrant/httpdocs of the git_url, as well as load
# the database, clean mage_root/var/* and whatever
# else comes up....
export DEBIAN_FRONTEND=noninteractive

# Install Apache & PHP 5.4
# --------------------
apt-get update

##apt-get install -y python-software-properties
##add-apt-repository ppa:ondrej/php5-5.6
##apt-get update && apt-get -y upgrade

apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php-pear php5-imap php5-mcrypt php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

apt-get update -y --fix-missing

php5enmod mcrypt

# Install GIT
apt-get install -y git

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html /vagrant/httpdocs
mkdir -p /vagrant/httpdocs

# Symlink back across
# --------------------
ln -fs /vagrant/httpdocs /var/www/html

# Adding site
su vagrant -c "
  git clone git@github.com:engrade/engrade-queue.git /vagrant/httpdocs/
  cd /vagrant/httpdocs/
  git checkout -b jobhandler origin/jobhandler
"

# Turn on error reporting in app
sed -i -e 's/<?php/<?php error_reporting(E_ALL); ini_set("display_errors", 1);/g' /vagrant/httpdocs/public/index.php

# Add Vagrant as the default Apache Config User/Group
sed -i -e 's/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=vagrant/g'   /etc/apache2/envvars
sed -e    's/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=vagrant/g' /etc/apache2/envvars

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
Listen 8080
<VirtualHost *:80>
  DocumentRoot "/var/www/html/public"
  ServerName localhost
  <Directory "/var/www/html/public">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "/var/www/html/public"
  ServerName localhost
  <Directory "/var/www/html/public">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2enmod rewrite
service apache2 restart

## per http://serverfault.com/questions/558283/apache2-config-variable-is-not-defined
source /etc/apache2/envvars

# MariaDB
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive

apt-get -q -y install mysql-server-5.5

sed -ie 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
service mysql restart

# Create a God mode user
mysql -u root -e "CREATE USER 'god'@'localhost'"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'god'@'localhost' WITH GRANT OPTION"

mysql -u root -e "CREATE USER 'god'@'%'"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'god'@'%' WITH GRANT OPTION"

mysql -u root -e "FLUSH PRIVILEGES"

cd /tmp && apt-get install -y unzip

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip

./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

mkdir -p '/home/vagrant/.aws'

# Set up AWS config stuff
echo -e '[default]\noutput = json\nregion = us-east-1' > /home/vagrant/.aws/config
echo -e '[default]\naws_access_key_id = AKIAIYBPLLDG63BQSLRQ\naws_secret_access_key = 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' > /home/vagrant/.aws/credentials
chown -R vagrant:vagrant /home/vagrant/.aws

su vagrant -c "
  curl -sS https://getcomposer.org/installer |php
  sudo mv composer.phar /bin/composer
  cd /var/www/html
  composer install
"