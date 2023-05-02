[_<< Previous section: GKE basic setup_](/docs/gke-basic.md)

# GKE advanced setup

- [[PA-GCP] Create the GKE cluster](#pa-gcp-create-the-gke-cluster)
- [[PA-GCP] Deploy the Nginx Ingress controller](#pa-gcp-deploy-the-nginx-ingress-controller)
- [[PA-GCP] Create the Google Service Account to access the GKE cluster](#pa-gcp-create-the-google-service-account-to-access-the-gke-cluster)
- [[PA-HUM] Create the GKE access resource definition](#pa-hum-create-the-gke-access-resource-definition)
- [[PA-GCP] Create the Google Service Account to access Cloud Logging](#pa-gcp-create-the-google-service-account-to-access-cloud-logging)

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
    end
    subgraph Resources
        gke-dev-connection>gke-dev-connection]
	logging-connection
    end
  end
  subgraph Google Cloud
    direction TB
    gke-admin-gsa[\gke-admin-gsa/]
    subgraph gke-cluster-dev
        subgraph ingress-controller
            nginx{{nginx}}
        end
    end
    logging-reader-gsa[\logging-reader-gsa/]
    cloud-logging((cloud-logging))
    gke-cluster-dev-.->gke-node-gsa[\gke-node-gsa/]
    gke-node-gsa-.->artifact-registry((artifact-registry))
    gke-node-gsa-.->cloud-logging
  end
  logging-connection-.->logging-reader-gsa
  logging-reader-gsa-.->cloud-logging
  gke-dev-connection-.->gke-admin-gsa
  gke-admin-gsa-.->gke-cluster-dev
```

```bash
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
CLUSTER_NAME=gke-advanced
REGION=northamerica-northeast1
ZONE=${REGION}-a
HUMANITEC_IP_ADDRESSES="34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32"
LOCAL_IP_ADRESS=$(curl -s ifconfig.co)

HUMANITEC_ORG=FIXME
HUMANITEC_TOKEN=FIXME

ENVIRONMENT=${CLUSTER_NAME}
```

## [PA-GCP] Create the GKE cluster

As Platform Admin, in Google Cloud.

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
for r in $roles; do gcloud projects add-iam-policy-binding ${PROJECT_ID} --member "serviceAccount:${GKE_NODE_SA_ID}" --role $r; done
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
    --network default \
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
    --network default \
    --region ${REGION}
gcloud compute routers nats create ${CLUSTER_NAME} \
    --router-region ${REGION} \
    --router ${CLUSTER_NAME} \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

## [PA-GCP] Deploy the Nginx Ingress controller

As Platform Admin, in Google Cloud.

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
```

Allow Kubernetes master nodes to talk to the node pool on port `8443` for Nginx Ingress controller:
```bash
gcloud compute firewall-rules create k8s-masters-to-nodes-on-8443 \
    --network default \
    --direction INGRESS \
    --source-ranges ${CLUSTER_MASTER_IP_CIDR} \
    --target-tags ${CLUSTER_FIREWALL_RULE_TAG} \
    --allow tcp:8443
```

## [PA-GCP] Create the Google Service Account to access the GKE cluster

As Platform Admin, in Google Cloud.

Create the Google Service Account (GSA) with the appropriate role:
```bash
GKE_ADMIN_SA_NAME=humanitec-to-${CLUSTER_NAME}
GKE_ADMIN_SA_ID=${GKE_ADMIN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${GKE_ADMIN_SA_NAME} \
    --display-name=${GKE_ADMIN_SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${GKE_ADMIN_SA_ID}" \
    --role "roles/container.admin"
```
_Note: for future considerations, add a condition to access onlye this specific GKE clusters, not all._

Download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${GKE_ADMIN_SA_NAME}.json \
    --iam-account ${GKE_ADMIN_SA_ID}
```

## [PA-HUM] Create the GKE access resource definition

As Platform Admin, in Humanitec.

Create the GKE access resource definition:
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

Clean sensitive information locally:
```bash
rm ${GKE_ADMIN_SA_NAME}.json
rm ${CLUSTER_NAME}.yaml
rm ${CLUSTER_NAME}.json
```

## [PA-GCP] Create the Google Service Account to access Cloud Logging

As Platform Admin, in Google Cloud.

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

As Platform Admin, in Humanitec.

Create the Cloud Logging access resource definition:
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

Clean sensitive information locally:
```bash
rm ${LOGGING_READER_SA_NAME}.json
rm ${CLUSTER_NAME}-logging.yaml
rm ${CLUSTER_NAME}-logging.json
```

## [PA-HUM] Create the `gke-advanced` Environment

As Platform Admin, in Humanitec.

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
name: ${ENVIRONMENT}
type: development
EOF
yq -o json ${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.yaml > ${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -d @${ONLINEBOUTIQUE_APP}-${ENVIRONMENT}-env.json
```

Get the current Delta in draft mode in the newly created Environment:
```bash
DRAFT_DELTA_IN_NEW_ENVIRONMENT=$(curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/deltas?env=${ENVIRONMENT}" \
    -s \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -H "Content-Type: application/json" \
    | jq -r .[0].id)
echo ${DRAFT_DELTA_IN_NEW_ENVIRONMENT}
```
_Note: re-run the above commands until you get a value for `DRAFT_DELTA_IN_NEW_ENVIRONMENT`._

Deploy current Delta in draft mode:
```bash
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT}/deploys \
    -X POST \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "comment": "Deploy App based on cloned Environment.",
  "delta_id": "${DRAFT_DELTA_IN_NEW_ENVIRONMENT}"
}
EOF
```

Get the public DNS exposing the `frontend` Workload:
```bash
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT}/resources" \
    -s \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -H "Content-Type: application/json" \
    | jq -c '.[] | select(.type | contains("dns"))' \
    | jq -r .resource.host
```
_Note: re-run the above command until you get a value._

**BELOW IS UNDER CONSTRUCTION, NOT READY YET... STAY TUNED!**

### Custom Service Account resource definition

```bash
cat <<EOF > custom-sa.yaml
id: custom-sa
name: custom-sa
type: k8s-service-account
driver_type: humanitec/template
driver_inputs:
  values:
    templates:
      init: |
        name: {{ index (regexSplit "\\." "$${context.res.id}" -1) 1 }}
      manifests: |
        service-account.yaml:
          location: namespace
          data:
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              {{if eq .init.name "cartservice" }}
              annotations:
                iam.gke.io/gcp-service-account: spanner-db-user-sa@mathieu-benoit-gcp.iam.gserviceaccount.com
              {{end}}
              name: {{ .init.name }}
      outputs: |
        name: {{ .init.name }}
criteria:
  - {}
EOF
yq -o json custom-sa.yaml > custom-sa.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
    -X POST \
  	-H "Content-Type: application/json" \
	  -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  	-d @custom-sa.json
```