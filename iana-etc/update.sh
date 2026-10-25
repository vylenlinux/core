#!/bin/sh

url_protocol_numbers="https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xml"
url_service_names_port_numbers="https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"

download() {
    datetime="$(date +'%FT%T%z')"

    printf 'Downloading protocols\n'
    curl -o protocols.xml "${url_protocol_numbers}" || exit 20

    printf 'Downloading services\n'
    curl -o services.xml "${url_service_names_port_numbers}" || exit 21
}

process() {
    printf 'Processing protocols\n'

    awk -F "[<>]" -v url="${url_protocol_numbers}" -v date_time="${datetime}" 'BEGIN {
        print "# /etc/protocols, created " date_time;
        print "# Source: " url;
    } /<record/ {
        v = n = "";
    } /<value/ {
        v = $3;
    } /<name/ && $3!~/ / {
        n = $3;
    } /<\/record/ && n && (v != "") {
        printf "%-12s %3i %s\n", tolower(n), v, n;
    }' < protocols.xml > protocols.new

    ret="$?"
    [ "$ret" -eq 0 ] || exit 30

    printf 'Processing services\n'

    awk -F "[<>]" -v url="${url_service_names_port_numbers}" -v date_time="${datetime}" 'BEGIN{
        print "# /etc/services, created " date_time;
        print "# Source: " url;
    } /<record/ {
        n = u = p = c = "";
    } /<name/ && !/\(/ {
        n = $3;
    } /<number/ {
        u = $3;
    } /<protocol/ {
        p = $3;
    } /Unassigned/ || /Reserved/ || /historic/ {
        c = 1;
    } /<\/record/ && n && u && p && !c {
        printf "%-15s %5i/%s\n", n, u, p;
    }' < services.xml > services.new

    ret="$?"
    [ "$ret" -eq 0 ] || exit 31
}

update() {
    mv protocols.new protocols || exit 40
    mv services.new services || exit 41

    rm -f protocols.xml services.xml || exit 42
}

download
process
update
