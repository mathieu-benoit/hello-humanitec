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
    -n $AKS
```

## [PA-GCP] Deploy the Nginx Ingress controller

As Platform Admin, in Azure.

Deploy the Nginx Ingress Controller:
```bash
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace
```

Grab the Public IP address of that Ingress Controller:
```bash
INGRESS_IP=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
echo ${INGRESS_IP}
```
_Note: re-run the above command until you get a value._

```bash
REDIS_NAME=redis-cart-${ENVIRONMENT}
REDIS_SKU="basic"
REDIS_SIZE="C0"

az provider register --namespace Microsoft.Cache

az redis create \
    --name $REDIS_NAME \
    --resource-group $RG \
    --location "$LOCATION" \
    --sku $REDIS_SKU \
    --vm-size $REDIS_SIZE

REDIS_HOST=$(az redis show \
    --name "$REDIS_NAME" \
    --resource-group $RG \
    --query [hostName] \
    --output tsv)
echo ${REDIS_HOST}
REDIS_PORT=$(az redis show \
    --name "$REDIS_NAME" \
    --resource-group $RG \
    --query [sslPort] \
    --output tsv)
echo ${REDIS_PORT}
REDIS_AUTH=$(az redis list-keys \
    --name "$REDIS_NAME" \
    --resource-group $RG \
    --query [primaryKey] \
    --output tsv)
echo ${REDIS_AUTH}
```

```bash
NAMESPACE=onlineboutique
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${NAMESPACE} \
    --set frontend.platform=azure \
    --set cartDatabase.inClusterRedis.create=false \
    --set cartDatabase.connectionString="${REDIS_HOST}:${REDIS_PORT}\,abortConnect=false\,ssl=true\,password=${REDIS_AUTH}"
```