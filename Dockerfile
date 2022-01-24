#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# from https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:7.4-apache-buster

RUN a2enmod rewrite
# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg=/usr \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
      echo 'post_max_size=512M'; \
      echo 'max_execution_time=6000'; \
      echo 'upload_max_filesize=256M'; \
      echo 'max_input_vars=5000'; \
      echo 'display_error=On'; \
      echo 'log_errors=On'; \
      echo 'memory_limit=2048M'; \
      echo 'error_log=/var/log/apache2/php-error.log'; \
      echo 'upload_emp_dir=/var/www/html/sites/default/files/tmp'; \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/



ENV GIT_BRANCH 9.3.x

RUN apt-get update && apt-get install -y git

WORKDIR /opt/drupal

RUN git clone -b $GIT_BRANCH https://github.com/V3Main-Tech/drupal.git /opt/drupal

RUN composer install

RUN composer require drush/drush

RUN cd /opt/drupal/sites/default && mkdir files && chmod 775 files

RUN cp -RL /opt/drupal/* /var/www/html/ && cp /opt/drupal/.htaccess /var/www/html 

RUN chown -R www-data:www-data /var/www/html/sites/default

RUN sed -i -e 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf && \
    sed -i -e 's/VirtualHost \*:80/VirtualHost *:8080/' /etc/apache2/sites-enabled/000-default.conf

#COPY ./custom.conf /etc/apache2/sites-enabled/custom.conf
#RUN chmod 755 /etc/apache2/sites-enabled/custom.conf
RUN /etc/init.d/apache2 restart

