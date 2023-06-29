#!/bin/bash

kubectl create secret docker-registry harbor-kpack-cred \
  --docker-server=registry.altair-lab.com \
  --docker-username=admin \
  --docker-password=Megazone00!

