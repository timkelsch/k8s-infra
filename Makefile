export AWS_PROFILE=kubeground-kops
export NAME=thekubeground.com
export KOPS_STATE_STORE=s3://kops-cluster-state-5582a348e45d656f
export NODE_SIZE=t3.micro
export CP_SIZE=t3.medium
export SSH_KEY=~/.ssh/id_ed25519.pub
export OIDC_BUCKET=s3://oidc-5582a348e45d656f

create-cluster:
	kops create -f cluster.yaml

add-ssh-key:
	kops create sshpublickey -i ${SSH_KEY} --name ${NAME} --state=${KOPS_STATE_STORE}

edit-cluster:
	kops edit cluster --name=${NAME}

update-cluster-check:
	kops update cluster --name=${NAME} --state=${KOPS_STATE_STORE}

update-cluster-execute:
	kops update cluster --name=${NAME} --state=${KOPS_STATE_STORE} --yes

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
	kops validate cluster --name=${NAME} --state=${KOPS_STATE_STORE} -v 3

update-backend:
	bash scripts/update-backend.sh


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