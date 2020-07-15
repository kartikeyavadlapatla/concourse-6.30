# concourse-6.30
1.Update Cloud-Config 

2.Update static ips and variables 

3. Upload stemcell and release

   wget --post-data="" --header="Authorization: Token <>" https://network.pivotal.io/api/v2/products/p-concourse/releases/673536/product_files/714094/download -O "concourse-bosh-release-6.3.0.tgz"
   wget --post-data="" --header="Authorization: Token <>" https://network.pivotal.io/api/v2/products/stemcells-ubuntu-xenial/releases/673636/product_files/714242/download -O "light-bosh-stemcell-250.200-aws-xen-hvm-ubuntu-xenial-go_agent.tgz"

4. create local user
   export BOSH_CLIENT=ops_manager BOSH_CLIENT_SECRET=<> BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=<redacted>
   export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
   credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
   credhub login

   credhub generate -t user -z admin -n /p-bosh/concourse-sc/local_user

   export ADMIN_USERNAME=admin
   export ADMIN_PASSWORD=password

   credhub set \
   -n /p-bosh/concourse/local_user \
   -t user \
   -z admin \
   -w admin

5.Run below commands

bosh deploy -d concourse \
concourse-bosh-deployment-5.5.11/cluster/concourse.yml \
-l concourse-bosh-deployment-5.5.11/versions.yml \
-l variables_sc.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/basic-auth.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/tls-vars.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/uaa.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/backup-atc-colocated-web.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/secure-internal-postgres.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/secure-internal-postgres-bbr.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/static-web.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/scale.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/credhub-colocated.yml \
-o operations/tls-530.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/debug-concourse.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/privileged-https.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/secure-internal-postgres-uaa.yml \
-o concourse-bosh-deployment-5.5.11/cluster/operations/privileged-http.yml | Dont use this setting BCBS Security issue
