#!/bin/bash
#set -eux
###00 05 * * * cd /home/ubuntu/control-plane-backups && ./control_plane_backup.sh >> /home/ubuntu/control-plane-backups/control_plane_backup.log 2>&1

timestamp=$(/bin/date +%Y%m%d_%H%M)
backup_dir=control_plane_backups/${timestamp}
log_dir=logs
log_director=${log_dir}/log_director_${timestamp}.log
log_concourse=${log_dir}/log_concourse_${timestamp}.log
backups_tobe_retained="2"
director_backup_status=false
aws_s3_access_key=
aws_s3_secret_key=
aws_s3_region=us-east-1
aws_s3_bucket=
BOSH_CLIENT_SECRET=
BBR_SECRET=
DIRECTOR_IP=
CREDHUB_DB=
OM_TARGET=
OM_USER=
OM_PWD=
OM_SKIP_SSL_VALIDATION=true
mkdir -p ${log_dir} ${backup_dir}

echo "BACKUPS ARE TAKEN @ $timestamp"

export AWS_ACCESS_KEY_ID=${aws_s3_access_key}
export AWS_SECRET_ACCESS_KEY=${aws_s3_secret_key}
export AWS_DEFAULT_REGION=${aws_s3_region}
export OM_TARGET=${OM_TARGET}
export OM_USERNAME=${OM_USER}
export OM_PASSWORD=${OM_PWD}
export OM_SKIP_SSL_VALIDATION=${OM_SKIP_SSL_VALIDATION}
##### Deleting Backups ##################

delete_backup()
{
        local backups_tobe_retained=$1
        echo "Backups to be retained: $backups_tobe_retained"
        total_backups=$( /bin/ls -ltr /home/ubuntu/control-plane-backups/control_plane_backups | /bin/grep -v total | /usr/bin/awk '{print $NF}' | /usr/bin/wc -l )
        echo "Total Backups: ${total_backups}"
        if [[ ${total_backups} > ${backups_tobe_retained} ]]; then
                backups_tobe_deleted=$((${total_backups}-${backups_tobe_retained}))
                echo "Backups to be Deleted: $backups_tobe_deleted"
                for old_backup in $( /bin/ls -ltr /home/ubuntu/control-plane-backups/control_plane_backups | /bin/grep -v total | /usr/bin/awk '{print $NF}' | /usr/bin/head -${backups_tobe_deleted})
                do
                        echo "$(/bin/date) removing /home/ubuntu/control-plane-backups/control_plane_backups/${old_backup}"
                        /bin/rm -Rf /home/ubuntu/control-plane-backups/control_plane_backups/${old_backup}
                done
        else
                echo "Avaialble backups and backups to be retained count is same, no cleanup needed"
        fi
}
##### Backing up OpsMan with OM Cli #####################

echo "Exporting OpsMan installation settings"

#om -e env export-installation --output-file ${backup_dir}/installation_${timestamp}a
om  export-installation --output-file ${backup_dir}/installation_${timestamp}

/usr/local/bin/aws s3 cp ${backup_dir}/installation_${timestamp} s3://${aws_s3_bucket}/installation_${timestamp}
/bin/chmod -R 777 ${backup_dir}/installation_${timestamp}
#########################################################
####### Backing up Control Plane director with BBR ######

echo "Backing up Control Plane director with BBR"

echo "Running Pre-Backup-Checks"

/usr/bin/bbr director --private-key-path \
        private_key.pem --username bbr --host ${DIRECTOR_IP} \
        --debug pre-backup-check > ${log_director}

/bin/grep -q "Director can be backed up." ${log_director}

if [[ $? != 0 ]];then
        echo "Err: Director not ready for backup, check logs ${log_director} for details"
        exit 1
fi

####### Director Backup #################################

echo "Taking Director Backup"

/usr/bin/bbr director --private-key-path private_key.pem \
        --username bbr --host ${DIRECTOR_IP} \
        --debug backup --artifact-path ${backup_dir} >> ${log_director} 2>&1
/bin/chmod -R 777 ${backup_dir}
if [[ $? != 0 ]]; then
        echo "Err: Director backup failed"
        echo "Removing backup ${backup_dir}"
        /bin/rm -Rf ${backup_dir}
        director_backup_status=false
else
        director_backup_status=true
        files=$(/bin/ls ${backup_dir}/${DIRECTOR_IP}*)
        IFS=$'\n'$'\r'
        PATH=$(/bin/ls ${backup_dir}/ | /bin/grep ${DIRECTOR_IP})
        for j in ${files}
        do
           /usr/local/bin/aws s3 cp ${backup_dir}/${DIRECTOR_IP}_*/${j} s3://${aws_s3_bucket}/${backup_dir}/${PATH}/${j}
        done
        /usr/local/bin/aws s3 cp ${log_dir}/log_director_${timestamp}.log s3://${aws_s3_bucket}/${log_director}
fi
echo "Director Backup log location"             @log_director:$log_director
echo "Director Backup location"                 @backup_dir:$backup_dir

######### Cleaing up director locks ######################

echo "Cleaning up Director locks"

/usr/bin/bbr director --private-key-path \
        private_key.pem --username bbr \
        --host ${DIRECTOR_IP} \
        --debug backup-cleanup >> ${log_director} 2>&1

echo "Director backup-clean-up log location     @log_director:${log_director}"
if [[ $director_backup_status == "false" ]]; then
        echo "Director backup failed !!"
        exit 1
fi

#########################################################
########## Concourse backup pre-deployment checks #######

export BOSH_CLIENT=ops_manager BOSH_CLIENT_SECRET=${BOSH_CLIENT_SECRET} BOSH_CA_CERT=~/root.cert BOSH_ENVIRONMENT=${DIRECTOR_IP}

#bosh -d concourse manifest > $backup_dir/deployed-manifest-$timestamp.yml

/usr/bin/bbr deployment --target ${DIRECTOR_IP} --deployment concourse \
        --username bbr_client --password ${BBR_SECRET} --ca-cert ~/root.cert --debug pre-backup-check > ${log_concourse} 2>&1

/bin/grep -q "Deployment 'concourse' can be backed up." ${log_concourse}

if [[ $? != 0 ]];then
        echo "Err: Concourse not ready for backup, check logs ${log_concourse} for details"
        echo "Removing backup ${backup_dir}"
        /bin/rm -Rf ${backup_dir}
        exit 1
fi

######### Concourse Backup ################################
echo "Taking concourse Backup"

/usr/bin/bbr deployment --target ${DIRECTOR_IP} --deployment concourse \
        --username bbr_client --password ${BBR_SECRET} --ca-cert ~/root.cert --debug backup --with-manifest \
        --artifact-path ${backup_dir} >> ${log_concourse} 2>&1
/bin/chmod -R 777 ${backup_dir}
if [[ $? != 0 ]];then
        echo "Err: Concourse backup failed, check logs ${log_concourse} for details"
        echo "Removing backup ${backup_dir}"
        /bin/rm -Rf ${backup_dir}
        exit 1
fi
#PATH=$(cd  find control_plane_backups/20200724_1427/ -name "10.0.1.21_*" -print)
files=$(/bin/ls ${backup_dir}/concourse*)
IFS=$'\n'$'\r'
PATH=$(/bin/ls ${backup_dir}/ | /bin/grep concourse)
for j in ${files}
do
  /usr/local/bin/aws s3 cp ${backup_dir}/concourse*/${j} s3://${aws_s3_bucket}/${backup_dir}/${PATH}/${j}
  #aws s3 cp ${backup_dir}/concourse_*/ s3://${aws_s3_bucket}/${backup_dir}/${PATH}/
done
/usr/local/bin/aws s3 cp ${log_dir}/log_concourse_${timestamp}.log s3://${aws_s3_bucket}/${log_concourse}
echo "concourse backup log location             @log_concourse:$log_concourse"
echo "concourse backup location                 @backup_dir:$backup_dir"

###### Cleaning up concourse locks ########################

/usr/bin/bbr deployment --target ${DIRECTOR_IP} --deployment concourse \
        --username bbr_client --password ${BBR_SECRET} --ca-cert ~/root.cert --debug backup-cleanup >> ${log_concourse} 2>&1

echo "concourse backup clean-up log location @log_concourse:$log_concourse"

##### Taking Concourse Credhub Backup #############################

export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
/usr/bin/credhub api -s $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
/usr/bin/credhub login


export CONCOURSE_CREDHUB_SECRET="$(/usr/bin/credhub get -n /p-bosh/concourse/credhub_admin_secret -q)"
export CONCOURSE_CA_CERT="$(/usr/bin/credhub get -n /p-bosh/concourse/atc_tls -k ca)"

unset CREDHUB_SECRET CREDHUB_CLIENT CREDHUB_SERVER CREDHUB_PROXY CREDHUB_CA_CERT

/usr/bin/credhub login \
  --server "https://${CREDHUB_DB}:8844" \
  --client-name=credhub_admin \
  --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
  --ca-cert "${CONCOURSE_CA_CERT}"

/usr/bin/credhub export -f ${backup_dir}/concourse-credhub_${timestamp}.file
/usr/local/bin/aws s3 cp ${backup_dir}/concourse-credhub_${timestamp}.file s3://${aws_s3_bucket}/${backup_dir}/concourse-credhub_${timestamp}.file

##### Deleting Old backups ###############################

echo "Deleting old backups"
delete_backup ${backups_tobe_retained}
echo "Backup scripts ended"
