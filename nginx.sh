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
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### basic: Basic Auth
# Arguments:
#   location) optional location for basic auth
# Return: configure Basic Auth
basic() {
    local loc=${1:-\\/}
    local file=/etc/nginx/sites-available/default
    shift

    grep -q '^[^#]*location '"$loc" $file ||
                sed -i '/location \/ /,/^    }/ { /^    }/a\
\
    location '"$loc"' {\
        try_files $uri $uri/ =404;\
    }
        }' $file

    sed -n '/location '"$(sed 's|/|\\/|' <<< $loc)"' /,/^    }/p' $file |
                grep -q auth_basic ||
        sed -i '/location '"$(sed 's|/|\\/|' <<< $loc)"' /,/^    }/ { /^    }/i\
'"$([[ ${1:-""} ]] && echo '\'; for i; do
    echo -e '        allow '"$i"';\'
done; [[ ${1:-""} ]] && echo ' ')"'\
        auth_basic           "restricted access";\
        auth_basic_user_file /etc/nginx/htpasswd;\
\
        satisfy any;
        }' $file
}

### gencert: Generate SSL cert
# Arguments:
#   domain) FQDN for server
#   country) 2 letter country code
#   state) state of server location
#   locality) city
#   org) company
# Return: self-signed certs will be generated
gencert() {
    local domain=${1:-*}
    local country=${2:-NO}
    local state=${3:-Rogaland}
    local locality=${4:-Sola}
    local org=${5:-None}

    local dir=/etc/nginx/ssl
    local cert=$dir/cert.pem
    local key=$dir/key.pem

    [[ -e $cert ]] && return
    [[ -d $dir ]] || mkdir -p $dir

    openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert -days 3600 \
        -nodes -subj "/C=$country/ST=$state/L=$locality/O=$org/CN=$domain"
}

### pfs: Perfect Forward Secrecy
# Arguments:
#   compat) Allow crusty old crypto
# Return: setup PFS config
pfs() {
    local compat=${1:-""}
    local dir=/etc/nginx/ssl
    local file=/etc/nginx/conf.d/perfect_forward_secrecy.conf

    [[ -d $dir ]] || mkdir -p $dir

    [[ -e $dir/dh2048.pem ]] || openssl dhparam -out $dir/dh2048.pem 2048

    echo '# Diffie-Hellman parameter for DHE, recommended 2048 bits' > $file
    echo 'ssl_dhparam '"$dir/dh2048.pem"';' >> $file
    echo '' >> $file
    echo 'ssl_prefer_server_ciphers on;' >> $file
    if [[ -z $compat ]]; then
        echo "ssl_protocols TLSv1 TLSv1.1 TLSv1.2;" >> $file
        echo "ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';" >> $file
    else
        echo "ssl_protocols SSLv3, TLSv1, TLSv1.1, TLSv1.2;" >> $file
        echo "ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128:AES256:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK';" >> $file
    fi
}

### prod: Production mode
# Arguments:
#   none)
# Return: Turn off server tokens
prod() {
    local file=/etc/nginx/nginx.conf

    sed -i '/# server_tokens/s/# //' $file
}

### hsts: HTTP Strict Transport Security
# Arguments:
#   none)
# Return: configure HSTS
hsts() {
    local file=/etc/nginx/conf.d/hsts.conf
    local file2=/etc/nginx/sites-available/default

    cat > $file << EOF
# HTTP Strict Transport Security (HSTS)
add_header Strict-Transport-Security "max-age=15768000; includeSubDomains";
# This will prevent certain click-jacking attacks, but will prevent
# other sites from framing your site, so delete or modify as necessary!
add_header X-Frame-Options SAMEORIGIN;
EOF
    sed -i '/^ *listen 80/,/^}/ { /proxy_cache/,/^}/c\
\
    rewrite ^(.*) https://$host$1 permanent;\
}
                }' $file2
}

### name: Set server_name
# Arguments:
#   name) new server name
#   oldname) old name to change from (defaults to localhost)
# Return: configure server_name
name() {
    local name=$1
    local oldname=${2:-localhost}
    local file=/etc/nginx/sites-available/default

    sed -i 's/\(^ *server_name\) '"$oldname"';/\1 '"$name"';/' $file
}

### ssi: Server Side Includes
# Arguments:
#   none)
# Return: configure SSI
ssi() {
    local file=/etc/nginx/sites-available/default

    sed -i '/location \/ /,/^    }/ { /^    }/i\
\
        ssi on;
        }' $file
}

### redirect: redirect to another host
# Arguments:
#   port) port to listen on
#   hostname) where to listen
#   destination) where to send the request
# Return: hostname redirect added to config
redirect() {
    local port=$1
    local hostname=$2
    local destination=$3
    local file=/etc/nginx/sites-available/default

    sed -i "$(grep -n '^}' $file | cut -d: -f1 | tail -1)"'a\
\
\
server {\
    listen '"$port"';\
    server_name '"$hostname"';\
'"$(grep -q 443 <<< $port && echo -e '\\\n    ssl on;\\
    ssl_certificate      /etc/nginx/ssl/cert.pem;\\
    ssl_certificate_key  /etc/nginx/ssl/key.pem;\\\n ')"'\
    rewrite ^(.*) '"$destination"'$1 permanent;\
}
                ' $file
}

### stapling: SSL stapling
# Arguments:
#   cert) full path to cert file
# Return: configure SSL stapling
stapling() {
    local dir=/etc/nginx/ssl
    local file=/etc/nginx/conf.d/stapling.conf
    local cert=${1:-$dir/ocsp.pem}

    [[ -e $cert ]] || { echo "ERROR: invalid stapling cert: $cert" >&2;return; }

    echo '# OCSP (Online Certificate Status Protocol) SSL stapling' > $file
    echo 'ssl_stapling on;' >> $file
    echo 'ssl_stapling_verify on;' >> $file
    echo "ssl_trusted_certificate $cert;" >> $file
    echo 'resolver 8.8.4.4 8.8.8.8 valid=300s;' >> $file
    echo 'resolver_timeout 5s;' >> $file
}

### ssl_sessions: Setup SSL session resumption
# Arguments:
#   timeout) how long to keep the session open
# Return: configure SSL sessions
ssl_sessions() {
    local timeout="${1:-5m}"
    local file=/etc/nginx/conf.d/sessions.conf

    echo '# Session resumption (caching)' > $file
    echo 'ssl_session_cache shared:SSL:50m;' >> $file
    echo "ssl_session_timeout $timeout;" >> $file
}

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() {
    local timezone="${1:-EST5EDT}"

    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified" >&2
        return
    }

    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
}

### uwsgi: Configure a UWSGI proxy
# Arguments:
#   service) where to contact UWSGI
#   location) URI in web server
# Return: UWSGI added to the config file
uwsgi() {
    local service=$1
    local location=$2
    local file=/etc/nginx/sites-available/default

    sed -i '/proxy_cache_path/,/^$/ { /^$/a\
\
upstream uwsgicluster {\
    server '"$service"';\
}\

        }' $file
    sed -i '/location \/ /,/^    }/ { /^    }/a\
\
    location '"$location"' {\
        proxy_cache_valid any 1m;\
        proxy_cache_min_uses 3;\
\
        uwsgi_pass uwsgicluster;\
        uwsgi_param SCRIPT_NAME '"$location"';\
        include uwsgi_params;\
        uwsgi_modifier1 30;\
    }
        }' $file
}

### proxy: Configure a web proxy
# Arguments:
#   service) where to contact HTTP service
#   location) URI in web server
# Return: proxy added to the config file
proxy() {
    local service=$1
    local location=$2
    local file=/etc/nginx/sites-available/default

    sed -i '/location \/ /,/^    }/ { /^    }/a\
\
    location '"$location"' {\
        proxy_pass       '"$service"';\
        proxy_set_header X-Real-IP $remote_addr;\
\
        proxy_buffering on;\
        proxy_buffers 8 4k;\
        proxy_busy_buffers_size 8k;\
\
        proxy_cache_valid any 1m;\
        proxy_cache_min_uses 3;\
    }
        }' $file
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() {
    local RC=${1:-0}

    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -b \"[location][;IP]\" Configure basic auth for \"location\"
                possible arg: [location] (defaults to '/')
                [location] is the URI in nginx (IE: /wiki)
                [;IP] addresses that don't have to authenticate
    -g \"\"       Generate a selfsigned SSL cert
                possible args: \"[domain][;country][;state][;locality][;org]\"
                    domain - FQDN for server
                    country - 2 letter country code
                    state - state of server location
                    locality - city
                    org - company
    -p \"\"       Configure PFS (Perfect Forward Secrecy)
                possible arg: \"[compat]\" - allow old insecure crypto
                NOTE: DH keygen is slow
    -P          Configure Production mode (no server tokens)
    -H          Configure HSTS (HTTP Strict Transport Security)
    -i          Enable SSI (Server Side Includes)
    -n          set server_name <name>[:oldname]
    -q          quick (don't create certs)
    -r \"<service;location>\" Redirect a hostname to a URL
                required arg: \"<port>;<hostname>;<https://destination/URI>\"
                <port> to listen on
                <hostname> to listen for (Fully Qualified Domain Name)
                <destination> where to send the requests
    -s \"<cert>\" Configure SSL stapling
                required arg: cert(s) your CA uses for the OCSP check
    -S \"\"       Configure SSL sessions
                possible arg: \"[timeout]\" - timeout for session reuse
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container
    -u \"<service;location>\" Configure UWSGI proxy and location
                required arg: \"<server:port|unix:///path/to.sock>;</location>\"
                <service> is how to contact UWSGI
                <location> is the URI in nginx (IE: /wiki)
    -w \"<service;location>\" Configure web proxy and location
                required arg: \"http://<server[:port]>;</location>\"
                <service> is how to contact the HTTP service
                <location> is the URI in nginx (IE: /mediatomb)

The 'command' (if provided and valid) will be run instead of nginx
" >&2
    exit $RC
}

while getopts ":hb:g:p:PHin:r:s:S:t:u:w:q" opt; do
    case "$opt" in
        h) usage ;;
        b) eval basic $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        g) eval gencert $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        p) pfs $OPTARG ;;
        P) prod ;;
        H) hsts ;;
        i) ssi ;;
        n) eval name $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        q) quick=1 ;;
        r) eval redirect $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        s) stapling $OPTARG ;;
        S) ssl_sessions $OPTARG ;;
        t) timezone $OPTARG ;;
        u) eval uwsgi $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        w) eval proxy $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ -d /var/cache/nginx/cache ]] || mkdir -p /var/cache/nginx/cache
[[ -d /etc/nginx/ssl || ${quick:-""} ]] || gencert
[[ -e /etc/nginx/conf.d/sessions.conf ]] || ssl_sessions

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
else
    exec nginx -g "daemon off;"
fi
