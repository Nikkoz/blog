#!/usr/bin/env bash

source /var/www/dist/provision/common.sh

#== Import script args ==

timezone=$(echo "$1")

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Configure timezone"
timedatectl set-timezone ${timezone} --no-ask-password

info "Configure language pack"
apt-get install -y language-pack-en zip unzip
locale-gen "en_US.UTF-8"
dpkg-reconfigure locales
update-locale LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" LC_CTYPE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

info "Prepare root password for MySQL"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
echo "Done!"

info "Add Php 7.2 repository"
add-apt-repository ppa:ondrej/php -y
#add-apt-repository -y 'deb http://archive.ubuntu.com/ubuntu trusty universe'

info "Update OS software"
apt-get update
apt-get upgrade -y

info "Install additional software:"

info "Install php"
apt-get install -y php7.2 php7.2-curl php7.2-cli php7.2-dev php7.2-xdebug php7.2-intl php7.2-gd php7.2-fpm php7.2-mbstring php7.2-zip php7.2-xml

info "Install mysql"
apt-get install -y php7.2-mysqlnd mysql-server-5.7

info "Configure MySQL"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"

#info "Install Redis"
#apt-get install -y redis-server

#info "Install Supervisor"
#apt-get install -y supervisor

info "Install memcached"
apt-get install -y php7.2-memcached memcached

info "Install nginx"
apt-get install -y nginx

info "Configure PHP-FPM"
sed -i 's/user = www-data/user = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
echo "Done!"

info "Configure xdebug"
cat << EOF > /etc/php/7.2/mods-available/xdebug.ini
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_autostart=1
xdebug.idekey = "PHPSTORM"
EOF
echo "Done!"

info "Configure NGINX"
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
#root -c "echo '127.0.0.1 test.local' >> /etc/hosts"
echo "Done!"

info "Enabling site configuration"
#rm /etc/nginx/sites-enabled/*
#rm /etc/nginx/nginx.conf

#cp /var/www/dist/nginx/nginx.conf /etc/nginx/
#cp /var/www/dist/nginx/test.local.conf /etc/nginx/sites-available/

#ln -s /etc/nginx/sites-available/test.local.conf /etc/nginx/sites-enabled/

ln -s /var/www/dist/nginx/app.conf /etc/nginx/sites-enabled/app.conf
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE blog"
mysql -uroot <<< "CREATE DATABASE blog_test"
echo "Done!"

#info "Enabling supervisor processes"
#ln -s /app/vagrant/supervisor/queue.conf /etc/supervisor/conf.d/queue.conf
#echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer