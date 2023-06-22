IN PROGRESS - DRAFT FOR AKS-BASIC

```bash
export RG=FIXME
export AKS='aks-basic'
export LOCATION='canadacentral'
export NODES_COUNT=3
export NODE_SIZE='Standard_DS2_v2'
export ZONES=false
HUMANITEC_IP_ADDRESSES="34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32"
LOCAL_IP_ADRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
```

```bash
az provider register --namespace Microsoft.ContainerService

az aks create \
    -g $RG \
    -n $AKS \
    --node-count 3 \
    --api-server-authorized-ip-ranges ${HUMANITEC_IP_ADDRESSES},${LOCAL_IP_ADRESS}/32 \
    --no-ssh-key

az aks get-credentials \
  -g $RG \
  -n $RG
```

```bash
az redis create \
    --name $cache \
    --resource-group $resourceGroup \
    --location "$location" \
    --sku $sku \
    --vm-size $size

# Get details of an Azure Cache for Redis
echo "Showing details of $cache"
az redis show --name "$cache" --resource-group $resourceGroup 

# Retrieve the hostname and ports for an Azure Redis Cache instance
redis=($(az redis show --name "$cache" --resource-group $resourceGroup --query [hostName,enableNonSslPort,port,sslPort] --output tsv))

# Retrieve the keys for an Azure Redis Cache instance
keys=($(az redis list-keys --name "$cache" --resource-group $resourceGroup --query [primaryKey,secondaryKey] --output tsv))
```



```bash
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

az aks create \
    -g $RG \
    -n $AKS \
    --enable-managed-identity \
    --node-count 1 \
    --enable-addons monitoring \
    --enable-msi-auth-for-monitoring \
    --no-ssh-key
```