[![logo](https://raw.githubusercontent.com/dperson/nginx/master/logo.png)](http://nginx.org)

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

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx

Then you can hit `http://hostname:8080` or `http://host-ip:8080` in your
browser.

## Hosting some local simple static content

    sudo docker run -it -p 80:80 -p 443:443 \
                -v /some/path:/srv/www:ro -d dperson/nginx

## Complex configuration

    sudo docker run -it --rm dperson/nginx -h

    Usage: nginx.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -6          Disable IPv6
        -B  "[on|off]" Enables/disables the proxy request buffer,
                    so that requests are passed through [on/off] (Default on)
        -b "[location][;IP]" Configure basic auth for "location"
                    possible arg: [location] (defaults to '/')
                    [location] is the URI in nginx (IE: /wiki)
                    [;IP] addresses that don't have to authenticate
        -C ""       Configure Content Security Policy header
        -c "<max_size>" Configure the client_max_body_size for uploads
        -e ""       Configure EXPIRES header on static assets
                    possible arg: "[timeout]" - timeout for cached files
        -f "<server;location>" Configure fastcgi proxy and location
                    required arg: "<server[:port]>;</location>"
                    <server> is hostname or IP to connect to
                    <location> is the URI in nginx (IE: /mediatomb)
        -g ""       Generate a selfsigned SSL cert
                    possible args: "[domain][;country][;state][;locality][;org]"
                        domain - FQDN for server
                        country - 2 letter country code
                        state - state of server location
                        locality - city
                        org - company
        -P          Configure Production mode (no server tokens)
        -p          Configure PFS (Perfect Forward Secrecy)
        -H          Configure HSTS (HTTPS Strict Transport Security)
        -I "<file>" Include a configuration file
                    required arg: "<file>"
                    <file> to be included
        -i          Enable SSI (Server Side Includes)
        -n          set server_name <name>[:oldname]
        -q          quick (don't create certs)
        -R ""       set header to stop robot indexing
                    possible arg: "[tag]"
                        all           no restrictions (default)
                        noindex       don't show in search results or "Cached" link
                        nofollow      don't follow the links on this page
                        none          equivalent to noindex, nofollow
                        noarchive     don't show a "Cached" link in search results
                        nosnippet     don't show a snippet in the search results
                        noodp         don't use Open Directory project metadata
                        notranslate   don't offer translation of this page
                        noimageindex  don't index images on this page
                        unavailable_after: [RFC-850 date/time] don't show after
                                    the specified date/time (RFC 850 format)
        -r "<service;location>" Redirect a hostname to a URL
                    required arg: "<hostname>;<https://destination/URI>"
                    <hostname> to listen for (Fully Qualified Domain Name)
                    <destination> where to send the requests
        -S ""       Configure SSL sessions
                    possible arg: "[timeout]" - timeout for session reuse, IE 5m
        -s "<cert>" Configure SSL stapling
                    required arg: cert(s) your CA uses for the OCSP check
        -T "<server;dest>[;protocol]" Configure a stream proxy
                    required arg: "<[IP:]port>;<dest>"
                    <server> what (optional) IP and (required) port to listen on
                    <dest> where to send the requests to <name_or_IP>:<port>
                    possible third arg: "[protocol]"
                    [protocol] if not TCP, specify here (IE "udp")
        -t ""       Configure timezone
                    possible arg: "[timezone]" - zoneinfo timezone for container
        -U "<username;password>" Configure a HTTP auth user
                    required arg: "username;password"
                    <username> is the name the user enters for authorization
                    <password> is the password the user enters for authorization
        -u "<service;location>" Configure UWSGI proxy and location
                    required arg: "<server:port|unix:///path/to.sock>;</location>"
                    <service> is how to contact UWSGI
                    <location> is the URI in nginx (IE: /wiki)
        -W "<service;hosts>" Configure web proxy hostname and location
                    required arg: "http://<server[:port]>/;hosts"
                    <service> is how to contact the HTTP service
                    <hosts> is a comma separated list of host names (minimum of 1)
                    NOTE: the webserver will listen, but DNS is still needed
                    possible args: "[header value]" "[sockets]"
                    [header value] set "header" to "value" on traffic going
                                through the proxy
                    [sockets] if set to "no" don't enable use of websockets
        -w "<service;location>" Configure web proxy and location
                    required arg: "http://<server[:port]>/;/<location>/"
                    <service> is how to contact the HTTP service
                    <location> is the URI in nginx (IE: /mediatomb)
                    possible args: "[header value]" "[sockets]"
                    [header value] set "header" to "value" on traffic going
                                through the proxy
                    [sockets] if set to "no" don't enable use of websockets

    The 'command' (if provided and valid) will be run instead of nginx

ENVIRONMENT VARIABLES

 * `IPV6` - As above, disables IPv6 support
 * `BASIC` - As above, setup basic auth for URI location, IE `/path`
 * `EXPIRES` - As above, configure EXPIRES header on static assets
 * `FASTCGI` - As above, configure a fastcgi proxy
 * `GENCERT` - As above, make selfsigned SSL cert
 * `PFS` - As above, configure Perfect Forward Secracy
 * `PROD` - As above, production server flags
 * `HSTS` - As above, HTTPS Strict Transport Security
 * `INCLUDE` - As above, file to be included in configuration
 * `SSI` - As above, setup basic auth for URI location, IE `/path`
 * `NAME` - As above, set servername
 * `OUICK` - As above, don't generate SSL cert
 * `REDIRECT` - As above, configure redirect `port;hostname;https://dest/url`
 * `ROBOT` - As above, set header to stop robot indexing
 * `STREAM` - As above, configure a stream proxy
 * `STAPLING` - As above, configure SSL stapling
 * `SSL_SESSIONS` - As above, setup SSL session reuse
 * `TZ` - As above, configure the zoneinfo timezone, IE `EST5EDT`
 * `HTTPUSER` - As above, configure HTTP user `username;password` (See NOTE2)
 * `USWGI` - As above, configure UWSGI app `http://dest:port/url;/path`
 * `PROXY` - As above, configure proxy to app `http://dest/url/;/path/`
 * `PROXY_HOST` - As above, configure proxy to app `http://dest/url/;host.name/`
 * `PROXYBUFFER` - Enables or disabled the proxy request buffer `[on|off]`
 * `USERID` - Set the UID for the webserver user
 * `GROUPID` - Set the GID for the webserver user
 * `CLIENTMAXBODYSIZE` - Set the max file size for uploads
 * `CONTENTSECURITY` - Set a CSP (Content Security Policy)

**NOTE**: The `-r`/`REDIRECT` no longer require the port be specified.

**NOTE2**: optionally supports additional variables starting with the same name,
IE `HTTPUSER` also will work for `HTTPUSER2`, `HTTPUSER3`... `HTTPUSERx`, etc.

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec -it nginx nginx.sh` (as of version 1.3 of docker).

### Start nginx with your real CA certs and setup SSL stapling:

    sudo docker run -it --name web -p 80:80 -p 443:443 -d dperson/nginx -q
    sudo docker exec -it web nginx.sh -q -s echo Stapling configured

Will get you the same settings as

    sudo docker run -it --name web -p 80:80 -p 443:443 -d dperson/nginx -q -s

Then run

    cat /path/to/your.cert.file | \
                sudo docker exec -it web tee /etc/nginx/ssl/fullchain.pem
    cat /path/to/your.key.file | \
                sudo docker exec -it web tee /etc/nginx/ssl/privkey.pem
    cat /path/to/your.ocsp.file | \
                sudo docker exec -it web tee /etc/nginx/ssl/chain.pem
    sudo docker restart web

### Start a wiki running in an uwsgi container behind nginx:

    sudo docker run -it --name wiki -d dperson/moinmoin
    sudo docker run -it -p 80:80 -p 443:443 --link wiki:wiki -d dperson/nginx \
                -u "wiki:3031;/wiki"

OR

    sudo docker run -it --name wiki -d dperson/moinmoin
    sudo docker run -it -p 80:80 -p 443:443 --link wiki:wiki \
                -e UWSGI="wiki:3031;/wiki" -d dperson/nginx

### Start nginx with a redirect:

nginx will listen on a port for the hostname, and redirect to a different URL
format (port;hostname;destination)

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx \
                -r "80;myapp.example.com;https://myapp.herokuapp.com" \
                -r "443;myapp.example.com;https://myapp.herokuapp.com"

ENVIRONMENT variables don't support multiple values, use args as above

### Start nginx with a web proxy:

    sudo docker run -it --name smokeping -d dperson/smokeping
    sudo docker run -it -p 80:80 -p 443:443 --link smokeping:smokeping \
                -d dperson/nginx -w "http://smokeping/smokeping/;/smokeping/"

OR

    sudo docker run -it --name smokeping -d dperson/smokeping
    sudo docker run -it -p 80:80 -p 443:443 --link smokeping:smokeping \
                 -e PROXY="http://smokeping/smokeping/;/smokeping/" \
                 -d dperson/nginx

### Start nginx with a specified zoneinfo timezone:

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -t EST5EDT

OR

    sudo docker run -it -p 80:80 -p 443:443 -e TZ=EST5EDT -d dperson/nginx

### Start nginx with a defined hostname (instead of 'localhost'):

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -n "example.com"

OR

    sudo docker run -it -p 80:80 -p 443:443 -e NAME="example.com" \
                -d dperson/nginx

### Start nginx with server tokens disabled (Production mode):

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -P

OR

    sudo docker run -it -p 80:80 -p 443:443 -e PROD=y -d dperson/nginx

### Start nginx with X-Robots-Tag header (block indexing):

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -R

OR

    sudo docker run -it -p 80:80 -p 443:443 -e ROBOT=y -d dperson/nginx

### Start nginx with SSI (Server Side Includes) enabled:

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -i

OR

    sudo docker run -it -p 80:80 -p 443:443 -e SSI=y -d dperson/nginx

### Start nginx with Perfect Forward Secrecy and HTTP Strict Transport Security:

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -p -H

OR

    sudo docker run -it -p 80:80 -p 443:443 -e PFS=1 -e HSTS=y -d dperson/nginx

### Start nginx with SSL Sessions (better performance for clients):

    sudo docker run -it -p 80:80 -p 443:443 -d dperson/nginx -S ""

OR

    sudo docker run -it -p 80:80 -p 443:443 -e SSL_SESSIONS=5m -d dperson/nginx

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