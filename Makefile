export AWS_PROFILE=kubeground-kops
export NAME=thekubeground.com
export KOPS_STATE_STORE=s3://kops-cluster-state-5582a348e45d656f
export NODE_SIZE=t3.micro
export CP_SIZE=t3.medium
export SSH_KEY=~/.ssh/thekubeground.pem
export OIDC_BUCKET=s3://oidc-5582a348e45d656f
export BACKUP_BUCKET=s3://kops-cluster-backup-5582a348e45d656f
export DATE_TIME=$(shell date +%Y%m%d-%H%M%S)
# export URL=$(shell kubectl get svc nginx-svc -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export NGINX_IC_INSTALLER=install-nginx-ic.sh
export APP_INSTALLER=install-app.sh
export CNAME_CREATOR=create-cname.sh
export KOPS_ACCESS_KEY=create-configure-kops-access-key.sh

create-cluster:
	kops create -f cluster.yaml

edit-cluster:
	kops edit cluster --name=${NAME}

update-cluster-check:
	kops update cluster --name=${NAME} --state=${KOPS_STATE_STORE}

update-cluster-execute:
	kops update cluster --name=${NAME} --state=${KOPS_STATE_STORE} --yes

create-configure-kops-access-key:
	cd scripts && "./${KOPS_ACCESS_KEY}"

edit-instancegroup-master:
	kops edit ig --name=${NAME} --state=${KOPS_STATE_STORE} control-plane-us-west-2a

edit-instancegroup-node:
	kops edit ig --name=${NAME} --state=${KOPS_STATE_STORE} nodes-us-west-2a

build-cluster:
	kops update cluster --name=${NAME} --yes --admin

get-clusters:
	kops get clusters --state="${KOPS_STATE_STORE}"

get-instancegroups:
	kops get ig --name=${NAME} --state="${KOPS_STATE_STORE}"

delete-cluster:
	kops delete cluster --name=${NAME} --state=${KOPS_STATE_STORE} --yes

validate-cluster:
	kops validate cluster --name=${NAME} --state=${KOPS_STATE_STORE} #-v 3

update-backend:
	bash scripts/update-backend.sh

backup-cluster:
	kops get clusters thekubeground.com -o yaml --state ${KOPS_STATE_STORE} \
		 | aws s3 cp - ${BACKUP_BUCKET}/${DATE_TIME}/cluster.yaml

update-aws-cluster-controller-policy:
	aws iam put-role-policy \
		--role-name aws-cloud-controller-manager.kube-system.sa.thekubeground.com \
		--policy-name aws-cloud-controller-manager.kube-system.sa.thekubeground.com \
		--policy-document file://policies/aws-cloud-controller-policy.json

set-imds-hops:
	aws ec2 modify-instance-metadata-options --http-put-response-hop-limit 2 \
		--region us-west-2 --instance-id i-01524724da5a7923f
	aws ec2 modify-instance-metadata-options --http-put-response-hop-limit 2 \
		--region us-west-2 --instance-id i-0f1fd4bea980e7b29

# check-website:
# 	curl http://${URL}

install-nginx-ic:
	cd scripts && ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
		-i ~/.ssh/v1.pem ubuntu@api.thekubeground.com 'bash -s' < \
		"${NGINX_IC_INSTALLER}"

deploy-application:
	cd scripts && "./${APP_INSTALLER}"

create-cname:
	cd scripts && "./${CNAME_CREATOR}"

ssh-cp:
	ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
		-i ${SSH_KEY} ubuntu@api.thekubeground.com

#create-cluster:
#	kops create cluster \
		--name=${NAME} \
		--state=${KOPS_STATE_STORE} \
		--cloud=aws \
		--zones=$(shell aws ec2 describe-availability-zones --region $(shell aws configure get region) \
			--query 'AvailabilityZones[?State==`available`] | [0].ZoneName') \
		--discovery-store="${OIDC_BUCKET}/${NAME}/discovery" \
		--node-count=1 \
		--node-size=${NODE_SIZE} \
		--control-plane-count=1 \
		--control-plane-size=${CP_SIZE} \
		--ssh-public-key=${SSH_KEY}

# add-ssh-key:
# 	kops create sshpublickey -i ${SSH_KEY} --name ${NAME} --state=${KOPS_STATE_STORE}

