#!/bin/bash -e

[[ $DEBUG -gt 0 ]] && set -x || set +x

BASE_DIR="$(cd "$(dirname "$0")"; pwd)"
PROGNAME=${0##*/}

usage () {
    printf "Setup Kibana on AWS EC2 instance.\n\n"

    printf "$PROGNAME\n"
    printf "\t[-s KIBANA_SETTING] ...\n"
    printf "\t[-l public | private | localhost]\n"
    printf "\t[-o PORT]\n"
    printf "\t[-e ELASTICSEARCH_URL]\n"
    printf "\t[-h]\n\n"

    printf "OPTIONS\n"
    printf "\t[-s KIBANA_SETTING] ...\n\n"
    printf "\tKIBANA_SETTING format: key=value\n"
    printf "\tMulti -s is allowed.\n\n"

    printf "\t[-l public | private | localhost]\n\n"
    printf "\tNetwork interface to listen on. Default is 'private' IP.\n\n"

    printf "\t[-o port]\n\n"
    printf "\tPort to listen on. Default port is 5601.\n\n"

    printf "\t[-e ELASTICSEARCH_URL]\n\n"
    printf "\tElasticsearc URL. Default is 'http://<listen_on_ip>:9200'.\n\n"

    printf "\t[-h]\n\n"
    printf "\tThis help.\n\n"
    exit 255
}

get_ec2_private_ip () {
    curl http://169.254.169.254/latest/meta-data/local-ipv4
}

get_ec2_public_ip () {
    curl http://169.254.169.254/latest/meta-data/public-ipv4
}


settings=()
while getopts s:l:o:e:h opt; do
    case $opt in
        s)
            settings[${#settings[@]}]=$OPTARG
            ;;
        l)
            listen=$OPTARG
            ;;
        o)
            port=$OPTARG
            ;;
        e)
            es_url=$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

if [[ -z $listen ]]; then
    listen='private'
fi

if [[ -z $port ]]; then
    port=5601
fi

# kibana settings

case $listen in
    private)
        ip=$(get_ec2_private_ip)
        ;;
    public)
        ip=$(get_ec2_public_ip)
        ;;
    localhost)
        ip='127.0.0.1'
        ;;
esac

if [[ -z $es_url ]]; then
    es_url="http://$ip:9200"
fi

content="
server.host: \"${ip:?}\"
server.port: ${port:?}
elasticsearch.url: \"${es_url:?}\"
"
mark_begin="# BEGIN: Generated by $PROGNAME for basic cluster settings"
mark_end="# -END-: Generated by $PROGNAME for basic cluster settings"
sh "$BASE_DIR/inject-to-file.sh" \
    -c "$content" \
    -f /etc/kibana/kibana.yml \
    -p end \
    -m "$mark_begin" \
    -n "$mark_end" \
    -x "$mark_begin" \
    -y "$mark_end"

# parameterize settings

for kv in "${settings[@]}"; do
    key="$(echo "$kv" | cut -d= -f1)"
    content="$(echo "$kv" | sed 's/=/: /')"
    mark_begin="# BEGIN: Generated by $PROGNAME for $key"
    mark_end="# -END-: Generated by $PROGNAME for $key"
    sh "$BASE_DIR/inject-to-file.sh" \
       -c "$content" \
       -f /etc/kibana/kibana.yml \
       -p end \
       -m "$mark_begin" \
       -n "$mark_end" \
       -x "$mark_begin" \
       -y "$mark_end"
done

service kibana start
chkconfig --add kibana

exit
