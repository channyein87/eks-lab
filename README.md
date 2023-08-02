# EKS LAB

EKS lab envrionment to experience different Kuberentes projects.

## Base

Module with base components where nearly production cluster needs.

- load balancer controller
- metrics server
- external dns
- cert manager
- cluster autoscaler
- hashicorp vault
- nginx ingress
- [oauth2 proxy](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider#github-auth-provider)

## Projects

### Atlantis

Terraform automation to deploy the infrastrature within the pull request.

### Linkerd

Service mesh project which is light weight and fast. Sidecar proxy is written in Rust.

### FluxCD

GitOps tool for automating application delivery pipelines using FluxCD.

### ArgoCD

GitOps tool for automating application delivery pipelines using ArgoCD.

## Usage

Go into the desired project directory and run the Terraform.

E.g.

```shell
cd linkerd
touch terraform.tfvars # update values based on variables.tf
terraform init
terraform plan
terraform apply
```

## Warning

- Vault is currently setup to use EBS csi for storage and volumes are requirend to cleanup manually after the stack is destroyed.
