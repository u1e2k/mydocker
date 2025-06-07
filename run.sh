#! /bin/bash

docker build . --file Dockerfile --tag my-image-name:$(date +%s)