FROM debian:9

RUN apt-get clean

RUN apt-get update
RUN apt-get -y install wget curl apt-transport-https apache2 unzip redis-server

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list

RUN apt-get update

RUN apt-get -y install  php7.2 php7.2-redis php7.2-curl php7.2-gd php7.2-mbstring php7.2-imagick php7.2-mysql php7.2-xdebug php7.2-simplexml php7.2-zip php7.2-soap php7.2-apcu php-apcu-bc php7.2-sqlite3 php7.2-intl php7.2-bcmath

#configure apache
RUN ["bin/bash", "-c", "sed -i 's/AllowOverride None/AllowOverride All\\nSetEnvIf X-Forwarded-Proto https HTTPS=on/g' /etc/apache2/apache2.conf"]

RUN service apache2 stop

#set timezone
RUN apt-get -y install tzdata && ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#configure php
RUN ["bin/bash", "-c", "sed -i 's/max_execution_time\\s*=.*/max_execution_time=180/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/upload_max_filesize\\s*=.*/upload_max_filesize=16M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/memory_limit\\s*=.*/memory_limit=512M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/post_max_size\\s*=.*/post_max_size=20M/g' /etc/php/7*/apache2/php.ini"]
RUN phpenmod redis

#configure XDebug
RUN ["bin/bash", "-c", "echo [XDebug] >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.remote_enable=1 >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.remote_connect_back=1 >> /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "echo xdebug.idekey=netbeans-xdebug >> /etc/php/7*/apache2/php.ini"]

# Configure apache
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod headers
# optionally enable ssl on apache - however, ssl termination is intended to be done by jwilder/nginx-proxy instead
# RUN a2ensite default-ssl
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN a2dissite 000-default.conf
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default.conf
#RUN service apache2 start

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
