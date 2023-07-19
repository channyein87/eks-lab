# EKS Module Bundle

Create EKS cluster with all based components.

## Listen Learned

### Prefix delegration not working

- `ENABLE_PREFIX_DELEGATION` of `vpc-cni` allows the node to create 110 pods.
- There is a catch that it has to configure before the node group, otherwise nodes will create in normal way.
- To do that set `before_compute = true` in `vpc-cni` addons config.

### Vault server KMS access denied

- Vault image version `1.14.0` doesn't take AWS IRSA in raft ha mode.
- Downgrade to `1.12.0`
