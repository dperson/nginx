#!/usr/bin/env bash
#===============================================================================
#          FILE: nginx.sh
#
#         USAGE: ./nginx.sh
#
#   DESCRIPTION: Entrypoint for nginx docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.1
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### basic: Basic Auth
# Arguments:
#   location) optional location for basic auth
#   IP) optionl range(s) to allow without auth
# Return: configure Basic Auth
basic() { local loc="${1:-\\/}" dav file=/etc/nginx/conf.d/default.conf
    shift
    [[ ${1:-""} =~ ^dav ]] && {
        dav="$(sed 's/^dav#//; s/#/ /g' <<< ${1:-""})"; shift; }

    grep -q '^[^#]*location '"$loc" $file ||
        sed -i '/location \/ /,/^    }/ { /^    }/a\
\
    location '"$loc"' {\
        autoindex on;\
    }
        }' $file

    sed -n '/location '"$(sed 's|/|\\/|g' <<< $loc)"' /,/^    }/p' $file |
                grep -q auth_basic ||
        sed -i '/location '"$(sed 's|/|\\/|g' <<<$loc)"' /,/^    }/ { /^    }/i\
'"$([[ ${dav:-""} ]] && echo '\' && echo "        create_full_put_path on;\\" &&
            echo "        dav_access $dav;\\" &&
            echo "        dav_methods PUT DELETE MKCOL COPY MOVE;\\"
[[ ${1:-""} ]] && echo '\'; for i; do
    echo -e '        allow '"$i"';\'
done; [[ ${1:-""} ]] && echo ' ')"'\
        auth_basic           "restricted access";\
        auth_basic_user_file /etc/nginx/htpasswd;\
\
        satisfy any;
        }' $file
}

### client_max_body_size: set a max body size for large uploads
# Arguments:
#  none)
# Return: The set body size
client_max_body_size() { local value="${1:-100M}" \
                file=/etc/nginx/conf.d/body_size.conf
    cat >$file <<-EOF
		# Set the client_max_body_size for large uploads
		# This can be represented as 10M for 10 MB rather than in bytes
		client_max_body_size $value;
		EOF
}

### content_security: set a Content Security Policy header
# Arguments:
#  policy) optional policy
# Return: The set body size
content_security() { local policy="${1:-default-src: https: 'unsafe-inline'}" \
                file=/etc/nginx/conf.d/content_security.conf
    cat >$file <<-EOF
		# Set a Content Security Policy header
		add_header Content-Security-Policy "$policy";
		EOF
}

### proxy_request_buffering: set a max body size for large uploads
# Arguments:
#  none)
# Return: The set proxy request buffer state
proxy_request_buffering() { local value="$1" \
                file=/etc/nginx/conf.d/proxy_request_buffering.conf
    cat >$file <<-EOF
		# Disabled or enables the proxy_request_buffering, which is
		# useful for large uploads. This can be represented as either
		# on or off
		proxy_request_buffering $value;
		EOF
}

### gencert: Generate SSL cert
# Arguments:
#   domain) FQDN for server
#   country) 2 letter country code
#   state) state of server location
#   locality) city
#   org) company
# Return: self-signed certs will be generated
gencert() { local domain="${1:-*}" country="${2:-NO}" state="${3:-Rogaland}" \
            locality="${4:-Sola}" org="{5:-None}" dir=/etc/nginx/ssl
    local cert="$dir/fullchain.pem" key="$dir/privkey.pem"
    [[ -e $cert ]] && return
    [[ -d $dir ]] || mkdir -p $dir

    openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert -days 3600 \
        -nodes -subj "/C=$country/ST=$state/L=$locality/O=$org/CN=$domain"
}

### ipv6: disables ipv6
# Arguments:
#   none)
# Return: disables ipv6
ipv6() { local file=/etc/nginx/conf.d/default.conf
    sed -i '/::/d' $file
}

### pfs: Perfect Forward Secrecy
# Arguments:
#   none)
# Return: setup PFS config
pfs() { local dir=/etc/nginx; local cert="$dir/ssl/ffdhe4096.pem" \
            file="$dir/conf.d/perfect_forward_secrecy.conf"
    [[ -d $dir/ssl ]] || mkdir -p $dir/ssl

    [[ -e $cert ]] ||
        echo -n '-----BEGIN DH PARAMETERS-----
MIICCAKCAgEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEfz9zeNVs7ZRkDW7w09N75nAI4YbRvydbmyQd62R0mkff3
7lmMsPrBhtkcrv4TCYUTknC0EwyTvEN5RPT9RFLi103TZPLiHnH1S/9croKrnJ32
nuhtK8UiNjoNq8Uhl5sN6todv5pC1cRITgq80Gv6U93vPBsg7j/VnXwl5B0rZp4e
8W5vUsMWTfT7eTDp5OWIV7asfV9C1p9tGHdjzx1VA0AEh/VbpX4xzHpxNciG77Qx
iu1qHgEtnmgyqQdgCpGBMMRtx3j5ca0AOAkpmaMzy4t6Gh25PXFAADwqTs6p+Y0K
zAqCkc3OyX3Pjsm1Wn+IpGtNtahR9EGC4caKAH5eZV9q//////////8CAQI=
-----END DH PARAMETERS-----' >$cert
    echo "ssl_dhparam $cert;" >>$file
    echo '' >>$file

    echo -n "ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:" >>$file
    echo -n "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:" >>$file
    echo -n "ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:" >>$file
    echo -n "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:" >>$file
    echo -n "ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:" >>$file
    echo -n "ECDHE-RSA-AES128-SHA256:" >>$file
    echo "!DSS:!aNULL:!eNULL:!EXPORT:!RC4:!DES:!3DES:!SSLv2:!MD5:!PSK';" >>$file
    grep -rq ssl_prefer_server_ciphers /etc/nginx ||
        echo 'ssl_prefer_server_ciphers on;' >>$file
    grep -rq ssl_protocols /etc/nginx ||
        echo "ssl_protocols TLSv1.2;" >>$file
}

### prod: Production mode
# Arguments:
#   none)
# Return: Turn off server tokens
prod() { local file=/etc/nginx/nginx.conf
    sed -i '/# *server_tokens/s|# *||' $file
    grep -q server_tokens $file || sed -i '/^ *sendfile/ i\
    server_tokens   off;' $file
    sed -i 's|\(^ *server_tokens *\).*|\1off;|' $file
}

### hsts: HTTP Strict Transport Security
# Arguments:
#   none)
# Return: configure HSTS
hsts() { local file=/etc/nginx/conf.d/hsts.conf \
            file2=/etc/nginx/conf.d/default.conf
    cat >$file <<-EOF
	# HTTP Strict Transport Security (HSTS)
	add_header Strict-Transport-Security \
	            "max-age=15768000; includeSubDomains; preload" always;
	add_header Front-End-Https "on" always;

	# This will prevent certain click-jacking attacks, but will prevent
	# other sites from framing your site, so delete or modify as necessary!
	add_header X-Content-Type-Options "nosniff" always;
	add_header X-Download-Options "noopen" always;
	add_header X-Frame-Options "SAMEORIGIN" always;
	add_header X-Permitted-Cross-Domain-Policies "none";

	# Header enables the Cross-site scripting (XSS) filter in most browsers.
	# This will re-enable it for this website if it was user disabled.
	add_header X-XSS-Protection "1; mode=block" always;
	EOF
    sed -i '/^ *listen 80/,/^}/ { /proxy_cache/,/^}/c\
\
    location ^~ /\.well-known/ {\
        break;\
    }\
    rewrite ^(.*) https://$host$1 permanent;\
}
                }' $file2
}

### http_user: HTTP auth user
# Arguments:
#   user) user name for authentication
#   pass) password for authentication
# Return: configure HTTP auth user
http_user() { local user="$1" pass="$2" file=/etc/nginx/htpasswd
    [[ -e $file ]] || touch $file
    htpasswd -b $file "$user" "$pass" &>/dev/null
}

### name: Set server_name
# Arguments:
#   name) new server name
#   oldname) old name to change from (defaults to localhost)
# Return: configure server_name
name() { local name="$1" oldname="${2:-localhost}" \
            file=/etc/nginx/conf.d/default.conf
    sed -i 's|\(^ *server_name\) '"$oldname"';|\1 '"$name"';|' $file
}

### ssi: Server Side Includes
# Arguments:
#   none)
# Return: configure SSI
ssi() { local file=/etc/nginx/conf.d/default.conf
    sed -n '/location \/ /,/^    }/p' $file | grep -q ssi ||
        sed -i '/location \/ /,/^    }/ { /^    }/i\
\
        ssi on;
        }' $file
}

### redirect: redirect to another host
# Arguments:
#   hostname) where to listen
#   destination) where to send the request
# Return: hostname redirect added to config
redirect() { [[ $1 =~ ^[0-9]*$ ]] && shift; local hostname="$1" \
            destination="$2" file=/etc/nginx/conf.d/default.conf
    sed -n '/^server {/,/^}/p' $file | grep -q "rewrite.*$destination" ||
        sed -i '/^server {/,/^}/ { n; /rewrite.*https.*\$host.*}/b; /^}/i\
\
    if ($hostname ~ '"$hostname"') {\
        rewrite ^(.*) '"$destination"'$1 permanent;\
    }
            }' $file
}

### robot: set header that works like robots.txt
# Arguments:
#   none)
# Return: configure HSTS
robot() { local tag="${1:-none}" file=/etc/nginx/conf.d/robot.conf
    cat >$file <<-EOF
		# X-Robots-Tag
		# Directive     Meaning
		# all           no restrictions for indexing / serving (default)
		# noindex       don't show in search results or a "Cached" link
		# nofollow      don't follow the links on this page
		# none          equivalent to noindex, nofollow
		# noarchive     don't show a "Cached" link in search results
		# nosnippet     don't show a snippet in the search results
		# noodp         don't use Open Directory project metadata
		# notranslate   don't offer translation of this page
		# noimageindex  don't index images on this page
		# unavailable_after: [RFC-850 date/time] don't show after
		#               the specified date/time (RFC 850 format)
		add_header X-Robots-Tag $tag;
		EOF
}

### stream: Configure a stream proxy
# Arguments:
#   server) where to listen for connections
#   dest) where to forward connections
# Return: stream added to the config file
stream() { local server="$1" dest="$2" proto="${3:-""}" \
            file=/etc/nginx/conf.d/default.stream
    if grep -q "server { listen $server${proto:+ $proto};" $file; then
        sed -i '/^[^#]*server { listen '"$server${proto:+ $proto}"';/,/^}/d' \
                    $file
    fi
    echo -e "server { listen $server${proto:+ $proto};\n}" >>$file

    sed -i '/^[^#]*server { listen '"$server${proto:+ $proto}"';/a\
    proxy_connect_timeout 10s;\
    proxy_timeout 1800s;\
    proxy_pass '"$dest"';' $file
}

### ssl_sessions: Setup SSL session resumption
# Arguments:
#   timeout) how long to keep the session open
# Return: configure SSL sessions
ssl_sessions() { local timeout="${1:-1d}" file=/etc/nginx/conf.d/sessions.conf
    echo '# Session resumption (caching)' >$file
    echo 'ssl_session_cache shared:SSL:50m;' >>$file
    echo "ssl_session_tickets off;" >>$file
    echo "ssl_session_timeout $timeout;" >>$file
}

### stapling: SSL stapling
# Arguments:
#   cert) full path to cert file
# Return: configure SSL stapling
stapling() { local dir=/etc/nginx/ssl file=/etc/nginx/conf.d/stapling.conf
    local cert="${1:-$dir/chain.pem}"

    [[ -e $cert ]] || { echo "ERROR: invalid stapling cert: $cert" >&2;return; }

    echo '# OCSP (Online Certificate Status Protocol) SSL stapling' >$file
    echo 'ssl_stapling on;' >>$file
    echo 'ssl_stapling_verify on;' >>$file
    echo "ssl_trusted_certificate $cert;" >>$file
    echo 'resolver 8.8.4.4 8.8.8.8 valid=300s;' >>$file
    echo 'resolver_timeout 5s;' >>$file
}

### static: Setup long EXPIRES header on static assets
# Arguments:
#   timeout) how long to keep the cached files
# Return: configured static asset caching
static() { local timeout="${1:-30d}" file=/etc/nginx/conf.d/default.conf
    sed -i '/^    ## Optional: set long EXPIRES/,/^ *$/d' $file
    sed -i '/^    #error_page/i\
    ## Optional: set long EXPIRES header on static assets\
    location ~* \\.(jpg|jpeg|gif|bmp|ico|png|css|js|swf)$ {\
        expires '"$timeout"';\
        add_header Cache-Control private;\
        ## Optional: Do not log access to assets\
        access_log off;\
    }\
                ' $file
}

### fastcgi: Configure a fastcgi proxy
# Arguments:
#   server) hostname or IP to connect to
#   location) URI in web server
# Return: proxy added to the config file
fastcgi() { local server="$1" location="$2" file=/etc/nginx/conf.d/default.conf
    if grep -q "location $location {" $file; then
        sed -i '/^[^#]*location '"$(sed 's|/|\\/|g'<<<$location)"' {/,/^    }/c\
    location '"$location"' {\
    }' $file
    else
        sed -i '/^[^#]*location \/ {$/,/^    }$/ { /^    }/a\
\
    location '"$location"' {\
    }
        }' $file
    fi

    sed -i '/^[^#]*location '"$(sed 's|/|\\/|g' <<< $location)"' {/a\
        index              index.php;\
\
        location ~ \.*php {\
            fastcgi_split_path_info ^(.+?\.php)(/.*)$;\
            include         fastcgi_params;\
            fastcgi_index   index.php;\
            fastcgi_intercept_errors on;\
            fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;\
            fastcgi_param   PATH_INFO $fastcgi_path_info;\
            fastcgi_param   modHeadersAvailable true;\
            fastcgi_param   front_controller_active true;\
            fastcgi_pass    '"$server"';\
\
            ## Optional: Do not log, get it at the destination\
            access_log off;\
        }
        ' $file
}

### include: incude a configuration file
# Arguments:
#   file) to be included
# Return: file included in the config file
include() { local conf="$1" file=/etc/nginx/conf.d/default.conf
    grep -q "^[^#]*include $conf;\$" $file ||
        sed -i '/^[^#]*location \/ /,/^    }/ { /^    }/a\
\
    include '"$conf"';\

            }' $file
}

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() { local timezone="${1:-EST5EDT}"
    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified: $timezone" >&2
        return
    }

    if [[ -w /etc/timezone && $(cat /etc/timezone) != $timezone ]]; then
        echo "$timezone" >/etc/timezone
        ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
    fi
}

### uwsgi: Configure a UWSGI proxy
# Arguments:
#   service) where to contact UWSGI
#   location) URI in web server
# Return: UWSGI added to the config file
uwsgi() { local service="$1" location="$2" file=/etc/nginx/conf.d/default.conf
    if grep -q "location $location {" $file; then
        sed -i '/^[^#]*location '"$(sed 's|/|\\/|g'<<<$location)"' {/,/^    }/c\
    location '"$location"' {\
    }' $file
    else
        sed -i '/^[^#]*location \/ {$/,/^    }$/ { /^    }/a\
\
    location '"$location"' {\
    }
        }' $file
    fi

    sed -i '/^[^#]*location '"$(sed 's|/|\\/|g' <<< $location)"' {/a\
        uwsgi_pass '"$service"';\
        include uwsgi_params;\
        uwsgi_param SCRIPT_NAME '"$location"';\
        uwsgi_modifier1 30;\
\
        ## Optional: Do not log, get it at the destination\
        access_log off;
        ' $file
}

### proxy: Configure a web proxy
# Arguments:
#   service) where to contact HTTP service
#   location) URI in web server
#   header) a HTTP header to add as traffic flows through the web proxy
#   sockets) set to "no" to disable websockets
# Return: proxy added to the config file
proxy() { local service="$1" location="$2" header="${3:-""}" \
                sockets="${4:-yes}" file=/etc/nginx/conf.d/default.conf
    if grep -q "location $location {" $file; then
        sed -i '/^[^#]*location '"$(sed 's|/|\\/|g'<<<$location)"' {/,/^    }/c\
    location '"$location"' {\
    }' $file
    else
        sed -i '/^[^#]*location \/ {$/,/^    }$/ { /^    }/a\
\
    location '"$location"' {\
    }
        }' $file
    fi

    sed -i '/^[^#]*location '"$(sed 's|/|\\/|g' <<< $location)"' {/a\
        proxy_pass       '"$service"';\
        proxy_set_header Host $http_host;\
        proxy_set_header Range $http_range;\
        proxy_set_header If-Range $http_if_range;\
        proxy_set_header X-Forwarded-Host $host;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
        proxy_set_header X-Real-IP $remote_addr;\
        # Mitigate httpoxy attack (see README for details)\
        proxy_set_header Proxy "";\
        add_header Referrer-Policy "no-referrer";\
\
'"$([[ $header ]] && echo -e "        proxy_set_header $header;\\\n")"'\
\
'"$([[ $sockets != "no" ]] && echo '        ## Required for websockets\
        proxy_http_version 1.1;\
        proxy_set_header Connection "upgrade";\
        proxy_set_header Upgrade $http_upgrade;\
        proxy_read_timeout 3600s;\
        proxy_send_timeout 3600s;')"'\
\
        ## Optional: Do not log, get it at the destination\
        access_log off;
' $file
}

### proxy_host: Configure a web proxy hostname
# Arguments:
#   service) where to contact HTTP service
#   hosts) comma separated list of server_name's to listen on
#   header) a HTTP header to add as traffic flows through the web proxy
#   sockets) set to "no" to disable websockets
# Return: proxy added to the config file
proxy_host() { local service="$1" hosts="$2" header="${3:-""}" \
                sockets="${4:-yes}" file=/etc/nginx/conf.d/default.conf
    if grep -q "server { #${hosts%%,*}" $file; then
        sed -i '/^[^#]*server { #'"${hosts%%,*}"',/^}/c\
    server { #'"${hosts%%,*}"'\
}' $file
    else
        echo -e "\nserver { #${hosts%%,*}\n} #${hosts%%,*}" >>$file
    fi

    sed -i '/^server { #'"${hosts%%,*}"'/a\
    listen      443 ssl http2;\
    listen      [::]:443 ssl http2;\
\
    server_name '"$hosts"';\
\
    ssl_certificate      /etc/nginx/ssl/fullchain.pem;\
    ssl_certificate_key  /etc/nginx/ssl/privkey.pem;\
\
    add_header Referrer-Policy "no-referrer";\
    add_header Content-Security-Policy "frame-ancestors '"$(sed 's/,/ /g' <<< \
                $hosts)"'";\
\
    location / { # '"${hosts%%,*}"'\
        proxy_pass       '"$service"';\
        proxy_set_header Host $http_host;\
        proxy_set_header Range $http_range;\
        proxy_set_header If-Range $http_if_range;\
        proxy_set_header X-Forwarded-Host $host;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
        proxy_set_header X-Real-IP $remote_addr;\
        # Mitigate httpoxy attack (see README for details)\
        proxy_set_header Proxy "";\
'"$([[ $header ]] && echo -e "        proxy_set_header $header;\\\n")"'\
\
'"$([[ $sockets != "no" ]] && echo '        ## Required for websockets\
        proxy_http_version 1.1;\
        proxy_set_header Connection "upgrade";\
        proxy_set_header Upgrade $http_upgrade;\
        proxy_read_timeout 3600s;\
        proxy_send_timeout 3600s;')"'\
    } # '"${hosts%%,*}"'\
\
    ## Optional: Do not log, get it at the destination\
    access_log off;
' $file
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC="${1:-0}"
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -6          Disable IPv6
    -B  \"[on|off]\" Enables/disables the proxy request buffer,
                so that requests are passed through [on/off] (Default on)
    -b \"[location][;IP]\" Configure basic auth for \"location\"
                possible arg: [location] (defaults to '/')
                [location] is the URI in nginx (IE: /wiki)
                [;IP] addresses that don't have to authenticate
    -C \"\"       Configure Content Security Policy header
    -c \"<max_size>\" Configure the client_max_body_size for uploads
    -e \"\"       Configure EXPIRES header on static assets
                possible arg: \"[timeout]\" - timeout for cached files
    -f \"<server;location>\" Configure fastcgi proxy and location
                required arg: \"<server[:port]>;</location>\"
                <server> is hostname or IP to connect to
                <location> is the URI in nginx (IE: /mediatomb)
    -g \"\"       Generate a selfsigned SSL cert
                possible args: \"[domain][;country][;state][;locality][;org]\"
                    domain - FQDN for server
                    country - 2 letter country code
                    state - state of server location
                    locality - city
                    org - company
    -P          Configure Production mode (no server tokens)
    -p \"\"       Configure PFS (Perfect Forward Secrecy)
    -H          Configure HSTS (HTTP Strict Transport Security)
    -I \"<file>\" Include a configuration file
                required arg: \"<file>\"
                <file> to be included
    -i          Enable SSI (Server Side Includes)
    -n          set server_name <name>[:oldname]
    -q          quick (don't create certs)
    -R \"\"     set header to stop robot indexing
                possible arg: \"[tag]\"
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
    -r \"<service;location>\" Redirect a hostname to a URL
                required arg: \"<hostname>;<https://destination/URI>\"
                <hostname> to listen for (Fully Qualified Domain Name)
                <destination> where to send the requests
    -S \"\"       Configure SSL sessions
                possible arg: \"[timeout]\" - timeout for session reuse
    -s \"<cert>\" Configure SSL stapling
                required arg: cert(s) your CA uses for the OCSP check
    -T \"<server;dest>[;protocol]\" Configure a stream proxy
                required arg: \"<[IP:]port>;<dest>\"
                <server> what (optional) IP and (required) port to listen on
                <dest> where to send the requests to <name_or_IP>:<port>
                possible third arg: \"[protocol]\"
                [protocol] if not TCP, specify here (IE \"udp\")
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container
    -U \"<username;password>\" Configure a HTTP auth user
                required arg: \"username;password\"
                <username> is the name the user enters for authorization
                <password> is the password the user enters for authorization
    -u \"<service;location>\" Configure UWSGI proxy and location
                required arg: \"<server:port|unix:///path/to.sock>;</location>\"
                <service> is how to contact UWSGI
                <location> is the URI in nginx (IE: /wiki)
    -W \"<service;hosts>\" Configure web proxy hostname and location
                required arg: \"http://<server[:port]>/;hosts\"
                <service> is how to contact the HTTP service
                <hosts> is a comma separated list of host names (minimum of 1)
                **NOTE**: the webserver will listen, but DNS is still needed
                possible args: \"[header value]\" \"[sockets]\"
                [header value] set \"header\" to \"value\" on traffic going
                            through the proxy
                [sockets] if set to \"no\" don't enable use of websockets
    -w \"<service;location>\" Configure web proxy and location
                required arg: \"http://<server[:port]>/;/<location>/\"
                <service> is how to contact the HTTP service
                <location> is the URI in nginx (IE: /mediatomb)
                possible args: \"[header value]\" \"[sockets]\"
                [header value] set \"header\" to \"value\" on traffic going
                            through the proxy
                [sockets] if set to \"no\" don't enable use of websockets

The 'command' (if provided and valid) will be run instead of nginx
" >&2
    exit $RC
}

while getopts ":h6B:b:C:c:g:e:f:PpHI:in:R:r:S:s:T:t:U:u:W:w:q" opt; do
    case "$opt" in
        h) usage ;;
        6) ipv6 ;;
        B) proxy_request_buffering "$OPTARG" ;;
        b) eval basic $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        C) content_security "$OPTARG" ;;
        c) client_max_body_size "$OPTARG" ;;
        g) eval gencert $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        e) static $OPTARG ;;
        f) eval fastcgi $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        P) prod ;;
        p) pfs ;;
        H) hsts ;;
        I) include "$OPTARG" ;;
        i) ssi ;;
        n) eval name $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        q) quick=1 ;;
        R) robot "$OPTARG" ;;
        r) eval redirect $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        S) ssl_sessions $OPTARG ;;
        s) stapling $OPTARG ;;
        T) eval stream $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        t) timezone $OPTARG ;;
        U) eval http_user $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        u) eval uwsgi $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        W) eval proxy_host $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        w) eval proxy $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${IPV6:-""}" ]] && ipv6
[[ "${BASIC:-""}" ]] && eval basic $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $BASIC)
[[ "${GENCERT:-""}" ]] && eval gencert $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $GENCERT)
[[ "${EXPIRES:-""}" ]] && ssl_sessions $EXPIRES
[[ "${FASTCGI:-""}" ]] && eval fastcgi $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $FASTCGI)
[[ "${PFS:-""}" ]] && pfs
[[ "${PROD:-""}" ]] && prod
[[ "${HSTS:-""}" ]] && hsts
[[ "${INCLUDE:-""}" ]] && include "$INCLUDE"
[[ "${SSI:-""}" ]] && ssi
[[ "${STREAM:-""}" ]] && eval stream $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $STREAM)
[[ "${NAME:-""}" ]] && eval name $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< $NAME)
[[ "${OUICK:-""}" ]] && quick=1
[[ "${REDIRECT:-""}" ]] && eval redirect $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' \
            <<< $REDIRECT)
[[ "${ROBOT:-""}" ]] && robot "$ROBOT"
[[ "${STAPLING:-""}" ]] && stapling $STAPLING
[[ "${SSL_SESSIONS:-""}" ]] && ssl_sessions $SSL_SESSIONS
[[ "${TZ:-""}" ]] && timezone $TZ
while read i; do
    eval http_user $(sed 's/^/"/; s/$/"/; s/;/" "/g' <<< $i)
done < <(env | awk '/^HTTPUSER[0-9=_]/ {sub (/^[^=]*=/, "", $0); print}')
[[ "${UWSGI:-""}" ]] && eval uwsgi $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $UWSGI)
[[ "${PROXY:-""}" ]] && eval proxy $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $PROXY)
[[ "${PROXYHOST:-""}" ]] && eval proxy $(sed 's/^/"/g; s/$/"/g; s/;/" "/g' <<< \
            $PROXYHOST)
[[ "${PROXYBUFFER:-""}" ]] && proxy_request_buffering "$PROXYBUFFER"
[[ "${USERID:-""}" =~ ^[0-9]+$ ]] && usermod -u $USERID -o nginx
[[ "${GROUPID:-""}" =~ ^[0-9]+$ ]] && groupmod -g $GROUPID -o nginx
[[ "${CONTENTSECURITY:-""}" ]] && content_security "$CONTENTSECURITY"
[[ "${CLIENTMAXBODYSIZE:-""}" ]] && client_max_body_size "$CLIENTMAXBODYSIZE"

[[ -d /var/cache/nginx/cache ]] || mkdir -p /var/cache/nginx/cache
chown -Rh nginx. /var/cache/nginx 2>&1 | grep -iv 'Read-only' || :
[[ -d /etc/nginx/ssl || ${quick:-""} ]] || gencert
[[ -e /etc/nginx/conf.d/sessions.conf ]] || ssl_sessions
[[ ! -e /etc/nginx/ssl/chain.pem && -e /etc/nginx/ssl/ocsp.pem ]] &&
    sed -i 's|chain\.pem|ocsp.pem|' /etc/nginx/conf.d/stapling.conf
[[ ! -e /etc/nginx/ssl/fullchain.pem && -e /etc/nginx/ssl/cert.pem ]] &&
    sed -i 's|fullchain\.pem|cert.pem|' /etc/nginx/conf.d/default.conf
[[ ! -e /etc/nginx/ssl/privkey.pem  && -e /etc/nginx/ssl/key.pem ]] &&
    sed -i 's|privkey\.pem|key.pem|' /etc/nginx/conf.d/default.conf

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v 'grep|nginx.sh' | grep -q nginx; then
    echo "Service already running, please restart container to apply changes"
else
    exec nginx -g "daemon off;"
fi