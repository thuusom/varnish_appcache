#!/bin/bash
docker stop varnish-appcache
docker container rm varnish-appcache

docker run -d -v $(pwd)/default.vcl:/etc/varnish/default.vcl:ro -p 9090:80 --name varnish-appcache varnish:latest
