FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    libpq-dev \
    unzip \
    git \
    && docker-php-ext-install pdo pdo_mysql mysqli

WORKDIR /var/www/html