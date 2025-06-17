# Use latest nginx as base
FROM nginx:latest

# Install PHP 8.2, PHP-FPM, and dependencies
RUN apt-get update && \
    apt-get install -y \
        lsb-release \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        git \
        openssh-server \
        php \
        php-fpm \
        php-curl \
        php-xml \
        php-sqlite3 \
        php-mbstring \
        php-zip \
        php-bcmath && \
    apt-get clean

# Set root password for SSH (not secure, dev use only)
RUN echo 'root:P@ssw0rd1' | chpasswd && \
    ssh-keygen -A

# Configure PHP-FPM socket
RUN sed -i 's|listen = .*|listen = /run/php/php8.2-fpm.sock|' /etc/php/8.2/fpm/pool.d/www.conf && \
    mkdir -p /run/php

# Create web root directory
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Copy configs if available
COPY default.conf /etc/nginx/conf.d/default.conf
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Start services
CMD service ssh start && service php8.2-fpm start && nginx -g 'daemon off;'
 