FROM php:5.5-apache

MAINTAINER Thomas Nabord <thomas.nabord@prestashop.com>

ENV PS_DOMAIN prestashop
ENV DB_SERVER database
ENV DB_PORT 3306
ENV DB_NAME prestashop
ENV DB_USER root
ENV DB_PASSWD admin
ENV ADMIN_MAIL demo@prestashop.com
ENV ADMIN_PASSWD prestashop_demo
ENV PS_LANGUAGE en
ENV PS_COUNTRY gb
ENV PS_INSTALL_AUTO 0
ENV PS_DEV_MODE 0
ENV PS_HOST_MODE 0
ENV PS_HANDLE_DYNAMIC_DOMAIN 0

ENV PS_FOLDER_ADMIN admin
ENV PS_FOLDER_INSTALL install

RUN apt-get update \
	&& apt-get install -y libmcrypt-dev \
		libjpeg62-turbo-dev \
		libpcre3-dev \
		libpng12-dev \
		libfreetype6-dev \
		libxml2-dev \
		libicu-dev \
		mysql-client \
		wget \
		vim \
		nano \
		unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install iconv intl mcrypt pdo pdo_mysql mbstring soap gd zip

RUN docker-php-source extract \
	&& if [ -d "/usr/src/php/ext/mysql" ]; then docker-php-ext-install mysql; fi \
	&& if [ -d "/usr/src/php/ext/opcache" ]; then docker-php-ext-install opcache; fi \
	&& docker-php-source delete

ENV PS_VERSION 1.6.1.14

# (OPTION 1) Get PrestaShop from scratch
ADD https://www.prestashop.com/download/old/prestashop_1.6.1.14.zip /tmp/prestashop.zip
COPY config_files/ps-extractor.sh /tmp/
RUN mkdir /tmp/data-ps && unzip -q /tmp/prestashop.zip -d /tmp/data-ps/ && bash /tmp/ps-extractor.sh /tmp/data-ps && rm /tmp/prestashop.zip

# # (OPTION 2) Copy prestashop from source
# COPY public_html/. /var/www/html/.

# Copy config files
COPY config_files/docker_updt_ps_domains.php /var/www/html/

# Apache configuration
RUN a2enmod rewrite

# (OPTIONAL) CGI configuration
RUN a2enmod cgi
COPY config_files/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Apache permissions
RUN chown www-data:www-data -R /var/www/html/

# PHP configuration
COPY config_files/php.ini /usr/local/etc/php/

VOLUME /var/www/html/modules
VOLUME /var/www/html/themes
VOLUME /var/www/html/override
VOLUME /var/www/html/img

# In case you have permission problems after installing
RUN mkdir img/p || : \
	&& chmod -R 777 img/p \
	&& mkdir img/tmp || : \
	&& chmod -R 777 img/tmp

COPY config_files/docker_run.sh /tmp/
CMD ["/tmp/docker_run.sh"]
