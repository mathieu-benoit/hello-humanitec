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

https://denniszielke.medium.com/advanced-load-balancing-scenarios-with-the-new-azure-application-gateway-for-containers-dd35c4de64df
