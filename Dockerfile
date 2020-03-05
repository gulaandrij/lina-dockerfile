FROM php:7.1-fpm

ARG XDEBUG_VERSION=2.9.2

#RUN printf "deb http://archive.ubuntu.com/ubuntu natty main restricted universe multiverse" > /etc/apt/sources.list

RUN apt-get update && apt-get -y install \
      autoconf \
      automake \
      build-essential \
      cmake \
      git-core \
      libass-dev \
      libfreetype6-dev \
      libsdl2-dev \
      libtool \
      libva-dev \
      libvdpau-dev \
      libvorbis-dev \
      libxcb1-dev \
      libxcb-shm0-dev \
      libxcb-xfixes0-dev \
      pkg-config \
      texinfo \
      wget \
      zlib1g-dev \
      nasm \
      yasm \
      libx265-dev \
      libnuma-dev \
      libvpx-dev \
      libmp3lame-dev \
      libopus-dev \
      libx264-dev

RUN mkdir -p ~/ffmpeg_sources ~/bin && cd ~/ffmpeg_sources && \
    wget -O ffmpeg-4.2.2.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.2.2.tar.bz2 && \
    tar xjvf ffmpeg-4.2.2.tar.bz2 && \
    cd ffmpeg-4.2.2 && \
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
      --prefix="$HOME/ffmpeg_build" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I$HOME/ffmpeg_build/include" \
      --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
      --extra-libs="-lpthread -lm" \
      --bindir="$HOME/bin" \
#      --enable-libfdk-aac \
      --enable-gpl \
      --enable-libass \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-nonfree && \
    PATH="$HOME/bin:$PATH" make -j8 && \
    make install -j8 && \
    hash -r
RUN mv ~/bin/ffmpeg /usr/local/bin && mv ~/bin/ffprobe /usr/local/bin && mv ~/bin/ffplay /usr/local/bin

RUN mkdir -p /usr/src/php/ext/xdebug && \
    curl -fsSL https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz | tar xz -C /usr/src/php/ext/xdebug --strip 1 && \
    docker-php-ext-install xdebug && \
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/php.ini

# Copy composer.lock and composer.json
COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
#    mysql-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
#    vim \
    unzip \
    git \
    curl \
    libpq-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_pgsql mbstring zip exif pcntl opcache
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
