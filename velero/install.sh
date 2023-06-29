#!/bin/bash

velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./minio_secret.yaml \
    --use-volume-snapshots=false \
    --plugins velero/velero-plugin-for-aws:v1.0.0 \
    --backup-location-config \
region=minio,s3ForcePathStyle="true",s3Url=http://minio-api.devops.internal.tanzu:80,publicUrl=http://minio-ui.devops.internal.tanzu:80
