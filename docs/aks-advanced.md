IN PROGRESS - DRAFT FOR AKS-ADVANCED

```bash
az aks create \
    -g $RG \
    -n $AKS \
    --enable-managed-identity \
    --node-count 1 \
    --enable-addons monitoring \
    --enable-msi-auth-for-monitoring \
    --no-ssh-key
```