# nginx

nginx docker instance

## Fork of the main docker ["nginx"](https://registry.hub.docker.com/_/nginx/) - with the following changes:

 * Based on Ubuntu
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

![logo](https://raw.githubusercontent.com/docker-library/docs/master/nginx/logo.png)

---

# How to use this image

## Hosting some simple static content

    sudo docker run --name web -v /some/path:/usr/share/nginx/html:ro -d dperson/nginx

## Exposing the port

    sudo docker run --name web -p 8080:80 -d dperson/nginx

Then you can hit `http://localhost:8080` or `http://host-ip:8080` in your
browser.

## Complex configuration

    sudo docker run -it --rm dperson/nginx -h

    Usage: nginx.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -g ""       Generate a selfsigned SSL cert
                    possible args: "[domain][;country][;state][;locality][;org]"
                        domain - FQDN for server
                        country - 2 letter country code
                        state - state of server location
                        locality - city
                        org - company
        -p ""       Configure PFS (Perfect Forward Secrecy)
                    possible arg: "[compat]" - allow old insecure crypto
                    NOTE: DH keygen is slow
        -P          Configure Production mode (no server tokens)
        -H          Configure HSTS (HTTP Strict Transport Security)
        -i          Enable SSI (Server Side Includes)
        -n          set server_name <name>[:oldname]
        -q          quick (do not create certs)
        -r "<service;location>" Redirect a hostname to a URL
                    required arg: "<port>;<hostname>;<https://destination/URI>"
                    <port> to listen on
                    <hostname> to listen for (Fully Qualified Domain Name)
                    <destination> where to send the requests
        -s "<cert>" Configure SSL stapling
                    required arg: cert(s) your CA uses for the OCSP check
        -S ""       Configure SSL sessions
                    possible arg: "[timeout]" - timeout for session reuse
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

## Examples (all options can be run with either `docker run` or `docker start`

Start nginx with your real CA certs and setup SSL stapling:

    sudo docker run -it --name web -p 80:80 -p 443:443 -v /path/to/your/certs:/mnt:ro dperson/nginx -q bash
        cp /mnt/your.cert.file /etc/nginx/ssl/cert.pem
        cp /mnt/your.key.file /etc/nginx/ssl/key.pem
        cp /mnt/your.ocsp.file /etc/nginx/ssl/ocsp.pem
        exit
    sudo docker start web -s ""

Start a wiki running in an uwsgi container behind nginx:

    sudo docker run -d --name wiki dperson/moinmoin
    sudo docker run --rm -p 80:80 -p 443:443 --link wiki:wiki dperson/nginx -u "wiki:3031;/wiki"

Start nginx with a redirect (nginx will listen on a port for the hostname, and redirect to a different URL (port;hostname;destination)):

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -r "80;myapp.example.com;https://myapp.herokuapp.com" -r "443;myapp.example.com;https://myapp.herokuapp.com"

Start nginx with a web proxy:

    sudo docker run --rm --name smokeping dperson/smokeping
    sudo docker run --rm -p 80:80 -p 443:443 --link smokeping:smokeping dperson/nginx -w "http://smokeping/smokeping;/smokeping"

Start nginx with a specified zoneinfo timezone:

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -t EST5EDT

Start nginx with a defined hostname (instead of 'localhost'):

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -n "example.com"

Start nginx with server tokens disabled (Production mode):

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -P

Start nginx with SSI (Server Side Includes) enabled:

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -i

Start nginx with PFS (Perfect Forward Secrecy) and HSTS (HTTP Strict Transport Security):

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -p "" -H

Start nginx with SSL Sessions (better performance for clients):

    sudo docker run --rm -p 80:80 -p 443:443 dperson/nginx -S ""

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
