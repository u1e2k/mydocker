#! /bin/bash

# docker build . --file Dockerfile --tag my-image-name:$(date +%s)
docker build . --file Dockerfile --tag my-image-name:$(date +%s) --tag my-image-name:latest
