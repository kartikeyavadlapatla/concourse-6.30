#!/bin/bash
set -eux
echo "creating concourse deployment"
CONCOURSE_PATH=concourse-bosh-deployment-6.3.0
bosh deploy -d concourse \
	$CONCOURSE_PATH/cluster/concourse.yml \
	-l $CONCOURSE_PATH/versions.yml \
	-l variables.yml \
	-o $CONCOURSE_PATH/cluster/operations/basic-auth.yml \
	-o $CONCOURSE_PATH/cluster/operations/tls-vars.yml \
	-o $CONCOURSE_PATH/cluster/operations/uaa.yml \
	-o $CONCOURSE_PATH/cluster/operations/backup-atc-colocated-web.yml \
	-o $CONCOURSE_PATH/cluster/operations/secure-internal-postgres.yml \
	-o $CONCOURSE_PATH/cluster/operations/secure-internal-postgres-bbr.yml \
	-o $CONCOURSE_PATH/cluster/operations/static-web.yml \
        -o operations/static-db.yml \
        -o operations/static-worker.yml \
	-o $CONCOURSE_PATH/cluster/operations/scale.yml \
	-o $CONCOURSE_PATH/cluster/operations/credhub-colocated.yml \
	-o operations/tls-530.yml \
        -o operations/add-role.yml \
	-o $CONCOURSE_PATH/cluster/operations/debug-concourse.yml \
	-o $CONCOURSE_PATH/cluster/operations/privileged-https.yml \
	-o $CONCOURSE_PATH/cluster/operations/secure-internal-postgres-uaa.yml 
