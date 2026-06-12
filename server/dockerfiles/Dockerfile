# Build args — set by the build script
ARG PHP_FULL_VERSION=8.3.21
ARG PHP_MINOR_VERSION=8.3

# ── Stage 1: build PHP from source ────────────────────────────────────────────
FROM ubuntu:20.04 AS builder

ARG PHP_FULL_VERSION
ARG PHP_MINOR_VERSION
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    wget \
    pkg-config \
    autoconf \
    bison \
    re2c \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libonig-dev \
    libsqlite3-dev \
    libreadline-dev \
    libzip-dev \
    libargon2-dev \
    libsodium-dev \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q "https://www.php.net/distributions/php-${PHP_FULL_VERSION}.tar.gz" && \
    tar xzf "php-${PHP_FULL_VERSION}.tar.gz"

# Build PHP with /pvm as prefix — the CLI patches paths after extraction
RUN cd "php-${PHP_FULL_VERSION}" && ./configure \
        --prefix=/pvm \
        --with-config-file-path=/pvm/lib \
        --with-config-file-scan-dir=/pvm/lib/conf.d \
        --enable-fpm \
        --with-openssl \
        --with-curl \
        --with-zlib \
        --with-readline \
        --with-zip \
        --with-sodium \
        --with-password-argon2 \
        --with-gmp \
        --enable-mbstring \
        --enable-bcmath \
        --enable-calendar \
        --enable-exif \
        --enable-gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --enable-intl \
        --enable-opcache \
        --enable-pcntl \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --with-sqlite3 \
        --enable-mysqlnd \
        --with-pdo-sqlite \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
    && make -j"$(nproc)" \
    && make install

# Copy default configs
RUN mkdir -p /pvm/lib/conf.d && \
    cp "/build/php-${PHP_FULL_VERSION}/php.ini-production" /pvm/lib/php.ini && \
    if [ -f /pvm/etc/php-fpm.conf.default ]; then \
        cp /pvm/etc/php-fpm.conf.default /pvm/etc/php-fpm.conf; \
    fi && \
    if [ -f /pvm/etc/php-fpm.d/www.conf.default ]; then \
        cp /pvm/etc/php-fpm.d/www.conf.default /pvm/etc/php-fpm.d/www.conf; \
    fi

# ── Stage 2: export only the install files ────────────────────────────────────
FROM scratch AS export
COPY --from=builder /pvm /php
