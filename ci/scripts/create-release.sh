#!/bin/bash

set -euo pipefail
set -v

# A release candidate consists of config and certs for haproxy.
# We build the RC from our inputs, validate it, and if successful promote it
# to a release

mkdir release-candidate

cp -rf ops.git/frontend/config-bucket/* release-candidate

mkdir release-candidate/certs
tar xvfz certs.s3/current-certificates.tgz -C release-candidate/certs

# Now the release-candidate dir contains an extracted haproxy config we can
# validate

# the haproxy config expects a vcap user and group, so create one
useradd vcap

export HAPROXY_FILES_DIR=release-candidate/
export HAPROXY_CERTS_DIR=release-candidate/certs/

# get haproxy to check the config file
haproxy -c -V -f release-candidate/configs/main.cfg

# Create a release tarball
pushd release-candidate
  tar cvfz ../release/release.tgz *
popd

#debug print contents of release
tar -tvf release/release.tgz
