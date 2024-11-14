#!/bin/bash

docker stop nginx-server
docker container rm nginx-server
docker run --name nginx-server \
  -p 9080:80 \
  -v $(pwd)/html:/usr/share/nginx/html:ro \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -d nginx
