[_<< Previous section: GKE basic setup in Staging_](/docs/gke-basic.md)

# GKE advanced setup in Production

- [[PA-GCP] Create the GKE cluster](#pa-gcp-create-the-gke-cluster)
- [[PA-GCP] Deploy the Nginx Ingress controller](#pa-gcp-deploy-the-nginx-ingress-controller)
- [[PA-GCP] Protect the Nginx Ingress controller behind a Global Cloud Load Balancer (GCLB) and Cloud Armor (WAF)](#pa-gcp-protect-the-nginx-ingress-controller-behind-a-global-cloud-load-balancer-gclb-and-cloud-armor-waf)
- [[PA-HUM] Create the associated DNS and TLS resource definitions](#pa-hum-create-the-associated-dns-and-tls-resource-definitions)
- [[PA-GCP] Create the Google Service Account to access the GKE cluster](#pa-gcp-create-the-google-service-account-to-access-the-gke-cluster)
- [[PA-HUM] Create the GKE access resource definition](#pa-hum-create-the-gke-access-resource-definition)
- [[PA-GCP] Create the Google Service Account to access Cloud Logging](#pa-gcp-create-the-google-service-account-to-access-cloud-logging)
- [[PA-HUM] Create the Production Environment](#pa-hum-create-the-production-environment)
- [[PA-GCP] Create a Spanner database](#pa-gcp-create-a-spanner-database)
- [[PA-HUM] Create the Spanner access resource definition](#pa-hum-create-the-spanner-access-resource-definition)
- [[PA-HUM] Update the custom Service Account resource definition with the Workload Identity annotation for `cartservice`](#pa-hum-update-the-custom-service-account-resource-definition-with-the-workload-identity-annotation-for-cartservice)
- [[DE-HUM] Deploy the `cartservice` connected to the Spanner database](#de-hum-deploy-the-cartservice-connected-to-the-spanner-database)
- [Test the Online Boutique website](#test-the-online-boutique-website)

```mermaid
flowchart LR
  subgraph Humanitec
    direction LR
    subgraph onlineboutique-app [Online Boutique App]
      subgraph Production
        direction LR
        cartservice-workload([cartservice])
        frontend-workload([frontend])
      end
    end
    subgraph Resources
        custom-ingress>custom-ingress]
        custom-dns>custom-dns]
        gke-advanced-connection>gke-advanced-connection]
        redis-cart-connection>redis-cart-connection]
        logging-connection
    end
  end
  subgraph Google Cloud
    direction TB
    subgraph gke-advanced
        subgraph ingress-controller
            nginx{{nginx}}
        end
        subgraph onlineboutique
            frontend-->cartservice
        end
        nginx-->frontend
    end
    gke-admin-gsa[\gke-admin-gsa/]
    onlineboutique-app-->onlineboutique
    logging-reader-gsa[\logging-reader-gsa/]
    cloud-logging((cloud-logging))
    gke-advanced-.->gke-node-gsa[\gke-node-gsa/]
    gke-node-gsa-.->artifact-registry((artifact-registry))
    gke-node-gsa-.->cloud-logging
    cloud-armor((cloud-armor))-->cloud-ingress((cloud-ingress))
    spanner[(spanner)]
    spanner-gsa[\spanner-gsa/]
  end
  enduser((End user))-->cloud-armor
  cloud-ingress-->nginx
  logging-connection-.->logging-reader-gsa
  logging-reader-gsa-.->cloud-logging
  gke-advanced-connection-.->gke-admin-gsa
  gke-admin-gsa-.->gke-advanced
  redis-cart-connection-.->spanner-gsa
  spanner-gsa-.->spanner
  cartservice-->spanner-gsa
```

```bash
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
CLUSTER_NAME=gke-advanced
REGION=northamerica-northeast1
ZONE=${REGION}-a
NETWORK=default
HUMANITEC_IP_ADDRESSES="34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32"
LOCAL_IP_ADRESS=$(curl -s ifconfig.co)

HUMANITEC_ORG=FIXME
export HUMANITEC_CONTEXT=/orgs/${HUMANITEC_ORG}
export HUMANITEC_TOKEN=FIXME

ENVIRONMENT=${PRODUCTION_ENV}
```

## [PA-GCP] Create the GKE cluster

As Platform Engineer, in Google Cloud.

```bash
gcloud services enable container.googleapis.com
```

Create a least privilege Google Service Account for the nodes of the GKE cluster:
```bash
gcloud services enable cloudresourcemanager.googleapis.com
GKE_NODE_SA_NAME=${CLUSTER_NAME}
GKE_NODE_SA_ID=${GKE_NODE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${GKE_NODE_SA_NAME} \
    --display-name=${GKE_NODE_SA_NAME}
roles="roles/logging.logWriter roles/monitoring.metricWriter roles/monitoring.viewer"
for r in $roles; do \
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${GKE_NODE_SA_ID}" \
    --role $r; \
done
```

Create an Artifact Registry repository in order to store the container images:
```bash
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
CONTAINERS_REGISTRY_NAME=containers
gcloud artifacts repositories create ${CONTAINERS_REGISTRY_NAME} \
    --location ${REGION} \
    --repository-format docker
gcloud artifacts repositories add-iam-policy-binding ${CONTAINERS_REGISTRY_NAME} \
    --location ${REGION} \
    --member "serviceAccount:${GKE_NODE_SA_ID}" \
    --role roles/artifactregistry.reader
```

Create the GKE cluster with advanced and secure features (like Workload Identity, Network Policies, Confidential nodes, private nodes)
```bash
CLUSTER_FIREWALL_RULE_TAG=${CLUSTER_NAME}-nodes
CLUSTER_MASTER_IP_CIDR=172.16.0.32/28
gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --scopes cloud-platform \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-master-authorized-networks \
    --master-authorized-networks ${HUMANITEC_IP_ADDRESSES},${LOCAL_IP_ADRESS}/32 \
    --no-enable-google-cloud-access \
    --enable-ip-alias \
    --enable-private-nodes \
    --master-ipv4-cidr ${CLUSTER_MASTER_IP_CIDR} \
    --tags ${CLUSTER_FIREWALL_RULE_TAG} \
    --network ${NETWORK} \
    --service-account ${GKE_NODE_SA_ID} \
    --machine-type n2d-standard-4 \
    --enable-confidential-nodes \
    --release-channel rapid \
    --enable-dataplane-v2 \
    --enable-shielded-nodes \
    --shielded-integrity-monitoring \
    --shielded-secure-boot
```

Create a Cloud NAT router in order to access the public internet in egress from the GKE cluster:
```bash
gcloud compute routers create ${CLUSTER_NAME} \
    --network ${NETWORK} \
    --region ${REGION}
gcloud compute routers nats create ${CLUSTER_NAME} \
    --router-region ${REGION} \
    --router ${CLUSTER_NAME} \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

## [PA-GCP] Deploy the Nginx Ingress controller

As Platform Engineer, in Google Cloud.

Deploy the Nginx Ingress Controller:
```bash
NGINX_NEG_PORT=443
NGINX_NEG_NAME=${CLUSTER_NAME}-ingress-nginx-${NGINX_NEG_PORT}-neg
cat <<EOF > ${CLUSTER_NAME}-nginx-ingress-controller-values.yaml
controller:
  service:
    enableHttp: false
    type: ClusterIP
    annotations:
      cloud.google.com/neg: '{"exposed_ports": {"${NGINX_NEG_PORT}":{"name": "${NGINX_NEG_NAME}"}}}'
  config:
    use-forwarded-headers: true
EOF
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    -f ${CLUSTER_NAME}-nginx-ingress-controller-values.yaml
```

Allow Kubernetes master nodes to talk to the node pool on port `8443` for Nginx Ingress controller:
```bash
gcloud compute firewall-rules create k8s-masters-to-nodes-on-8443 \
    --network ${NETWORK} \
    --direction INGRESS \
    --source-ranges ${CLUSTER_MASTER_IP_CIDR} \
    --target-tags ${CLUSTER_FIREWALL_RULE_TAG} \
    --allow tcp:8443
```

## [PA-GCP] Protect the Nginx Ingress controller behind a Global Cloud Load Balancer (GCLB) and Cloud Armor (WAF)

Allow traffic from the Global Load Balancer (GCLB) to the node pool on port `443` for Nginx Ingress controller:
```bash
gcloud compute firewall-rules create ${CLUSTER_NAME}-allow-tcp-loadbalancer \
    --network ${NETWORK} \
    --allow tcp:${NGINX_NEG_PORT} \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags ${CLUSTER_FIREWALL_RULE_TAG}
```

```bash
gcloud compute health-checks create https ${CLUSTER_NAME}-ingress-nginx-health-check \
    --port ${NGINX_NEG_PORT} \
    --check-interval 60 \
    --unhealthy-threshold 3 \
    --healthy-threshold 1 \
    --timeout 5 \
    --request-path /healthz

gcloud compute backend-services create ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --load-balancing-scheme EXTERNAL_MANAGED \
    --protocol HTTPS \
    --port-name https \
    --health-checks ${CLUSTER_NAME}-ingress-nginx-health-check \
    --enable-logging \
    --global

gcloud compute backend-services add-backend ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --network-endpoint-group ${NGINX_NEG_NAME} \
    --network-endpoint-group-zone ${ZONE} \
    --balancing-mode RATE \
    --capacity-scaler 1.0 \
    --max-rate-per-endpoint 100 \
    --global

gcloud compute url-maps create ${CLUSTER_NAME}-ingress-nginx-loadbalancer \
    --default-service ${CLUSTER_NAME}-ingress-nginx-backend-service

gcloud compute target-http-proxies create ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --url-map ${CLUSTER_NAME}-ingress-nginx-loadbalancer
```

```bash
gcloud compute addresses create ${CLUSTER_NAME}-public-static-ip \
    --global
INGRESS_IP=$(gcloud compute addresses describe ${CLUSTER_NAME}-public-static-ip --global --format "value(address)")
echo ${INGRESS_IP}
```

```bash
ONLINEBOUTIQUE_DNS=ob-${CLUSTER_NAME}.endpoints.${PROJECT_ID}.cloud.goog
cat <<EOF > ${ONLINEBOUTIQUE_APP}-${CLUSTER_NAME}-dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${ONLINEBOUTIQUE_DNS}"
x-google-endpoints:
- name: "${ONLINEBOUTIQUE_DNS}"
  target: "${INGRESS_IP}"
EOF
gcloud endpoints services deploy ${ONLINEBOUTIQUE_APP}-${CLUSTER_NAME}-dns-spec.yaml
```

Create a self managed SSL certificate:
```bash
openssl genrsa -out ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ca.key 2048
openssl req -x509 \
    -new \
    -nodes \
    -days 365 \
    -key ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ca.key \
    -out ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ca.crt \
    -subj "/CN=${ONLINEBOUTIQUE_DNS}"
```

Upload the SSL certificate in Google Cloud:
```bash
gcloud compute ssl-certificates create ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ssl-certificate \
    --certificate ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ca.crt \
    --private-key ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ca.key \
    --global
```

```bash
gcloud compute target-https-proxies create ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --url-map ${CLUSTER_NAME}-ingress-nginx-loadbalancer \
    --ssl-certificates ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-ssl-certificate
```

```bash
gcloud compute forwarding-rules create ${CLUSTER_NAME}-https-forwarding-rule \
    --load-balancing-scheme EXTERNAL_MANAGED \
    --network-tier PREMIUM \
    --global \
    --ports 443 \
    --target-https-proxy ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --address ${CLUSTER_NAME}-public-static-ip
```

```bash
cat <<EOF > ${CLUSTER_NAME}-http-to-https-redirect.yaml
kind: compute#urlMap
name: ${CLUSTER_NAME}-http-to-https-redirect
defaultUrlRedirect:
  redirectResponseCode: MOVED_PERMANENTLY_DEFAULT
  httpsRedirect: True
EOF
gcloud compute url-maps import ${CLUSTER_NAME}-http-to-https-redirect \
    --source ${CLUSTER_NAME}-http-to-https-redirect.yaml \
    --global
gcloud compute target-http-proxies create ${CLUSTER_NAME}-http-to-https-redirect-proxy \
    --url-map ${CLUSTER_NAME}-http-to-https-redirect \
    --global
gcloud compute forwarding-rules create ${CLUSTER_NAME}-http-to-https-redirect-rule \
    --load-balancing-scheme EXTERNAL_MANAGED \
    --network-tier PREMIUM \
    --address ${CLUSTER_NAME}-public-static-ip \
    --global \
    --target-http-proxy ${CLUSTER_NAME}-http-to-https-redirect-proxy \
    --ports 80
```

Create Cloud Armor (DDoS protection only) and attach it to the public endpoint:
```bash
gcloud compute security-policies create ${CLUSTER_NAME}-security-policy
gcloud compute security-policies update ${CLUSTER_NAME}-security-policy \
    --enable-layer7-ddos-defense
gcloud compute backend-services update ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --global \
    --security-policy ${CLUSTER_NAME}-security-policy
```

## [PA-HUM] Create the associated DNS and TLS resource definitions

As Platform Engineer, in Humanitec.

Create the custom Ingress resource definition:
```bash
cat <<EOF > custom-ingress.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: custom-ingress
object:
  name: custom-ingress
  type: ingress
  driver_type: humanitec/ingress
  driver_inputs:
    values:
      api_version: v1
      class: nginx
      no_tls: true
  criteria:
    - env_id: ${ENVIRONMENT}
EOF
humctl create \
    -f custom-ingress.yaml
```
<details>
  <summary>With curl.</summary>

  ```bash
  cat <<EOF > custom-ingress.yaml
  id: custom-ingress
  name: custom-ingress
  type: ingress
  driver_type: humanitec/ingress
  driver_inputs:
    values:
      api_version: v1
      class: nginx
      no_tls: true
  criteria:
    - env_id: ${ENVIRONMENT}
  EOF
  yq -o json custom-ingress.yaml > custom-ingress.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @custom-ingress.json
  ```
</details>

Create the custom DNS resource definition:
```bash
cat <<EOF > ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns
object:
  name: ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns
  type: dns
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${ONLINEBOUTIQUE_DNS}
  criteria:
    - env_id: ${ENVIRONMENT}
      app_id: ${ONLINEBOUTIQUE_APP}
EOF
humctl create \
    -f ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.yaml
```
<details>
  <summary>With curl.</summary>

  ```bash
  cat <<EOF > ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.yaml
  id: ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns
  name: ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns
  type: dns
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${ONLINEBOUTIQUE_DNS}
  criteria:
    - env_id: ${ENVIRONMENT}
      app_id: ${ONLINEBOUTIQUE_APP}
  EOF
  yq -o json ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.yaml > ${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @${CLUSTER_NAME}-${ONLINEBOUTIQUE_APP}-dns.json
```
</details>

## [PA-GCP] Create the Google Service Account to access the GKE cluster

As Platform Engineer, in Google Cloud.

Create the Google Service Account (GSA) with the appropriate role:
```bash
GKE_ADMIN_SA_NAME=humanitec-to-${CLUSTER_NAME}
GKE_ADMIN_SA_ID=${GKE_ADMIN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${GKE_ADMIN_SA_NAME} \
    --display-name=${GKE_ADMIN_SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${GKE_ADMIN_SA_ID}" \
    --role "roles/container.admin" \
    --condition='resource.name == "${CLUSTER_NAME}"'
```

Download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${GKE_ADMIN_SA_NAME}.json \
    --iam-account ${GKE_ADMIN_SA_ID}
```

## [PA-HUM] Create the GKE access resource definition

As Platform Engineer, in Humanitec.

Create the GKE access resource definition:
```bash
cat <<EOF > ${CLUSTER_NAME}.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}
object:
  name: ${CLUSTER_NAME}
  type: k8s-cluster
  driver_type: humanitec/k8s-cluster-gke
  driver_inputs:
    values:
      loadbalancer: ${INGRESS_IP}
      name: ${CLUSTER_NAME}
      project_id: ${PROJECT_ID}
      zone: ${ZONE}
    secrets:
      credentials: $(cat ${GKE_ADMIN_SA_NAME}.json)
  criteria:
    - env_id: ${ENVIRONMENT}
EOF
humctl create \
    -f ${CLUSTER_NAME}.yaml
```
<details>
  <summary>With curl.</summary>

  ```bash
  cat <<EOF > ${CLUSTER_NAME}.yaml
  id: ${CLUSTER_NAME}
  name: ${CLUSTER_NAME}
  type: k8s-cluster
  driver_type: humanitec/k8s-cluster-gke
  driver_inputs:
    values:
      loadbalancer: ${INGRESS_IP}
      name: ${CLUSTER_NAME}
      project_id: ${PROJECT_ID}
      zone: ${ZONE}
    secrets:
      credentials: $(cat ${GKE_ADMIN_SA_NAME}.json)
  criteria:
    - env_id: ${ENVIRONMENT}
  EOF
  yq -o json ${CLUSTER_NAME}.yaml > ${CLUSTER_NAME}.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @${CLUSTER_NAME}.json
  ```
</details>

Clean sensitive information locally:
```bash
rm ${GKE_ADMIN_SA_NAME}.json
rm ${CLUSTER_NAME}.yaml
rm ${CLUSTER_NAME}.json
```

## [PA-GCP] Create the Google Service Account to access Cloud Logging

As Platform Engineer, in Google Cloud.

Create the Google Service Account (GSA) with the appropriate role:
```bash
LOGGING_READER_SA_NAME=humanitec-to-${CLUSTER_NAME}-logs
LOGGING_READER_SA_ID=${LOGGING_READER_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${LOGGING_READER_SA_NAME} \
    --display-name=${LOGGING_READER_SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${LOGGING_READER_SA_ID}" \
    --role "roles/logging.viewer"
```

Download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${LOGGING_READER_SA_NAME}.json \
    --iam-account ${LOGGING_READER_SA_ID}
```

## [PA-HUM] Create the Cloud Logging access resource definition

As Platform Engineer, in Humanitec.

Create the Cloud Logging access resource definition for the Production Environment Type:
```bash
cat <<EOF > ${CLUSTER_NAME}-logging.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}-logging
object:
  name: ${CLUSTER_NAME}-logging
  type: logging
  driver_type: humanitec/logging-gcp
  driver_inputs:
    values:
      cluster_name: ${CLUSTER_NAME}
      cluster_zone: ${ZONE}
      project_id: ${PROJECT_ID}
    secrets:
      credentials: $(cat ${LOGGING_READER_SA_NAME}.json)
  criteria:
    - env_type: ${PRODUCTION_ENV}
EOF
humctl create \
    -f ${CLUSTER_NAME}-logging.yaml
```
<details>
  <summary>With curl.</summary>

  ```bash
  cat <<EOF > ${CLUSTER_NAME}-logging.yaml
  id: ${CLUSTER_NAME}-logging
  name: ${CLUSTER_NAME}-logging
  type: logging
  driver_type: humanitec/logging-gcp
  driver_inputs:
    values:
      cluster_name: ${CLUSTER_NAME}
      cluster_zone: ${ZONE}
      project_id: ${PROJECT_ID}
    secrets:
      credentials: $(cat ${LOGGING_READER_SA_NAME}.json)
  criteria:
    - env_id: ${ENVIRONMENT}
  EOF
  yq -o json ${CLUSTER_NAME}-logging.yaml > ${CLUSTER_NAME}-logging.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @${CLUSTER_NAME}-logging.json
  ```
</details>

Clean sensitive information locally:
```bash
rm ${LOGGING_READER_SA_NAME}.json
rm ${CLUSTER_NAME}-logging.yaml
rm ${CLUSTER_NAME}-logging.json
```

## [PA-HUM] Create the Production Environment

As Platform Engineer, in Humanitec.

Create the new Environment by cloning the existing Environment from its latest Deployment:
```bash
CLONED_ENVIRONMENT=development
humctl create environment ${ENVIRONMENT} \
    --name Production \
    -t ${PRODUCTION_ENV} \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP} \
    --from ${CLONED_ENVIRONMENT}
```
<details>
  <summary>With curl.</summary>

  Get the latest Deployment's id of the existing Environment:
  ```bash
  CLONED_ENVIRONMENT=development
  LAST_DEPLOYMENT_IN_CLONED_ENVIRONMENT=$(curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${CLONED_ENVIRONMENT}/deploys" \
      -s \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -H "Content-Type: application/json" \
      | jq -r .[0].id)
  ```

  Create the new Environment by cloning the existing Environment from its latest Deployment:
  ```bash
  cat <<EOF > ${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.yaml
  from_deploy_id: ${LAST_DEPLOYMENT_IN_CLONED_ENVIRONMENT}
  id: ${ENVIRONMENT}
  name: Production
  type: ${ENVIRONMENT}
  EOF
  yq -o json ${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.yaml > ${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.json
  ```
</details>

Deploy the new Environment:
```bash
humctl deploy env ${CLONED_ENVIRONMENT} ${ENVIRONMENT} \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}
```

At this stage, you can already [test the Online Boutique website](#test-the-online-boutique-website) in its existing state.

### [PA-GCP] Create a Spanner database

Create the Spanner instance and database:
```bash
gcloud services enable spanner.googleapis.com

SPANNER_REGION_CONFIG=regional-us-east5
SPANNER_INSTANCE_NAME=${ONLINEBOUTIQUE_APP}
gcloud spanner instances create ${SPANNER_INSTANCE_NAME} \
    --description="online boutique shopping cart" \
    --instance-type free-instance \
    --config ${SPANNER_REGION_CONFIG}

SPANNER_DATABASE_NAME=carts
gcloud spanner databases create ${SPANNER_DATABASE_NAME} \
    --instance ${SPANNER_INSTANCE_NAME} \
    --database-dialect GOOGLE_STANDARD_SQL \
    --ddl "CREATE TABLE CartItems (userId STRING(1024), productId STRING(1024), quantity INT64) PRIMARY KEY (userId, productId); CREATE INDEX CartItemsByUserId ON CartItems(userId);"
```

Create a dedicated Google Service Account for the `cartservice` to access this Spanner database:
```bash
SPANNER_DB_USER_GSA_NAME=spanner-db-user-sa
SPANNER_DB_USER_GSA_ID=${SPANNER_DB_USER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
ONLINEBOUTIQUE_NAMESPACE=${ENVIRONMENT}-${ONLINEBOUTIQUE_APP}
CARTSERVICE_KSA_NAME=cartservice
gcloud iam service-accounts create ${SPANNER_DB_USER_GSA_NAME} \
    --display-name=${SPANNER_DB_USER_GSA_NAME}
gcloud spanner databases add-iam-policy-binding ${SPANNER_DATABASE_NAME} \
    --instance ${SPANNER_INSTANCE_NAME} \
    --member "serviceAccount:${SPANNER_DB_USER_GSA_ID}" \
    --role roles/spanner.databaseUser
gcloud iam service-accounts add-iam-policy-binding ${SPANNER_DB_USER_GSA_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[${ONLINEBOUTIQUE_NAMESPACE}/${CARTSERVICE_KSA_NAME}]" \
    --role roles/iam.workloadIdentityUser
```

Get the Spanner database connection string:
```bash
SPANNER_DB_CONNECTION_STRING=$(gcloud spanner databases describe ${SPANNER_DATABASE_NAME} \
    --instance ${SPANNER_INSTANCE_NAME} \
    --format 'get(name)')
echo ${SPANNER_DB_CONNECTION_STRING}
```
_Note: re-run the above the command until you get the value._

## [PA-HUM] Create the Spanner access resource definition

As Platform Engineer, in Humanitec.

```bash
cat <<EOF > ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner
object:
  name: ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner
  type: redis
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${SPANNER_DB_CONNECTION_STRING}
      user: ${SPANNER_DB_USER_GSA_ID}
  criteria:
    - env_id: ${ENVIRONMENT}
EOF
humctl create \
    -f ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.yaml
```
<details>
  <summary>With curl.</summary>

  ```bash
  cat <<EOF > ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.yaml
  id: ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner
  name: ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner
  type: redis
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${SPANNER_DB_CONNECTION_STRING}
      user: ${SPANNER_DB_USER_GSA_ID}
  criteria:
    - env_id: ${ENVIRONMENT}
  EOF
  yq -o json ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.yaml > ${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.json
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -d @${SPANNER_INSTANCE_NAME}-${SPANNER_DATABASE_NAME}-${ENVIRONMENT}-spanner.json
```
</details>

_Note: Here we create a Redis resource definition but in a near future, this will be a Spanner resource type._

## [PA-HUM] Update the custom Service Account resource definition with the Workload Identity annotation for `cartservice`

Update the Kubernetes `ServiceAccount` to add the Workload Identity annotation for allowing the `cartservice` to access the Spanner database:
```bash
cat <<EOF > custom-service-account.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: custom-service-account
object:
  name: custom-service-account
  type: k8s-service-account
  driver_type: humanitec/template
  driver_inputs:
    values:
      templates:
        init: |
          name: {{ index (regexSplit "\\\\." "\$\${context.res.id}" -1) 1 }}
        manifests: |-
          service-account.yaml:
            location: namespace
            data:
              apiVersion: v1
              kind: ServiceAccount
              metadata:
                {{if hasPrefix "projects/" \${resources.redis.outputs.host} }}
                annotations:
                  iam.gke.io/gcp-service-account: \${resources.redis.outputs.user}
                {{end}}
                name: {{ .init.name }}
        outputs: |
          name: {{ .init.name }}
  criteria:
    - {}
EOF
humctl apply \
    -f custom-service-account.yaml
```

_Note: Here we test if the `${resources.redis.outputs.host}` starts with `projects/` which is the beginning of a the connection string of the Spanner database. In a near future, we will leverage the Spanner resource type instead._

## [DE-HUM] Deploy the `cartservice` connected to the Spanner database

```bash
score-humanitec delta \
    --app ${ONLINEBOUTIQUE_APP} \
    --env ${ENVIRONMENT} \
    --org ${HUMANITEC_ORG} \
    --token ${HUMANITEC_TOKEN} \
    --deploy \
    --retry \
    -f samples/onlineboutique/cartservice/score-spanner.yaml \
    --extensions samples/onlineboutique/cartservice/humanitec.score.yaml
```

## Test the Online Boutique website

Get the public DNS exposing the `frontend` Workload:
```bash
echo -e "https://$(humctl get active-resources \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT} \
    -o json \
    | jq -c '.[] | select(.object.type | contains("dns"))' \
    | jq -r .object.resource.host)"
```
<details>
  <summary>With curl.</summary>
  
  ```bash
  echo -e "https://$(curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT}/resources" \
      -s \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -H "Content-Type: application/json" \
      | jq -c '.[] | select(.type | contains("dns"))' \
      | jq -r .resource.host)"
  ```
</details>

_Note: re-run the above command until you get a value._

[_<< Previous section: GKE basic setup in Staging_](/docs/gke-basic.md)
