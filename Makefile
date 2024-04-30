export AWS_PROFILE=k8s-tmp
export NAME=k8s-pg.timkelsch.com
export KOPS_STATE_STORE=s3://kops-cluster-state-ffbf22bd9e96206c
export NODE_SIZE=t3.micro
export CP_SIZE=t3.medium
export SSH_KEY=~/.ssh/id_ed25519.pub

create-cluster:
	kops create cluster \
	--name=${NAME} \
	--state=${KOPS_STATE_STORE} \
	--cloud=aws \
	--zones=$(shell aws ec2 describe-availability-zones --region $(shell aws configure get region) \
	  --query 'AvailabilityZones[?State==`available`] | [0].ZoneName') \
	--discovery-store="s3://oidc-ffbf22bd9e96206c/${NAME}/discovery" \
	--node-count=1 \
	--node-size=${NODE_SIZE} \
	--control-plane-count=1 \
	--control-plane-size=${CP_SIZE} \
	--ssh-public-key=${SSH_KEY}

edit-cluster:
	kops edit cluster --name=${NAME}

edit-instancegroup:
	kops edit ig --name=${NAME} --state=${KOPS_STATE_STORE} nodes

build-cluster:
	kops update cluster --name=${NAME} --yes --admin

get-clusters:
	kops get clusters --state="${KOPS_STATE_STORE}" -v 5

delete-cluster:
	kops delete cluster --name=${NAME} --state=${KOPS_STATE_STORE} --yes

validate-cluster:
	kops validate cluster --name=${NAME} --state=${KOPS_STATE_STORE}

update-backend:
	bash scripts/update-backend.sh