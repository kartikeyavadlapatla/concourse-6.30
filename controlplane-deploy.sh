#!/bin/bash
set -eux
##Install CLIs
  ##Install jq editor
sudo apt install jq -y
  ##Install OM cli
sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
sudo apt-get update
sudo apt-get install om -y
  ##Install yq editor
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update
sudo apt install yq -y

### Install FLY Cli ####
wget https://github.com/concourse/concourse/releases/download/v6.3.0/fly-6.3.0-linux-amd64.tgz
tar -xvf fly-6.3.0-linux-amd64.tgz
sudo mv fly /usr/local/bin/fly
sudo chmod 777 /usr/local/bin/fly

PATHLOCAL=/home/ubuntu/TestScript
echo $PATHLOCAL
####Take input variables
echo "Provide GIT Branch"
read -p 'Git Branch:' gitbranch
echo "Provide opsman creds"
read -p 'OpsMan User:' omadmin               
read -p 'OpsMan Pwd:'  ompass                
read -p 'OpsMan Decrypt Pwd:' omdecrypt      
read -p 'OpsMan Target:' omtarget
read -p 'Controlplane Environment:' foundation
read -p 'PCF Environment:' pcffoundation
echo "Provide 6 static IPs for Concourse Deployment"
echo "this IP will be used for WEB in AZ1"
read -p 'Static IP 1:' staticip1
echo "this IP will be used for DB in AZ1"
read -p 'Static IP 2:' staticip2
echo "This IPs will be used for worker nodes in 3 AZs"
echo "This IPs will be used for worker nodes in AZ1"
read -p 'Static IP 3:' staticip3
read -p 'Static IP 4:' staticip4
echo "This IP will be used for worker nodes in AZ2"
read -p 'Static IP 5:' staticip5
echo "This IP will be used for worker nodes in AZ3"
read -p 'Static IP 6:' staticip6
echo "Provide Pivnet Token"
read -p 'Pivnet Token:' token
echo "Provide IAM Instance profile"
read -p 'IAM Instance profile:' iaminstprofile
echo "Control Plane director SSH Key and S3 Bucket Access Key for Sandbox and Prod"
read -p 'Control Plane Director S3 Bucket Name:' directors3name
read -p 'Control Plane Bosh AZ1 Subnet IDs:' az1subnet
read -p 'Control Plane Bosh AZ2 Subnet IDs:' az2subnet
read -p 'Control Plane Bosh AZ3 Subnet IDs:' az3subnet
read -p 'Control Plane Bosh VMs Security Group:' sgname
read -p 'Control Plane ssh Key name:' sshkeyname
read -p 'Control Plane director S3 Bucket Access Key:' directoraccesskey
read -p 'Control Plane director S3 Bucket Secret Key:' directorsecretkey
read -p 'Control Plane ssh key:' sshkey
read -p 'Control Plane KMS key:' kmskey
gitbranch=
omadmin=
ompass=
omdecrypt=
omtarget=localhost
foundation=
sshkeyname=
sgname=
az1subnet=
az2subnet=
az3subnet=
pcffoundation=sandbox
directors3name=
staticip1=
staticip2=
staticip3=
staticip4=
staticip5=
staticip6=
token=
iaminstprofile=
directoraccesskey=
directorsecretkey=
##sshkey=$(cat KEYCP.key)
##SSHKEY=$(echo $sshkey)
sshkey=KEYCP.key
kmskey==
CONCOURSE_PATH=pcf-controlplane/control-plane/concourse-6.30
### Clone Git Repo
rm -Rf dal-pcf-controlplane
if [ -z ${gitbranch} ]; then
  git clone https://git.com//pcf-controlplane
else
  git clone -b ${gitbranch} https://git.com//pcf-controlplane
fi

### Install om cli
sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
sudo apt-get update
sudo apt-get install om -y

### Configure OpsMan Auth

#om configure-authentication --username ${omadmin} \
#          --password ${ompass} \
#          --decryption-passphrase ${omdecrypt} \
#          --target ${omtarget}

##To check login

##Create Director Config YAML###

cat > Director-config.yaml <<EOL
---
az-configuration: ((az-configuration))
iaas-configurations:
- iam_instance_profile: ${iaminstprofile}
  encrypted: true
  key_pair_name: ${sshkeyname}
  name: default
  region: ((default-region))
  security_group: ${sgname}
  ssh_private_key: |
  kms_key_arn: ${kmskey}
network-assignment:
  network:
    name: ((singleton-network-name))
  other_availability_zones: []
  singleton_availability_zone:
    name: ((singleton-az))
networks-configuration:
  icmp_checks_enabled: false
  networks:
  - name: ((pcf-infra-network))
    subnets:
    - iaas_identifier: ${az1subnet}
      cidr: ((pcf-infra-1-subnet-cidr))
      dns: ((dns))
      gateway: ((pcf-infra-1-subnet-gateway))
      reserved_ip_ranges: ((pcf-infra-1-reserved-ips))
      availability_zone_names:
      - ((az1))
    - iaas_identifier: ${az2subnet}
      cidr: ((pcf-infra-2-subnet-cidr))
      dns: ((dns))
      gateway: ((pcf-infra-2-subnet-gateway))
      reserved_ip_ranges: ((pcf-infra-2-reserved-ips))
      availability_zone_names:
      - ((az2))
    - iaas_identifier: ${az3subnet}
      cidr: ((pcf-infra-3-subnet-cidr))
      dns: ((dns))
      gateway: ((pcf-infra-3-subnet-gateway))
      reserved_ip_ranges: ((pcf-infra-3-reserved-ips))
      availability_zone_names:
      - ((az3))
properties-configuration:
  director_configuration:
    blobstore_type: s3
    bosh_recreate_on_next_deploy: false
    bosh_recreate_persistent_disks_on_next_deploy: false
    database_type: internal
    director_worker_count: 5
    encryption:
      keys: []
      providers: []
    hm_emailer_options:
      enabled: false
    hm_pager_duty_options:
      enabled: false
    identification_tags: {}
    job_configuration_on_tmpfs: false
    keep_unreachable_vms: false
    ntp_servers_string: ((ntp-servers))
    post_deploy_enabled: false
    resurrector_enabled: true
    retry_bosh_deploys: false
    s3_blobstore_options:
      bucket_name: ${directors3name}
      endpoint: ((director-s3-endpoint))
      region: ((director-s3-region))
      access_key: ${directoraccesskey}
      secret_key: ${directorsecretkey}
      signature_version: "4"
      backup_strategy: "use_versioned_bucket"
    skip_director_drain: false
  dns_configuration:
    excluded_recursors: []
    handlers: []
  security_configuration:
    generate_vm_passwords: true
    opsmanager_root_ca_trusted_certs: true
  syslog_configuration:
    enabled: false
resource-configuration:
  compilation:
    additional_vm_extensions: ${iaminstprofile}
    instance_type:
      id: ((compilation-vm-type))
    instances: ((compilation-vm-count))
  director:
    additional_vm_extensions: ${iaminstprofile}
    instance_type:
      id: ((director-vm-type))
    instances: ((director-vm-count))
    persistent_disk:
      size_mb: ((director-persistant-disk))
EOL

head -10 Director-config.yaml > Director-config-add-key.yaml
sed 's/^/    /' ${sshkey} >> Director-config-add-key.yaml
tail -n +11 Director-config.yaml >> Director-config-add-key.yaml


om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} staged-products

##To add Instance Profile

if [ ${foundation} == prod ] && [ ${pcffoundation} == prod ]
then
  #### VM Instance profile #########
  om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} \
      curl --path /api/v0/staged/vm_extensions/instance-role -x PUT -d \
         '{"name": "instance-role", "cloud_properties": { "iam_instance_profile": "${iaminstprofile}"}}'

  #### Om Configure Director #######
  om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} \
      configure-director --config Director-config-add-key.yaml --vars-file dal-pcf-controlplane/OpsMan-config/bosh-director-var-prod.yml

  ### Apply Changes to the director
  om -k -u ${omadmin} \
        -p ${ompass} \
        -t ${omtarget} \
         apply-changes

elif [ ${foundation} == non-prod ] && [ ${pcffoundation} == sandbox ]
then

  #### VM Instance profile #########
  om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} \
      curl --path /api/v0/staged/vm_extensions/instance-role -x PUT -d \
         '{"name": "instance-role", "cloud_properties": { "iam_instance_profile": "pcf_devsecops-nonprod-instance-role"}}'

  #### Om Configure Director #######
  om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} \
      configure-director --config Director-config-add-key.yaml --vars-file dal-pcf-controlplane/OpsMan-config/bosh-director-var-non-prod.yml


  ### Apply Changesi to the director
  om -k -u ${omadmin} \
        -p ${ompass} \
        -t ${omtarget} \
         apply-changes

elif [ ${foundation} == non-prod ] && [ ${pcffoundation} == non-prod ]
then
  echo "OpsMan ControlPlane already setup for Sandbox" 
else
  echo "non right foundation specified"
fi

### Get BOSH Creds
##### getting values for Bosh login
om -k -u ${omadmin} \
      -p ${ompass} \
      -t ${omtarget} \
      curl -p /api/v0/deployed/director/credentials/bosh_commandline_credentials > bosh-client-creds

####Login to Bosh
BOSH_EXPORTS=$(jq -r .credential bosh-client-creds)
echo $BOSH_EXPORTS
export $BOSH_EXPORTS
bosh vms 


### Setup Bosh JumpBox ####
if [ ${foundation} == prod ] && [ ${pcffoundation} == prod ]
then

  bosh upload-release --sha1 7ef05f6f3ebc03f59ad8131851dbd1abd1ab3663 \
    https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=22.1.0

  bosh -d jumpbox deploy \
    -o dal-pcf-controlplane/jumpbox-boshrelease/manifests/jumpbox_optional_prod.yml  \
    dal-pcf-controlplane/jumpbox-boshrelease/manifests/jumpbox.yml

elif [ ${foundation} == non-prod ] && [ ${pcffoundation} == sandbox ]
then

  bosh upload-release --sha1 7ef05f6f3ebc03f59ad8131851dbd1abd1ab3663 \
    https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=22.1.0

  bosh -d jumpbox deploy \
    -o dal-pcf-controlplane/jumpbox-boshrelease/manifests/jumpbox_optional_non_prod.yml  \
    dal-pcf-controlplane/jumpbox-boshrelease/manifests/jumpbox.yml
else
  echo "non right foundation specified"
fi


###Setup Concourse
bosh cloud-config > config-cp-old.yml 
bosh cloud-config > config-cp-new.yml

cat > StaticIPs.yml <<EOL
- command: update
  path: networks.[0].name
  value:
    concourse-static-network
- command: update
  path: networks.*.subnets.[0].static[+]
  value:
    ${staticip1}
- command: update
  path: networks.*.subnets.[0].static[+]
  value:
    ${staticip2}
- command: update
  path: networks.*.subnets.[0].static[+]
  value:
    ${staticip3}
- command: update
  path: networks.*.subnets.[0].static[+]
  value:
    ${staticip4}
- command: update
  path: networks.*.subnets.[1].static[+]
  value:
    ${staticip5}
- command: update
  path: networks.*.subnets.[2].static[+]
  value:
    ${staticip6}
EOL

echo "networks:" > concourse-cloud-config.yml
yq r config-cp-old.yml networks >> concourse-cloud-config.yml
yq w -s StaticIPs.yml concourse-cloud-config.yml > concourse-cloud-config-static-ips.yml
bosh update-config --name concourse --type cloud concourse-cloud-config-static-ips.yml -n
bosh configs
bosh cloud-config
bosh config --name concourse --type cloud

###Download concourse rel
bosh upload-release --sha1 6a75118c6d295476f1619a7befa0d4ff0dc58602 \
  https://bosh.io/d/github.com/concourse/concourse-bosh-release?v=6.3.0

wget --post-data="" --header="Authorization: Token ${token}" \
https://network.pivotal.io/api/v2/products/stemcells-ubuntu-xenial/releases/673636/product_files/714242/download -O "light-bosh-stemcell-250.200-aws-xen-hvm-ubuntu-xenial-go_agent.tgz"

bosh upload-stemcell light-bosh-stemcell-250.200-aws-xen-hvm-ubuntu-xenial-go_agent.tgz

export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
credhub login
credhub generate -t user -z admin -n /p-bosh/concourse/local_user
credhub get -n /p-bosh/concourse/local_user

cat > variables_new.yml <<EOL
azs:
  - us-east-1a
  - us-east-1b
  - us-east-1c
role:
  - instance-role
deployment_name: concourse
network_name: concourse-static-network
external_host: ${staticip1}      ##for static setup can static web ip or concourse lb ip
external_url: https://${staticip1} ##for static setup can static web ip or concourse lb ip
web_ip: ${staticip1}              ## static web ip
web_vm_type: m5.xlarge
web_instances: 1
db_vm_type: m5.large
db_persistent_disk_type: 102400
db_ip: ${staticip2}
worker_vm_type: m5.xlarge
worker_instances: 4
worker_ip:
  - ${staticip3}
  - ${staticip4}
  - ${staticip5}
  - ${staticip6}
EOL

cp variables_new.yml $CONCOURSE_PATH/variables.yml
cd $CONCOURSE_PATH && ./deploy-concourse.sh && cd $PATHLOCAL
cd /home/ubuntu/TestScript
export $BOSH_EXPORTS
export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
credhub login

export CONCOURSE_ADMIN="$(credhub get -n /p-bosh/concourse/local_user -k password)"
export CONCOURSE_CREDHUB_SECRET="$(credhub get -n /p-bosh/concourse/credhub_admin_secret -q)"
export CONCOURSE_CA_CERT="$(credhub get -n /p-bosh/concourse/atc_tls -k ca)"
unset CREDHUB_SECRET CREDHUB_CLIENT CREDHUB_SERVER CREDHUB_PROXY CREDHUB_CA_CERT

credhub login \
  --server "https://${staticip1}:8844" \
  --client-name=credhub_admin \
  --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
  --ca-cert "${CONCOURSE_CA_CERT}"

echo ${CONCOURSE_CA_CERT} | sed 's/----- /-----\n/g' | sed 's/ -----/\n-----/g' | sed '2s/ /\n/g'  > CONCOURSE_CA_CERT.key


if [ ${pcffoundation} == non-prod ]
then
  cd /home/ubuntu/TestScript
  export $BOSH_EXPORTS
  export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
  credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
  credhub login

  export CONCOURSE_CREDHUB_SECRET="$(credhub get -n /p-bosh/concourse/credhub_admin_secret -q)"
  export CONCOURSE_CA_CERT="$(credhub get -n /p-bosh/concourse/atc_tls -k ca)"
  unset CREDHUB_SECRET CREDHUB_CLIENT CREDHUB_SERVER CREDHUB_PROXY CREDHUB_CA_CERT
  credhub login \
    --server "https://${staticip1}:8844" \
    --client-name=credhub_admin \
    --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
    --ca-cert "${CONCOURSE_CA_CERT}"
  
  EC2_CREATE_ACCESS_KEY=
  EC2_CREATE_SECRET_KEY=
  ACCESS_KEY=
  SECRET_KEY=
  NONPROD_AWS_BROKER_ACC_KEY=
  NONPROD_AWS_BROKER_SEC_KEY=
  NONPROD_CREDHUB_ENCRYPT_KEY=
  NONPROD_OPSMAN_DCRYPT_PASS=
  NONPROD_OPSMAN_KEY=
  NONPROD_BOSH_KMS_KEY=
  credhub f

  credhub set -n /concourse/non-prod/access-key-id -t value -v ${ACCESS_KEY}
  credhub set -n /concourse/non-prod/credhub_ca_cert -t certificate -c CONCOURSE_CA_CERT.key
  credhub set -n /concourse/non-prod/director-trusted-certs -t certificate -c DIRECTOR-TRUST-CERT.CA-NONPRD
  credhub set -n /concourse/non-prod/aws-service-broker-access-key -t value -v ${NONPROD_AWS_BROKER_ACC_KEY}
  credhub set -n /concourse/non-prod/aws-service-broker-secret-key -t value -v ${NONPROD_AWS_BROKER_SEC_KEY}
  credhub set -n /concourse/non-prod/non-prod-access-key-id -t value -v ${ACCESS_KEY}
  credhub set -n /concourse/non-prod/secret-access-key -t value -v ${SECRET_KEY}
  credhub set -n /concourse/non-prod/uaa-saml-cert -t certificate -c NETWORK-CERT.CA-NONPRD -p NETWORK-CERT.KEY-NONPRD
  credhub set -n /concourse/non-prod/network-poe-cert -t certificate -c NETWORK-CERT.CA-NONPRD -p NETWORK-CERT.KEY-NONPRD
  credhub set -n /concourse/non-prod/credhub_server -t value -v https://${staticip1}:8844
  credhub set -n /concourse/non-prod/credhub-encrypt-key-secret -t value -v ${NONPROD_CREDHUB_ENCRYPT_KEY}
  credhub set -n /concourse/non-prod/opsman-decryption-passphrase -t value -v ${NONPROD_OPSMAN_DCRYPT_PASS}
  credhub set -n /concourse/non-prod/pivnet_token -t value -v ${token}
  credhub set -n /concourse/non-prod/bosh-ssh-key -t ssh -p NONPROD-SSH-PRIVATE.KEY
  credhub set -n /concourse/non-prod/opsman-private-key -t ssh -p NONPROD-SSH-PRIVATE.KEY
  credhub set -n /concourse/non-prod/credhub_secret -t value -v ${CONCOURSE_CREDHUB_SECRET}
  credhub set -n /concourse/non-prod/git_keys -t ssh -p GIT_KEY_PRIVATE.KEY -u GIT_KEY_PUBLIC.KEY
  credhub set -n /concourse/non-prod/opsman-username -t value -v nonprod-admin
  credhub set -n /concourse/non-prod/opsman-password -t value -v ${NONPROD_OPSMAN_KEY}
  credhub set -n /concourse/non-prod/bosh-kms-key -t value -v ${NONPROD_BOSH_KMS_KEY}
  credhub set -n /concourse/non-prod/non-prod-secret-access-key -t value -v ${SECRET_KEY}
  credhub set -n /concourse/non-prod/s3-storage-secret-access-key -t value -v ${SECRET_KEY}
  credhub set -n /concourse/non-prod/s3-storage-access-key-id -t value -v ${ACCESS_KEY}
  credhub set -n /concourse/non-prod/ec2-create-access-key -t value -v ${EC2_CREATE_ACCESS_KEY}
  credhub set -n /concourse/non-prod/ec2-create-secret-key -t value -v ${EC2_CREATE_SECRET_KEY}
elif [ ${pcffoundation} == sandbox ]
then
  cd /home/ubuntu/TestScript
  export $BOSH_EXPORTS
  export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
  credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
  credhub login

  export CONCOURSE_CREDHUB_SECRET="$(credhub get -n /p-bosh/concourse/credhub_admin_secret -q)"
  export CONCOURSE_CA_CERT="$(credhub get -n /p-bosh/concourse/atc_tls -k ca)"
  unset CREDHUB_SECRET CREDHUB_CLIENT CREDHUB_SERVER CREDHUB_PROXY CREDHUB_CA_CERT
  credhub login \
    --server "https://${staticip1}:8844" \
    --client-name=credhub_admin \
    --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
    --ca-cert "${CONCOURSE_CA_CERT}"
  
  EC2_CREATE_ACCESS_KEY=
  EC2_CREATE_SECRET_KEY=
  STORAGE_ACCESS_KEY=
  STORAGE_SECRET_KEY=
  ACCESS_KEY=
  SECRET_KEY=
  SBX_AWS_BROKER_ACC_KEY=
  SBX_AWS_BROKER_SEC_KEY=
  SBX_CREDHUB_ENCRYPT_KEY=
  SBX_OPSMAN_DCRYPT_PASS=
  SBX_OPSMAN_KEY=
  SBX_BOSH_KMS_KEY=


  credhub f
  credhub set -n /concourse/sandbox/credhub_ca_cert -t certificate -c CONCOURSE_CA_CERT.key
  credhub set -n /concourse/sandbox/director-trusted-certs -t certificate -c DIRECTOR-TRUST-CERT.CA-SBX
  credhub set -n /concourse/sandbox/aws-service-broker-access-key -t value -v ${SBX_AWS_BROKER_ACC_KEY}
  credhub set -n /concourse/sandbox/aws-service-broker-secret-key -t value -v ${SBX_AWS_BROKER_SEC_KEY}
  credhub set -n /concourse/sandbox/sandbox-access-key-id -t value -v ${ACCESS_KEY}
  credhub set -n /concourse/sandbox/access-key-id -t value -v ${ACCESS_KEY}
  credhub set -n /concourse/sandbox/secret-access-key -t value -v ${SECRET_KEY}
  credhub set -n /concourse/sandbox/uaa-saml-cert -t certificate -c NETWORK-CERT.CA-SBX -p NETWORK-CERT.KEY-SBX
  credhub set -n /concourse/sandbox/network-poe-cert -t certificate -c NETWORK-CERT.CA-SBX -p NETWORK-CERT.KEY-SBX
  credhub set -n /concourse/sandbox/credhub_server -t value -v https://${staticip1}:8844
  credhub set -n /concourse/sandbox/credhub-encrypt-key-secret -t value -v ${SBX_CREDHUB_ENCRYPT_KEY}
  credhub set -n /concourse/sandbox/opsman-decryption-passphrase -t value -v ${SBX_OPSMAN_DCRYPT_PASS}
  credhub set -n /concourse/sandbox/pivnet_token -t value -v ${token}
  credhub set -n /concourse/sandbox/bosh-ssh-key -t ssh -p SBX-SSH-PRIVATE.KEY
  credhub set -n /concourse/sandbox/opsman-private-key -t ssh -p SBX-SSH-PRIVATE.KEY
  credhub set -n /concourse/sandbox/credhub_secret -t value -v ${CONCOURSE_CREDHUB_SECRET}
  credhub set -n /concourse/sandbox/git_keys -t ssh -p GIT_KEY_PRIVATE.KEY -u GIT_KEY_PUBLIC.KEY
  credhub set -n /concourse/sandbox/opsman-username -t value -v sandbox-admin
  credhub set -n /concourse/sandbox/opsman-password -t value -v ${SBX_OPSMAN_KEY}
  credhub set -n /concourse/sandbox/bosh-kms-key -t value -v ${SBX_BOSH_KMS_KEY}
  credhub set -n /concourse/sandbox/sandbox-secret-access-key -t value -v ${SECRET_KEY}
  credhub set -n /concourse/sandbox/s3-storage-secret-access-key -t value -v ${STORAGE_SECRET_KEY}
  credhub set -n /concourse/sandbox/s3-storage-access-key-id -t value -v ${STORAGE_ACCESS_KEY}
  credhub set -n /concourse/sandbox/ec2-create-access-key -t value -v ${EC2_CREATE_ACCESS_KEY}
  credhub set -n /concourse/sandbox/ec2-create-secret-key -t value -v ${EC2_CREATE_SECRET_KEY}

else
  echo "non foundation specified"
fi

### Import Cred values to credhub ###

export $BOSH_EXPORTS
export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
credhub login

export CONCOURSE_ADMIN="$(credhub get -n /p-bosh/concourse/local_user -k password)"
export CONCOURSE_CREDHUB_SECRET="$(credhub get -n /p-bosh/concourse/credhub_admin_secret -q)"
export CONCOURSE_CA_CERT="$(credhub get -n /p-bosh/concourse/atc_tls -k ca)"
unset CREDHUB_SECRET CREDHUB_CLIENT CREDHUB_SERVER CREDHUB_PROXY CREDHUB_CA_CERT

credhub login \
  --server "https://${staticip1}:8844" \
  --client-name=credhub_admin \
  --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
  --ca-cert "${CONCOURSE_CA_CERT}"

### Install PCP Pipelines
## Install PCF Pipelines
rm -Rf pcf-pipeline
rm -Rf pcf-templates
git clone https://git.com//pcf-pipeline.git
git clone https://git.com//pcf-templates.git

### Setup Fly pipelines

fly -t main login -c https://${staticip1}:443 --ca-cert <(echo "${CONCOURSE_CA_CERT}") -u admin -p ${CONCOURSE_ADMIN}

if [ ${pcffoundation} == non-prod ]
then
  fly -t main set-team --team-name non-prod --local-user admin --non-interactive
  fly -t non-prod login --team-name non-prod --concourse-url https://${staticip1}:443 --ca-cert <(echo "${CONCOURSE_CA_CERT}") \
       -u admin -p ${CONCOURSE_ADMIN}
  cd dal-pcf-pipeline/backup-restore/pipelines && fly -t non-prod set-pipeline -p backup-pcf -c pipeline-bbr.yml -l paramas.yml --non-interactive
  cd /home/ubuntu/TestScript
  cd dal-pcf-pipeline/install-pcf/pipelines/install && fly -t non-prod set-pipeline -p install-pcf -c pipeline-.yml -l params-non-prod.yml \
      --non-interactive
  cd /home/ubuntu/TestScript
  cd dal-pcf-pipeline/install-pcf/pipelines/delete && fly -t non-prod set-pipeline -p delete-pcf -c pipeline.yml -l ../install/params-non-prod.yml \
      --non-interactive
  cd /home/ubuntu/TestScript
elif [ ${pcffoundation} == sandbox ]
then
  fly -t main set-team --team-name sandbox --local-user admin --non-interactive
  fly -t sandbox login --team-name sandbox --concourse-url https://${staticip1}:443 --ca-cert <(echo "${CONCOURSE_CA_CERT}") -u admin -p ${CONCOURSE_ADMIN}
  cd dal-pcf-pipeline/upload-to-s3 && fly -t sandbox set-pipeline -p upload-to-s3 -c pipeline-.yml -l params.yml --non-interactive
  cd /home/ubuntu/TestScript
  cd dal-pcf-pipeline/backup-restore/pipelines && fly -t sandbox set-pipeline -p backup-pcf -c pipeline-bbr.yml -l paramas.yml \
       --non-interactive
  cd /home/ubuntu/TestScript
  cd dal-pcf-pipeline/install-pcf/pipelines/install && fly -t sandbox set-pipeline -p install-pcf -c pipeline-.yml -l params-sandbox.yml \
       --non-interactive
  cd /home/ubuntu/TestScript
  cd dal-pcf-pipeline/install-pcf/pipelines/delete && fly -t sandbox set-pipeline -p delete-pcf -c pipeline.yml -l ../install/params-sandbox.yml \
       --non-interactive
  cd /home/ubuntu/TestScript
else
  echo "No Environment Provided"
fi
