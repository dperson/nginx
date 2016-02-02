FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install nginx
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-key adv --keyserver pgp.mit.edu --recv-keys \
                573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 && \
    /bin/echo -n "deb http://nginx.org/packages/mainline/debian/ jessie nginx" \
                >>/etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends apache2-utils openssl nginx \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    apt-get clean && \
    sed -i 's/#gzip/gzip/' /etc/nginx/nginx.conf && \
    sed -i "/http_x_forwarded_for\"';/s/';/ '/" /etc/nginx/nginx.conf && \
    sed -i "/http_x_forwarded_for/a \\\
                      '\$request_time \$upstream_response_time';" \
                /etc/nginx/nginx.conf && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
# Forward request and error logs to docker log collector

COPY default.conf /etc/nginx/conf.d/
COPY nginx.sh /usr/bin/

VOLUME ["/srv/www", "/etc/nginx"]

EXPOSE 80 443

ENTRYPOINT ["nginx.sh"]