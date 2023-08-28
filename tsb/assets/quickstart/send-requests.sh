#!/bin/sh

while true; do
    result=$(curl -m 5 -k -s -o /dev/null -I -w "%{http_code}" "https://bookinfo.tetrate.com/productpage" --connect-to bookinfo.tetrate.com:443:$GATEWAY_IP)
    echo date: $(date),  status code: "$result"
    sleep 1
done
