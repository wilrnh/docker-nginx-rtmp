FROM phusion/baseimage:0.9.18

RUN apt-get update

# Install FFMPEG
RUN \
  apt-get -y --force-yes install \
  autoconf automake build-essential pkg-config \
  libass-dev \
  libfreetype6-dev \
  libsdl1.2-dev \
  libtheora-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  texinfo \
  zlib1g-dev \
  yasm \
  libx264-dev \
  && mkdir /ffmpeg_sources /ffmpeg_build \
  && cd /ffmpeg_sources \
  && curl -Lo fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/archive/v0.1.4.tar.gz \
  && tar xzvf fdk-aac.tar.gz \
  && cd fdk-aac-0.1.4/ \
  && autoreconf -fiv \
  && ./configure --prefix="/ffmpeg_build" --disable-shared \
  && make \
  && make install \
  && make distclean \
  && cd /ffmpeg_sources \
  && curl -LO https://github.com/FFmpeg/FFmpeg/releases/download/n3.0/ffmpeg-3.0.tar.bz2 \
  && tar xjvf ffmpeg-3.0.tar.bz2 \
  && cd ffmpeg-3.0 \
  && PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/ffmpeg_build/include" \
    --extra-ldflags="-L/ffmpeg_build/lib" \
    --bindir="/usr/bin" \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libx264 \
    --enable-nonfree \
  && make \
  && make install \
  && make distclean \
  && rm -rf /ffmpeg_sources /ffmpeg_build \
  \
  # Install Nginx
  && mkdir /nginx_sources \
  && cd /nginx_sources \
  && apt-get -y --force-yes install \
    autoconf automake build-essential \
    ca-certificates \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    libxslt-dev \
    libgd-dev \
    libgeoip-dev \
  && curl -LO http://nginx.org/download/nginx-1.9.12.tar.gz \
  && tar xvf nginx-1.9.12.tar.gz \
  && curl -Lo nginx-rtmp-module-1.1.7.10.tar.gz https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/v1.1.7.10.tar.gz \
  && tar xvf nginx-rtmp-module-1.1.7.10.tar.gz \
  && cd nginx-1.9.12 \
  && ./configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/etc/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --user=nginx \
      --group=nginx \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_stub_status_module \
      --with-http_auth_request_module \
      --with-http_xslt_module=dynamic \
      --with-http_image_filter_module=dynamic \
      --with-http_geoip_module=dynamic \
      --with-threads \
      --with-stream \
      --with-stream_ssl_module \
      --with-http_slice_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-file-aio \
      --with-http_v2_module \
      --with-cc-opt="-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security" \
      --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro" \
      --with-ipv6 \
      --add-module=/nginx_sources/nginx-rtmp-module-1.1.7.10 \
      --with-debug \
  && make && make install \
  && rm -rf /nginx_sources \
  && addgroup --system nginx \
  && adduser \
      --system \
      --disabled-login \
      --ingroup nginx \
      --no-create-home \
      --home /nonexistent \
      --gecos "nginx user" \
      --shell /bin/false \
      nginx \
  && mkdir -p \
      /usr/sbin \
      /etc/nginx/conf.d \
      /usr/lib/nginx/modules \
      /usr/share/nginx \
      /usr/share/nginx/html \
      /var/cache/nginx \
      /var/log/nginx \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && chown -R nginx:nginx /var/cache/nginx \
  \
  # Cleanup
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup Nginx service
RUN mkdir /etc/service/nginx
ADD etc_service_nginx_run /etc/service/nginx/run
ADD etc_initd_nginx /etc/init.d/nginx

EXPOSE 80 443

CMD ["/sbin/my_init"]
