# cloud.gov.au frontend config

Generate, test, and deliver configuration for [the cloud.gov.au reverse proxy servers](https://github.com/govau/frontend-boshrelease).

This is currently a concourse pipeline that:
- generates release candidate of haproxy config and certificates
- test the release candidate
- promote the release candidate to a release and push to s3
- deploy the release to each server
