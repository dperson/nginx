FROM ubuntu:trusty
MAINTAINER David Personette <dperson@dperson.com>

# Install nginx and uwsgi
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
                00A6F0A3C300EE8C && \
    echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" >> \
                /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -qqy --no-install-recommends openssl nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
# Forward request and error logs to docker log collector

# Configure
COPY nginx.sh /

VOLUME ["/usr/share/nginx/html", "/etc/nginx"]

EXPOSE 80 443

ENTRYPOINT ["nginx.sh"]
