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

# How to use this image

Hosting some simple static content

    sudo docker run --name some-nginx -v /some/path:/usr/share/nginx/html:ro -d nginx

## Exposing the port

    sudo docker run --name some-nginx -d -p 8080:80 some-content-nginx

Then you can hit `http://localhost:8080` or `http://host-ip:8080` in your
browser.

## Complex configuration

    sudo docker run --name some-nginx -v /some/nginx.conf:/etc/nginx/nginx.conf:ro -d nginx

For information on the syntax of the Nginx configuration files, see
[the official documentation](http://nginx.org/en/docs/) (specifically the
[Beginner's Guide](http://nginx.org/en/docs/beginners_guide.html#conf_structure)).

If you wish to adapt the default configuration, use something like the following
to copy it from a running Nginx container:

    sudo docker cp some-nginx:/etc/nginx/nginx.conf /some/nginx.conf

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/nginx/issues).
