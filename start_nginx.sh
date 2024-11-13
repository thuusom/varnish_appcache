#!/bin/bash

docker stop nginx-cryptoguard
docker container rm nginx-cryptoguard
docker run --name nginx-cryptoguard \
  -p 9080:80 \
  -v $(pwd)/html:/usr/share/nginx/html:ro \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -d nginx
