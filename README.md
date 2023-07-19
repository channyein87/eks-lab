# EKS LAB

EKS lab envrionment to experience different Kuberentes projects.

## Base

Module with base components where nearly production cluster needs.

- load balancer controller
- metrics server
- external dns
- cert manager
- cluster autoscaler
- nginx ingress
- hashicorp vault
- oauth2 proxy

## Projects

### Atlantis

Terraform automation to deploy the infrastrature within the pull request.

### Linkerd

Service mesh project which is light weight and fast. Sidecar proxy is written in Rust.

### FluxCD

GitOps tool for automating application delivery pipelines.

## Usage

Go into the desired project directory and run the Terraform.

E.g.

```shell
cd linkerd
terraform init
terraform plan
terraform apply
```
