#!/usr/bin/env bash

LOG_FILE=/vagrant/setup/vm_build.log

DATABASE_ROOT_PASS=root
BLOWFISH_SECRET=`openssl rand -base64 32`

SERVER_NAME="localhost"
SERVER_ADMIN="your@email.address"
SERVER_LANGUAGE="en_US.UTF-8"
SERVER_TIMEZONE="Europe/Amsterdam"
SERVER_DOCUMENT_ROOT=/var/www/html

echo -e "install jiam/vagrant-xenial64-php7.1"

##
# Upgrade
# ---------------------------------------------------------------------------- #
##
echo -e "\t-update packages."

apt-get update -qq >> $LOG_FILE 2>&1
apt-get upgrade -qq >> $LOG_FILE 2>&1

##
# Software Packages
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install packages."

apt-get install -y curl wget >> $LOG_FILE 2>&1
apt-get install -y build-essential >> $LOG_FILE 2>&1

echo -e "\t\t--software properties"
apt-get install -y software-properties-common python-software-properties >> $LOG_FILE 2>&1

echo -e "\t\t--language pack"
apt-get install -y language-pack-en-base >> $LOG_FILE 2>&1

echo -e "\t\t--7zip"
apt-get install -y p7zip p7zip-full p7zip-rar >> $LOG_FILE 2>&1

##
# Language Properties
# ---------------------------------------------------------------------------- #
##
echo -e "\t-configure server language properties."

export LANG=$SERVER_LANGUAGE
export LC_ALL=$SERVER_LANGUAGE

##
# Timezone
# ---------------------------------------------------------------------------- #
##
echo -e "\t-configure server timezone."

echo $SERVER_TIMEZONE > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata >> $LOG_FILE 2>&1

##
# Repositories
# ---------------------------------------------------------------------------- #
##
echo -e "\t-add repositories."

add-apt-repository -y ppa:ondrej/php >> $LOG_FILE 2>&1

apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 >> $LOG_FILE 2>&1
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/10.1/ubuntu xenial main' >> $LOG_FILE 2>&1

apt-get update -qq >> $LOG_FILE 2>&1

##
# Apache2
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install apache2.4."

apt-get install -y apache2 apache2-doc apache2-utils >> $LOG_FILE 2>&1
apt-get install -y libapache2-mod-php7.1 >> $LOG_FILE 2>&1

##
# Maria DB 10
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install mariadb10"

debconf-set-selections <<< "mysql-server mysql-server/root_password password ${DATABASE_ROOT_PASS}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${DATABASE_ROOT_PASS}"

apt-get install -y mariadb-server mariadb-client >> $LOG_FILE 2>&1

service mysql restart >> $LOG_FILE 2>&1

#/usr/bin/mysqladmin -u root password "${DATABASE_ROOT_PASS}"

# allow remote access (required to access from our private network host. Note that this is completely insecure if used in any other way)
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${DATABASE_ROOT_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES;"

##
# PHP 7.1
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install php7.1."

apt-get install -y php7.1 php7.1-cli php7.1-common php7.1-curl php7.1-gd php-gettext php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-xml php7.1-xmlrpc php7.1-zip >> $LOG_FILE 2>&1

##
# PhpMyAdmin
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install phpmyadmin."

cd /usr/share
mkdir phpmyadmin

wget https://files.phpmyadmin.net/phpMyAdmin/4.5.4.1/phpMyAdmin-4.5.4.1-all-languages.zip >> $LOG_FILE 2>&1

7z x phpMyAdmin-4.5.4.1-all-languages.zip >> $LOG_FILE 2>&1
mv phpMyAdmin-4.5.4.1-all-languages/* phpmyadmin

rm phpMyAdmin-4.5.4.1-all-languages.zip
rm -rf phpMyAdmin-4.5.4.1-all-languages

chmod -R 0755 phpmyadmin

# Blowfish Secret
mv /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php
sed -i "s|cfg\['blowfish_secret'\] = ''|cfg\['blowfish_secret'\] = '${BLOWFISH_SECRET}'|" /usr/share/phpmyadmin/config.inc.php

##
# Server Configuration
# ---------------------------------------------------------------------------- #
##
echo -e "\t-configure server."

# Document Root
rm -rf /var/www/html
ln -fs /vagrant/public /var/www/html

# Mod Rewrite
a2enmod rewrite >> $LOG_FILE 2>&1
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

# Server Name
echo "Servername ${SERVER_NAME}" >> /etc/apache2/conf-available/servername.conf
a2enconf servername >> $LOG_FILE 2>&1

# Virtual Host
VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_NAME}
    ServerAdmin ${SERVER_ADMIN}

    #Document-Root
    DocumentRoot ${SERVER_DOCUMENT_ROOT}

    #Log-Files
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    #PhpMyAdmin
    Alias /phpmyadmin "/usr/share/phpmyadmin/"

    <Directory "/usr/share/phpmyadmin/">
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>
</VirtualHost>
EOF
)

echo "${VHOST}" >> /etc/apache2/sites-available/default.conf

rm /etc/apache2/sites-available/000-default.conf

a2dissite 000-default.conf >> $LOG_FILE 2>&1
a2ensite default.conf >> $LOG_FILE 2>&1

service apache2 restart >> $LOG_FILE 2>&1

##
# Utilities
# ---------------------------------------------------------------------------- #
##
echo -e "\t-install utilities."

# Composer
echo -e "\t\t--composer."
curl -s https://getcomposer.org/installer | php >> $LOG_FILE 2>&1
mv composer.phar /usr/local/bin/composer

# Git
echo -e "\t\t--git."
apt-get install -y git >> $LOG_FILE 2>&1

# NodeJS & NPM
echo -e "\t\t--nodejs & npm."
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - >> $LOG_FILE 2>&1
apt-get install -y nodejs >> $LOG_FILE 2>&1

# Bower, Grunt & Gulp
echo -e "\t\t--bower, grunt & gulp."
npm install -g bower grunt gulp >> $LOG_FILE 2>&1

##
# Update
# ---------------------------------------------------------------------------- #
##
echo -e "\t-update packages."

apt-get update -qq >> $LOG_FILE 2>&1
apt-get autoremove -y >> $LOG_FILE 2>&1
