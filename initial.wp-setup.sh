#!/bin/sh
function plugin_install(){
  cd /tmp
  /usr/bin/wget http://downloads.wordpress.org/plugin/$1
  /usr/bin/unzip /tmp/$1 -d /var/www/vhosts/$2/wp-content/plugins/
  /bin/rm /tmp/$1
}

INSTANCEID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
AZ=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/`
SERVERNAME=$INSTANCEID

cd /usr/local/src/chef-repo/cookbooks/amimoto/
/usr/bin/git pull origin master
/usr/bin/chef-solo -c /usr/local/src/chef-repo/solo.rb -j /usr/local/src/chef-repo/amimoto.json
/bin/rm -rf /usr/local/src/chef-repo/

if [ "$AZ" = "eu-west-1a" -o "$AZ" = "eu-west-1b" -o "$AZ" = "eu-west-1c" ]; then
  REGION=eu-west-1
elif [ "$AZ" = "sa-east-1a" -o "$AZ" = "sa-east-1b" ]; then
  REGION=sa-east-1
elif [ "$AZ" = "us-east-1a" -o "$AZ" = "us-east-1b" -o "$AZ" = "us-east-1c" -o "$AZ" = "us-east-1d" -o "$AZ" = "us-east-1e" ]; then
  REGION=us-east-1
elif [ "$AZ" = "ap-northeast-1a" -o "$AZ" = "ap-northeast-1b" -o "$AZ" = "ap-northeast-1c" ]; then
  REGION=ap-northeast-1
elif [ "$AZ" = "us-west-2a" -o "$AZ" = "us-west-2b" -o "$AZ" = "us-west-2c" ]; then
  REGION=us-west-2
elif [ "$AZ" = "us-west-1a" -o "$AZ" = "us-west-1b" -o "$AZ" = "us-west-1c" ]; then
  REGION=us-west-1
elif [ "$AZ" = "ap-southeast-1a" -o "$AZ" = "ap-southeast-1b" ]; then
  REGION=ap-southeast-1
else
  REGION=unknown
fi

cd /tmp/

if [ "$REGION" = "ap-northeast-1" ]; then
  /bin/cp /tmp/amimoto/etc/motd /etc/motd
  /bin/cat /etc/system-release >> /etc/motd
  /bin/cat /tmp/amimoto/etc/motd.jp >> /etc/motd
  /bin/cp /tmp/amimoto/etc/sysconfig/i18n.jp /etc/sysconfig/i18n
else
  /bin/cp /tmp/amimoto/etc/motd /etc/motd
  /bin/cat /etc/system-release >> /etc/motd
  /bin/cat /tmp/amimoto/etc/motd.en >> /etc/motd
  /bin/cp /tmp/amimoto/etc/sysconfig/i18n /etc/sysconfig/i18n
fi
  
/bin/cp /dev/null /root/.bash_history > /dev/null 2>&1; history -c
/usr/bin/yes | /usr/bin/crontab -r

/sbin/service nginx stop
/bin/rm -Rf /var/log/nginx/*
/bin/rm -Rf /var/cache/nginx/*
/sbin/service nginx start

/sbin/service php-fpm stop
/bin/rm -Rf /var/log/php-fpm/*
/sbin/service php-fpm start

/sbin/service mysql stop
/bin/rm /var/lib/mysql/ib_logfile*
/bin/rm /var/log/mysqld.log*
/sbin/service mysql start

echo "WordPress install ..."
mkdir /var/www/vhosts/$SERVERNAME
cd /var/www/vhosts/$SERVERNAME
if [ "$REGION" = "ap-northeast-1" ]; then
  /usr/bin/wp core download --locale=ja
else
  /usr/bin/wp core download
fi
if [ -f /tmp/amimoto/wp-setup.php ]; then
  /usr/bin/php /tmp/amimoto/wp-setup.php $SERVERNAME $INSTANCEID $PUBLICNAME
fi
/bin/chown -R nginx:nginx /var/log/nginx
plugin_install "nginx-champuru.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wpbooster-cdn-client.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-remote-manager-client.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "head-cleaner.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-total-hacks.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "flamingo.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "contact-form-7.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "nephila-clavata.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "jetpack.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "hotfix.zip" "$SERVERNAME" > /dev/null 2>&1
echo "... WordPress installed"

/bin/chown -R nginx:nginx /var/log/nginx
/bin/chown -R nginx:nginx /var/log/php-fpm
/bin/chown -R nginx:nginx /var/cache/nginx
/bin/chown -R nginx:nginx /var/tmp/php
/bin/chown -R nginx:nginx /var/www/vhosts/$SERVERNAME

/bin/rm -rf /tmp/amimoto