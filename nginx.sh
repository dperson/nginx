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

    [[ -d $dir ]] || mkdir -p $dir

    [[ -e $dir/dh2048.pem ]] || openssl dhparam -out $dir/dh2048.pem 2048
    openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert -days 3600 \
        -nodes -subj "/C=$country/ST=$state/L=$locality/O=$org/CN=$domain"
}

### pfs: Perfect Forward Secrecy
# Arguments:
#   compat) Allow crusty old crypto
# Return: setup PFS config
pfs() {
    local compat=${1:-""}
    local file=/etc/nginx/conf.d/perfect_forward_secrecy.conf

    echo '# Diffie-Hellman parameter for DHE, recommended 2048 bits' > $file
    echo 'ssl_dhparam /etc/nginx/ssl/dh2048.pem;' >> $file
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

    cat > $file << EOF
add_header Strict-Transport-Security "max-age=15768000; includeSubDomains";
# This will prevent certain click-jacking attacks, but will prevent
# other sites from framing your site, so delete or modify as necessary!
add_header X-Frame-Options SAMEORIGIN;
EOF
}

### stapling: SSL stapling
# Arguments:
#   cert) full path to cert file
# Return: configure SSL stapling
stapling() {
    local cert=${1:-blank}
    local file=/etc/nginx/conf.d/stapling.conf

    [[ -e $cert ]] || echo "ERROR: invalid stapling cert: $cert" >&2

    echo 'ssl_stapling on;' > $file
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

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() {
    local RC=${1:-0}

    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional):
    -h          This help
    -g \"\"       Generate a selfsigned SSL cert
                possible args: \"[domain][:country][:state][:locality][:org]\"
                    domain - FQDN for server
                    country - 2 letter country code
                    state - state of server location
                    locality - city
                    org - company
    -p \"\"       Configure PFS (Perfect Forward Secrecy)
                possible arg: \"[compat]\" - allow old insecure crypto
    -H          Configure HSTS (HTTP Strict Transport Security)
    -s \"cert\"   Configure SSL stapling
                cert(s) your CA uses for the OCSP check
    -S \"\"       Configure SSL sessions
                possible arg: \"[timeout]\" - timeout for session reuse
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container
    -q          quick (don't create certs)

The 'command' (if provided and valid) will be run instead of nginx
" >&2
    exit $RC
}

while getopts ":hg:p:PHs:S:t:q" opt; do
    case "$opt" in
        h) usage ;;
        g) gencert $(sed 's/:/ /g' <<< $OPTARG) ;;
        p) pfs $OPTARG ;;
        P) prod ;;
        H) hsts ;;
        s) stapling $OPTARG ;;
        S) ssl_sessions $OPTARG ;;
        t) timezone $OPTARG ;;
        q) quick=1 ;;
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
