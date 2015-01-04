FROM ubuntu:trusty
MAINTAINER David Personette <dperson@dperson.com>

ENV DEBIAN_FRONTEND noninteractive

# Install nginx
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys\
                00A6F0A3C300EE8C && \
    echo -n "deb http://ppa.launchpad.net/nginx/stable/ubuntu" >> \
                /etc/apt/sources.list && \
    echo " $(lsb_release -cs) main" >> /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends apache2-utils openssl nginx &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
# Forward request and error logs to docker log collector

COPY default /etc/nginx/sites-available/
COPY nginx.sh /usr/bin/

VOLUME ["/srv/www", "/etc/nginx"]

EXPOSE 80 443

ENTRYPOINT ["nginx.sh"]
