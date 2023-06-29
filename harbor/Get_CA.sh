#!/bin/bash


kubectl get secret -n harbor harbor-ca-key-pair -o jsonpath={".data.ca\.crt"} | base64 -d > INTERNAL_CA.crt

cat INTERNAL_CA.crt > ~/.config/tanzu/tkg/providers/infrastructure-aws/ytt/private_registry_ca.crt
