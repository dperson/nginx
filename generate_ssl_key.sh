#!/usr/bin/env bash
#===============================================================================
#
#          FILE: generate_ssl_key.sh
#
#         USAGE: ./generate_ssl_key.sh
#
#   DESCRIPTION: Generate self-signed SSL keys
#
#       OPTIONS: FQDN, Country, State, Locality - for cert
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#Required
domain=${1:-*}

#Change to your details
country=${2:-NO}
state=${3:-Rogaland}
locality=${4:-Sola}
org=${5:-None}

cert=/etc/ssl/certs/cert.pem
key=/etc/ssl/private/key.pem

openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert -days 3600 \
    -nodes -subj "/C=$country/ST=$state/L=$locality/O=$org/CN=$domain"
