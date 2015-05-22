#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

  URL="${1}"
  KEY="${2}"
  PEM="${3}"

echo -e "\nUsing the following configuration:"
echo -e "-> URL: ${URL}"
echo -e "-> KEY: ${KEY}"
echo -e "-> PEM: ${PEM}"


# Define envvars
# --------------------
export APPDIR=/var/www/html
export HTDOCS=/vagrant/httpdocs


# Update Apache 2.4
# --------------------
apt-get install -y apache2 git


# Empty GIT_DIR
# --------------------
[[ 1 == $(ls $HTDOCS |wc -l) ]] && {
  rm -fr $HTDOCS/*
}


# Nuke and pave...
# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf   $HTDOCS $APPDIR
mkdir -p $HTDOCS


# Symlink back across
# --------------------
ln -fs $HTDOCS $APPDIR

git clone $URL $APPDIR

## Add Vagrant as the default Apache Config User/Group
sed -i -e 's/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=vagrant/g'   /etc/apache2/envvars
sed -i -e 's/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=vagrant/g' /etc/apache2/envvars


# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
Listen 8080
<VirtualHost *:80>
  ServerName        localhost
  DocumentRoot      "$APPDIR/tests"

  SetEnv APP_HOME   $APPDIR
  SetEnv APP_ENV    virtualmachine
  #Include          conf-available/serve-cgi-bin.conf

  SetEnv KEY        $KEY
  SetEnv SECRET     $PEM

  ProxyPassMatch    ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000$APPDIR/tests/\$1

  <Directory "$APPDIR/tests">
    Order allow,deny
    Allow from all
    AllowOverride FileInfo All

    # New directive needed in Apache 2.4.3:
    Require all granted
  </Directory>

  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined

</VirtualHost>

<VirtualHost *:8080>
  ServerName        localhost
  DocumentRoot      "$APPDIR/tests"

  SetEnv APP_HOME   $APPDIR
  SetEnv APP_ENV    virtualmachine
  #Include          conf-available/serve-cgi-bin.conf

  SetEnv KEY        $KEY
  SetEnv SECRET     $PEM

  ProxyPassMatch    ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000$APPDIR/tests/\$1

  <Directory "$APPDIR/tests">
    Order allow,deny
    Allow from all
    AllowOverride FileInfo All

    # New directive needed in Apache 2.4.3:
    Require all granted
  </Directory>

  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF
)


echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

# Enable modules
# --------------------
a2enmod proxy_fcgi
a2enmod rewrite

service apache2 restart


## per http://serverfault.com/questions/558283/apache2-config-variable-is-not-defined
source /etc/apache2/envvars


# Install PHP modules
# --------------------
apt-get install -y php5-fpm php5-cli php5-curl

sed -i -e 's/www-data/vagrant/g'                        /etc/php5/fpm/pool.d/www.conf
sed -i -e 's~/var/run/php5-fpm.sock~127.0.0.1:9000~g'   /etc/php5/fpm/pool.d/www.conf

service php5-fpm restart


# Install Composer
# --------------------
su vagrant -c "
  curl -sS https://getcomposer.org/installer |php
  sudo mv composer.phar /bin/composer
  cd $APPDIR && composer install
"

# Git Commands
# --------------------
su vagrant -c "
  curl -sSL https://gist.githubusercontent.com/ehime/5d7ab0d87da9cae55c40/raw/2abfa8760ba1038a8cd7c18ecd109876fefa34f1/.gitconfig > ~/.gitconfig
  git config --global credential.helper cache
"