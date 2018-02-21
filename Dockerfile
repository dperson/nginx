FROM debian:stretch
MAINTAINER David Personette <dperson@gmail.com>

# Install nginx
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends apache2-utils gnupg1 openssl \
                procps \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    apt-key adv --keyserver pgp.mit.edu --recv-keys ABF5BD827BD9BF62 && \
    echo "deb http://nginx.org/packages/mainline/debian/ stretch nginx" \
                >>/etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends nginx && \
    sed -i 's/#gzip/gzip/' /etc/nginx/nginx.conf && \
    sed -i "/http_x_forwarded_for\"';/s/';/ '/" /etc/nginx/nginx.conf && \
    sed -i "/http_x_forwarded_for/a \\\
                      '\$request_time \$upstream_response_time';" \
                /etc/nginx/nginx.conf && \
    echo "\n\nstream {\n    include /etc/nginx/conf.d/*.stream;\n}" \
                >>/etc/nginx/nginx.conf && \
    [ -d /srv/www ] || mkdir -p /srv/www && \
    mv /usr/share/nginx/html/index.html /srv/www/ && \
    apt-get purge -qqy gnupg1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
# Forward request and error logs to docker log collector

COPY default.conf /etc/nginx/conf.d/
COPY nginx.sh /usr/bin/

VOLUME ["/srv/www", "/etc/nginx"]

EXPOSE 80 443

ENTRYPOINT ["nginx.sh"]