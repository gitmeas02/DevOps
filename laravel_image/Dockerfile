FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    nano \
    libpq-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    libsqlite3-dev \
    cron \
    gnupg2 \
    ca-certificates \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    opcache \
    curl \
    xml

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install Node.js (for Laravel Mix or Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Create necessary directories
RUN mkdir -p /var/www/html/production/public \
    && mkdir -p /var/www/html/staging/public \
    && mkdir -p /etc/nginx/sites-enabled \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/log/supervisor

# Copy Nginx configurations
COPY gici4c2025.com.conf /etc/nginx/sites-available/gici4c2025.com.conf
RUN ln -sf /etc/nginx/sites-available/gici4c2025.com.conf /etc/nginx/sites-enabled/

COPY gici4c2025.staging.conf /etc/nginx/sites-available/gici4c2025.staging.conf
RUN ln -sf /etc/nginx/sites-available/gici4c2025.staging.conf /etc/nginx/sites-enabled/

# Remove default Nginx site
RUN rm -f /etc/nginx/sites-enabled/default

# Configure PHP-FPM
RUN echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_children = 50" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.start_servers = 5" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.min_spare_servers = 5" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_spare_servers = 35" >> /usr/local/etc/php-fpm.d/www.conf

# Install SSH server
RUN apt-get update && apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && echo "root:P@ssw0rd1" | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf \
    && echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'logfile=/var/log/supervisor/supervisord.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'pidfile=/var/run/supervisord.pid' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:nginx]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=nginx -g "daemon off;"' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/supervisor/nginx.err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/supervisor/nginx.out.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:php-fpm]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=php-fpm -F' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/supervisor/php-fpm.err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/supervisor/php-fpm.out.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:sshd]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=/usr/sbin/sshd -D' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/supervisor/sshd.err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/supervisor/sshd.out.log' >> /etc/supervisor/conf.d/supervisord.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Create a startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo 'set -e' >> /start.sh \
    && echo '' >> /start.sh \
    && echo '# Set proper permissions' >> /start.sh \
    && echo 'chown -R www-data:www-data /var/www/html' >> /start.sh \
    && echo 'find /var/www/html -type d -exec chmod 755 {} \;' >> /start.sh \
    && echo 'find /var/www/html -type f -exec chmod 644 {} \;' >> /start.sh \
    && echo '' >> /start.sh \
    && echo '# Set Laravel specific permissions' >> /start.sh \
    && echo 'if [ -d "/var/www/html/production/storage" ]; then' >> /start.sh \
    && echo '  chmod -R 775 /var/www/html/production/storage' >> /start.sh \
    && echo '  chmod -R 775 /var/www/html/production/bootstrap/cache' >> /start.sh \
    && echo 'fi' >> /start.sh \
    && echo 'if [ -d "/var/www/html/staging/storage" ]; then' >> /start.sh \
    && echo '  chmod -R 775 /var/www/html/staging/storage' >> /start.sh \
    && echo '  chmod -R 775 /var/www/html/staging/bootstrap/cache' >> /start.sh \
    && echo 'fi' >> /start.sh \
    && echo '' >> /start.sh \
    && echo '# Start supervisor' >> /start.sh \
    && echo 'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /start.sh \
    && chmod +x /start.sh

EXPOSE 80 22

VOLUME ["/var/www/html"]

CMD ["/start.sh"]