#!/bin/bash

set -e
set -x

TARGET=${TARGET:-local}
PIPELINE=frontend-config

fly validate-pipeline --config pipeline.yml

fly --target ${TARGET} set-pipeline --config pipeline.yml --pipeline $PIPELINE -n -l credentials.yml

for resource in  ops.git this.git \
    certs-b.s3 release-b.s3 \
    certs-d.s3 release-d.s3 \
    certs-g.s3 release-g.s3 \
    certs-y.s3 release-y.s3; do
  fly -t ${TARGET} check-resource --resource $PIPELINE/$resource
done

fly -t ${TARGET} unpause-pipeline -p $PIPELINE
