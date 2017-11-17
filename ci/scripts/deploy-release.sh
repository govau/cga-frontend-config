#!/bin/bash

set -euo pipefail
set -v

# There is a script on each router which will load the latest release
# from the s3 bucket: https://github.com/govau/acme-proxy-boshrelease/blob/master/jobs/haproxy/templates/fetch_extra_files.erb
# To deploy the latest release we ssh to each gorouter and run this script.

: "${ENV_NAME:?Need to set ENV_NAME e.g. d}"
: "${JUMPBOX_SSH_KEY:?Need to set JUMPBOX_SSH_KEY}"

JUMPBOX=bosh-jumpbox.${ENV_NAME}.cld.gov.au
PATH_TO_KEY=${PWD}/jumpbox.pem

# Create the private key for the jumpbox
echo "${JUMPBOX_SSH_KEY}">${PATH_TO_KEY}
chmod 600 ${PATH_TO_KEY}

# preload the jumpbox host key
mkdir ~/.ssh
KNOWN_HOSTS=~/.ssh/known_hosts
ssh-keyscan -H ${JUMPBOX} > ${KNOWN_HOSTS}

# Create a script to run on the environment's jumpbox, which will
# trigger each router instance to reload it's configuration to use
# the current release.
cat >> frontend-config-deploy.sh <<'EOF'
#!/bin/bash

set -euo pipefail
set -v

# login to bosh director
source ~/bosh-bootstrap/bin/admin-login.sh

# The number of router instances in this environment's cf deployment
bosh manifest -d cf > /tmp/cf-deployment-manifest.yml
ROUTER_INSTANCE_COUNT=$(bosh int /tmp/cf-deployment-manifest.yml --path /instance_groups/name=router/instances)

for INSTANCE in `seq 0 $(expr $ROUTER_INSTANCE_COUNT - 1)`;
do
  echo "Updating router/$INSTANCE"
  bosh ssh -d cf router/$INSTANCE \
    sudo /var/vcap/jobs/haproxy/bin/update release.tgz
  # todo do we need our own error checking here?
done

EOF

chmod a+x frontend-config-deploy.sh

scp -i ${PATH_TO_KEY} frontend-config-deploy.sh ec2-user@$JUMPBOX:.

ssh -i ${PATH_TO_KEY} ec2-user@$JUMPBOX ./frontend-config-deploy.sh
