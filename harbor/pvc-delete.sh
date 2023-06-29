#!/bin/bash

kubectl delete pvc -n harbor $(kubectl get pvc -n harbor  | awk '{print $1}' | sed -n "2, \$p")
