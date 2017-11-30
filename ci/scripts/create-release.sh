#!/bin/bash

set -euo pipefail
set -v
shopt -s nullglob

# A release candidate consists of config and certs for haproxy.
# We build the RC from our inputs, validate it, and if successful promote it
# to a release

mkdir release-candidate

cp -rf ops.git/frontend/config-bucket/* release-candidate

# This directory is managed by the cert manager, but it might already exist in
# the repo for testing purposes
mkdir -p release-candidate/certs
rm -rf release-candidate/certs/*

tar xvfz certs.s3/current-certificates.tgz -C release-candidate/certs

# Now the release-candidate dir contains an extracted haproxy config we can
# validate

# the haproxy config expects a vcap user and group, so create one
useradd vcap

export HAPROXY_FILES_DIR=release-candidate/
declare -a ENV
# If the config relies on environment variables, it should provide sample values
# in this file for testing
if [[ -e release-candidate/test_vars ]]
then
  # Read variable assignments into an array called ENV
  # We whitelist variables starting with FE_, and the env command treats an
  # argument as a variable assignment if it contains an =
  readarray -t ENV < <(grep '^FE_.*=' release-candidate/test_vars)
fi

# get haproxy to check the config file (using the provided environment variables)
env "${ENV[@]}" haproxy -c -V -- release-candidate/configs/*.cfg release-candidate/haproxy.d/*.cfg

# Create a release tarball
pushd release-candidate
  tar cvfz ../release/release.tgz *
popd

#debug print contents of release
tar -tvf release/release.tgz
