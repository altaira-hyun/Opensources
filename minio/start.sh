#!/bin/bash

#helm install minio -n minio --create-namespace minio/minio-operator -f minio-values.yaml

kubectl -n minio get secret $(kubectl -n minio get serviceaccount console-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode 
