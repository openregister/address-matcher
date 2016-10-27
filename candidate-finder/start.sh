#!/bin/sh
/etc/init.d/nginx start
/usr/bin/sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch &
echo "Waiting 20s for elasticsearch to start -- FIXME"
echo "Importing addresses"
echo $PATH
ln -s /usr/bin/nodejs /usr/bin/node
sleep 20
zcat /root/flattened_es.json.gz | elasticdump --input=$ --output=http://localhost:9200/flattened
echo "Done"
