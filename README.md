# concourse-6.30
1.Update Cloud-Config 

2.Update static ips and variables 

3.Run below commands

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
