# Metaflow Set up Guide

## Overview

Metaflow is an open-source framework for building and managing real-life machine learning workflows.

In order to provide the its various functionality, Metaflow needs to deploy several pieces of infrastructure using Terraform.

The folloing infra is deployed in this build:
- Google Kubernetes Engine (GKE): Handles compute (CPU & GPU) management
- Network Layer: Private subnetwork for internal communication between various infra components
- Storage Bucket: Supports Metaflow auto versioning
- Database: ???
- Artifact Store: Allows users to push custom docker images, that can be retrieved by GKE compute instances
- Service Accounts: Accounts with various permissions to access deployed infra


This guide provides instructions for:
- [Setting up a new Metaflow Stack](#setting-up-a-new-stack)
- [Setting up a new user](#new-user-setup)


## Pre Requisites

This is needed for both new stack and new users.

### Terraform Tooling

- Install Terraform following [these instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Clone the [Atelico Metaflow Terraform Template](https://github.com/atelico/metaflow-tools)

### GCP CLI

- The GCP CLI, `gcloud`, will be used by terraform for authentication purposes
- Install the `gcloud` CLI tool following [these instructions](https://cloud.google.com/sdk/docs/install-sdk)

### kubectl

- Standard CLI tool for working with Kubernetes clusters (GKE, in our case)
- Install `kubectl` following [these instructions](https://kubernetes.io/docs/tasks/tools/#kubectl)


## Setting up a new stack

### Initialization and Authentication

1. Create a new Project in Google Cloud Console, noting the PROJECT_ID.
2. Log into GCP via CLI 
	```
	$ gcloud auth login
	$ gcloud auth application-default login
	```
3. Set `gcloud` active project
	```
	$ gcloud config set project <PROJECT_ID>
	```

4. `cd` into `metaflow-tools/gcp/terraform` and initialize terraform
	```
	$ cd metaflow-tools/gcp/terraform
	$ terraform init
	```
5. Create a file `FILE.tfvars` in `metaflow-tools/gcp/terraform` with following content. `FILE` can be any meaningful name, e.g., `metaflow.tfvars`.

	```
	org_prefix = "<ORG_PREFIX>"
	project = "<GCP_PROJECT_ID>"
	```

### Applying Terraform

There are three stages to the creation of the Metaflow stack:

1. Enabling GCP APIs (e.g. Compute Enginer API, Network API, ...)
2. Provisioning the Infrastructure: This instructs GCP to create the infrastructure components specified by terraform.
3. Deplying various Metaflow services to the GKE Cluster: Several micro services keep metaflow running (e.g. collecting metadata). This step initializes them on our newly provisioned GKE.

---

1. __Enable GCP APIs__
	
	```
	$ terraform apply -target=module.apis -var-file=FILE.tfvars
	```


	#### Interlude: Requesting Compute Quotas 

	In a new project, the default quotas may be low (and sometimes zero). In order to successfully deploy the stack, we need to verify and increase our quotas.


	- GPUS: Increase the `GPUS_ALL_REGION` quota to at least 1. This is the miniumum and is usually accepted automatically. Anything greater might require reuqesting via different channels.
	- By default, we use the `nvidia-l4` GPU, for which the default quota is 1. If the GPU pools are set up with different GPU types (e.g. `A100`) (See `gpu_type` in `~./variables.tf`), then we need to ensure that we have sufficient quota before intializing the stack. 
	- Go to [here](https://console.cloud.google.com/iam-admin/quotas) to manage project quotas.


2. __Provision GCP Infra__
	
	```
	$ terraform apply -target=module.infra -var-file=FILE.tfvars
	``` 

3.  __Deploy Metaflow services__

	```
	$ terraform apply -target=module.services -var-file=FILE.tfvars
	```
	

At this point, the Metaflow stack should be up and running!


## New User Setup

1. Login with gcloud CLI. Login as a sufficiently capabable user: 

	```
	$ gcloud auth application-default login.
	```

2. Configure your local Kubernetes context to point to the the right Kubernetes cluster:

	```
	$ gcloud container clusters get-credentials gke-metaflow-default --region=<CLUSTER-REGION>
	```

3. Configure Metaflow. Copy `config.json` to `~/.metaflowconfig/config.json`:
	
	```
	$ cp config.json ~/.metaflowconfig/config.json
	```

4. Port Fowarding:

	Due to the manner in which Metaflow set up the networking, there is no publicly accessible endpoint for the metaflow services running in the GKE. Metaflow has provided a script, `forward_metaflow_ports.py`, that performs the neccessary kubectl port forwarding. Since we do not want to run this everytime we run Metaflow, we run this as a background process.

	See [here](https://docs.outerbounds.com/engineering/deployment/gcp-k8s/advanced/#authenticated-public-endpoints-for-metaflow-services) for more details.


## Docker Images

To run metaflow steps on a gpu node for machine learning purposes, a docker image with appropriate packages and drivers should be provided. Additonally metaflow natively calls `python` instead of `python3`, whereas many modern images only support `python3`, thus it is neccesary to create a symlink. We provide an example docker file in `/gcp/docker/Dockerfile` illustratiing this.


Here a few steps to get started with the suggested image:

1. Authenticate docker with Artifact Registry:
	```
	$ gcloud auth configure-docker <REGION>-docker.pkg.dev
	```
2. Build docker image:
	```
	$ cd ../docker/
	$ docker build -t huggingface-pytorch-training-cu121.2-3.transformers.4-42.ubuntu2204.py310-metaflow .
	```
3. Tag image for Artifact Registry:

	```
	$ docker tag huggingface-pytorch-training-cu121.2-3.transformers.4-42.ubuntu2204.py310-metaflow <METAFLOW_DEFAULT_DOCKER_REGISTRY>/huggingface-pytorch-training-cu121.2-3.transformers.4-42.ubuntu2204.py310-metaflow:latest
	```
4. Push image to registry (this may take awhile):
	```
	$ docker push <METAFLOW_DEFAULT_DOCKER_REGISTRY>/huggingface-pytorch-training-cu121.2-3.transformers.4-42.ubuntu2204.py310-metaflow:latest
	```

`METAFLOW_DEFAULT_DOCKER_REGISTRY` can be obtained from ~/.metaflowconfg/confg.json






















	
