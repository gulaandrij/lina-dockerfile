FROM php:7.2-fpm

ARG XDEBUG_VERSION=2.9.2

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
      libmagickwand-dev \
      imagemagick \
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
      libx264-dev \
      libxrender1

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

RUN pecl install imagick-3.4.3
RUN docker-php-ext-enable imagick

#RUN apt-get update && apt-get -y install xvfb && apt-get -y install fontconfig && apt-get -y install libssl-dev && apt-get -y install libx11-dev libx11-xcb-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-shm0-dev libxcb-util0-dev libxcb-xfixes0-dev libxcb-xkb-dev libxcb1-dev libxfixes-dev libxrandr-dev libxrender-dev

RUN mkdir -p /usr/src/php/ext/xdebug && \
    curl -fsSL https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz | tar xz -C /usr/src/php/ext/xdebug --strip 1 && \
    docker-php-ext-install xdebug && \
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/php.ini

RUN apt-get update && \
    apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libwebp-dev libpng-dev
RUN docker-php-ext-configure gd --with-webp-dir=/usr/include/ --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

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
    libpq-dev \
    libgmp-dev 

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN mv wkhtmltox_0.12.5-1.stretch_amd64.deb /tmp/
RUN apt-get update
RUN apt-get install -y zlib1g fontconfig libxrender1 libfreetype6 libxext6 libx11-6 gnupg2
RUN apt-get install /tmp/wkhtmltox_0.12.5-1.stretch_amd64.deb -y

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
RUN apt-get update
RUN apt-get install -y postgresql-client-12

RUN rm /tmp/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN apt install --fix-broken --assume-yes
RUN ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install pdo_pgsql mbstring zip exif pcntl opcache bcmath gmp

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
