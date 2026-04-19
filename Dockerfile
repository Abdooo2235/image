FROM php:8.3-cli-bookworm

ARG IMAGEMAGICK_VERSION=7.1.2-15

# install dependencies for building ImageMagick and PHP extensions
RUN apt-get update -o Acquire::Retries=3 \
        && apt-get install -y --no-install-recommends \
            libjpeg-dev \
            libgif-dev \
            libtiff-dev \
            libpng-dev \
            libwebp-dev \
            libavif-dev \
            libheif-dev \
            libraqm-dev \
            libopenjp2-7-dev \
            liblcms2-dev \
            git \
            zip \
            curl \
            xz-utils \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# build and install ImageMagick from source
RUN curl -o /tmp/ImageMagick.tar.xz -sL \
        "https://imagemagick.org/archive/releases/ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz" \
        && cd /tmp \
        && tar xf ImageMagick.tar.xz \
        && cd "ImageMagick-${IMAGEMAGICK_VERSION}" \
        && ./configure \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
        && cd / \
        && rm -rf /tmp/ImageMagick*

# install PHP extensions
# Pin imagick below 3.8.x to avoid transient PHP-Parser tarball fetch failures.
RUN pecl channel-update pecl.php.net \
        && pecl install imagick-3.7.0 \
        && pecl install xdebug \
        && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
        && docker-php-ext-enable \
            imagick \
            xdebug \
        && docker-php-ext-install \
            gd \
            exif

# install composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# setup entrypoint
# Write the script bytes directly to guarantee LF-only line endings on every host OS.
RUN printf '\x23\x21\x2f\x62\x69\x6e\x2f\x73\x68\x0a\x73\x65\x74\x20\x2d\x65\x0a\x0a\x63\x6f\x6d\x70\x6f\x73\x65\x72\x20\x69\x6e\x73\x74\x61\x6c\x6c\x20\x2d\x2d\x71\x75\x69\x65\x74\x0a\x0a\x65\x78\x65\x63\x20\x22\x24\x40\x22\x0a' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
