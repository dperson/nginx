[![logo](https://raw.githubusercontent.com/docker-library/docs/master/nginx/logo.png)](http://nginx.org)

# nginx

nginx docker container

## Fork of the main docker ["nginx"](https://registry.hub.docker.com/_/nginx/)

### With the following changes:

 * Entrypoint script to take care of most normal configuration needs
 * Sets up a self-signed SSL cert

# What is Nginx?

Nginx (pronounced "engine-x") is an open source reverse proxy server for HTTP,
HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer, HTTP cache,
and a web server (origin server). The nginx project started with a strong focus
on high concurrency, high performance and low memory usage. It is licensed under
the 2-clause BSD-like license and it runs on Linux, BSD variants, Mac OS X,
Solaris, AIX, HP-UX, as well as on other \*nix flavors. It also has a proof of
concept port for Microsoft Windows.

[wikipedia.org/wiki/Nginx](https://wikipedia.org/wiki/Nginx)

---

# How to use this image

## Exposing the port

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx

Then you can hit `http://hostname:8080` or `http://host-ip:8080` in your
browser.

## Hosting some local simple static content

    sudo docker run -p 80:80 -p 443:443 \
                -v /some/path:/srv/www:ro -d dperson/nginx

## Complex configuration

    sudo docker run -it --rm dperson/nginx -h

    Usage: nginx.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -b "[location]" Configure basic auth for "location"
                    possible arg: [location] (defaults to '/')
                    [location] is the URI in nginx (IE: /wiki)
        -e ""       Configure EXPIRES header on static assets
                    possible arg: "[timeout]" - timeout for cached files
        -g ""       Generate a selfsigned SSL cert
                    possible args: "[domain][;country][;state][;locality][;org]"
                        domain - FQDN for server
                        country - 2 letter country code
                        state - state of server location
                        locality - city
                        org - company
        -p          Configure PFS (Perfect Forward Secrecy)
                    NOTE: DH keygen is slow
        -P          Configure Production mode (no server tokens)
        -H          Configure HSTS (HTTPS Strict Transport Security)
        -i          Enable SSI (Server Side Includes)
        -n          set server_name <name>[:oldname]
        -q          quick (don't create certs)
        -r "<service;location>" Redirect a hostname to a URL
                    required arg: "<port>;<hostname>;<https://destination/URI>"
                    <port> to listen on
                    <hostname> to listen for (Fully Qualified Domain Name)
                    <destination> where to send the requests
        -s "<cert>" Configure SSL stapling
                    required arg: cert(s) your CA uses for the OCSP check
        -S ""       Configure SSL sessions
                    possible arg: "[timeout]" - timeout for session reuse, IE 5m
        -t ""       Configure timezone
                    possible arg: "[timezone]" - zoneinfo timezone for container
        -u "<service;location>" Configure UWSGI proxy and location
                    required arg: "<server:port|unix:///path/to.sock>;</location>"
                    <service> is how to contact UWSGI
                    <location> is the URI in nginx (IE: /wiki)
        -w "<service;location>" Configure web proxy and location
                    required arg: "http://<server[:port]>;</location>"
                    <service> is how to contact the HTTP service
                    <location> is the URI in nginx (IE: /mediatomb)

    The 'command' (if provided and valid) will be run instead of nginx

ENVIROMENT VARIABLES (only available with `docker run`)

 * `BASIC` - As above, setup basic auth for URI location, IE `/path`
 * `EXPIRES` - As above, Configure EXPIRES header on static assets
 * `GENCERT` - As above, make selfsigned SSL cert
 * `PFS` - As above, configure Perfect Forward Secracy
 * `PROD` - As above, production server flags
 * `HSTS` - As above, HTTPS Strict Transport Security
 * `SSI` - As above, setup basic auth for URI location, IE `/path`
 * `NAME` - As above, set servername
 * `OUICK` - As above, don't generate SSL cert
 * `REDIRECT` - As above, configure redirect `port;hostname;https://dest/url`
 * `STAPLING` - As above, configure SSL stapling
 * `SSL_SESSIONS` - As above, setup SSL session reuse
 * `TZ` - As above, set a zoneinfo timezone, IE `EST5EDT`
 * `USWGI` - As above, configure UWSGI app `http://dest:port/url;/path`
 * `PROXY` - As above, configure proxy to app `http://dest/url;/path`

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec nginx.sh` (as of version 1.3 of docker).

### Start nginx with your real CA certs and setup SSL stapling:

    sudo docker run -it --name web -p 80:80 -p 443:443 -d dperson/nginx -q
    sudo docker exec -it web nginx.sh -q -s echo Stapling configured

Will get you the same settings as

    sudo docker run -it --name web -p 80:80 -p 443:443 -d dperson/nginx -q -s

Then run

    cat /path/to/your.cert.file | \
                sudo docker exec -i web tee /etc/nginx/ssl/cert.pem
    cat /path/to/your.key.file | \
                sudo docker exec -i web tee /etc/nginx/ssl/key.pem
    cat /path/to/your.ocsp.file | \
                sudo docker exec -i web tee /etc/nginx/ssl/ocsp.pem
    sudo docker restart web

### Start a wiki running in an uwsgi container behind nginx:

    sudo docker run --name wiki -d dperson/moinmoin
    sudo docker run -p 80:80 -p 443:443 --link wiki:wiki -d dperson/nginx \
                -u "wiki:3031;/wiki"

OR

    sudo docker run --name wiki -d dperson/moinmoin
    sudo docker run -p 80:80 -p 443:443 --link wiki:wiki \
                -e UWSGI="wiki:3031;/wiki" -d dperson/nginx

### Start nginx with a redirect:

nginx will listen on a port for the hostname, and redirect to a different URL
format (port;hostname;destination)

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx \
                -r "80;myapp.example.com;https://myapp.herokuapp.com" \
                -r "443;myapp.example.com;https://myapp.herokuapp.com"

ENVIRONMENT variables don't support multiple values, use args as above

### Start nginx with a web proxy:

    sudo docker run --name smokeping -d dperson/smokeping
    sudo docker run -p 80:80 -p 443:443 --link smokeping:smokeping \
                -d dperson/nginx -w "http://smokeping/smokeping;/smokeping"

OR

    sudo docker run --name smokeping -d dperson/smokeping
    sudo docker run -p 80:80 -p 443:443 --link smokeping:smokeping \
                 -e PROXY="http://smokeping/smokeping;/smokeping" \
                 -d dperson/nginx

### Start nginx with a specified zoneinfo timezone:

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -t EST5EDT

OR

    sudo docker run -p 80:80 -p 443:443 -e TZ=EST5EDT -d dperson/nginx

### Start nginx with a defined hostname (instead of 'localhost'):

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -n "example.com"

OR

    sudo docker run -p 80:80 -p 443:443 -e NAME="example.com" -d dperson/nginx

### Start nginx with server tokens disabled (Production mode):

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -P

OR

    sudo docker run -p 80:80 -p 443:443 -e PROD=y -d dperson/nginx

### Start nginx with SSI (Server Side Includes) enabled:

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -i

OR

    sudo docker run -p 80:80 -p 443:443 -e SSI=y -d dperson/nginx

### Start nginx with Perfect Forward Secrecy and HTTP Strict Transport Security:

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -p -H

OR

    sudo docker run -p 80:80 -p 443:443 -e PFS=1 -e HSTS=y -d dperson/nginx

### Start nginx with SSL Sessions (better performance for clients):

    sudo docker run -p 80:80 -p 443:443 -d dperson/nginx -S ""

OR

    sudo docker run -p 80:80 -p 443:443 -e SSL_SESSIONS=5m -d dperson/nginx

---

For information on the syntax of the Nginx configuration files, see
[the official documentation](http://nginx.org/en/docs/) (specifically the
[Beginner's Guide](http://nginx.org/en/docs/beginners_guide.html#conf_structure)).

If you wish to adapt the default configuration, use something like the following
to copy it from a running container:

    sudo docker cp web:/etc/nginx/nginx.conf /some/nginx.conf

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/nginx/issues).
