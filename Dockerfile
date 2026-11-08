FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pgsql \
    pdo_pgsql \
    zip \
    gd \
    intl \
    mbstring \
    soap \
    exif \
    opcache

# Enable Apache modules
RUN a2enmod rewrite headers

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY moodle-devops/moodle.ini /usr/local/etc/php/conf.d/moodle.ini

# Set working directory
WORKDIR /var/www/moodle

# Copy Moodle source code
COPY moodle/ .

# Install PHP dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Configure Apache document root (Moodle 5.1)
ENV APACHE_DOCUMENT_ROOT=/var/www/moodle/public

RUN sed -ri "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

# Create Moodle data directory
RUN mkdir -p /var/moodledata \
    && chown -R www-data:www-data /var/moodledata \
    && chown -R www-data:www-data /var/www/moodle

EXPOSE 80

CMD ["apache2-foreground"]