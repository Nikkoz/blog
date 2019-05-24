#!/usr/bin/env bash

source /var/www/dist/provision/common.sh

#== Provision script ==

info "Provision-script user: `whoami`"

info "Restart web-stack"
service php7.2-fpm restart
service nginx restart
service mysql restart