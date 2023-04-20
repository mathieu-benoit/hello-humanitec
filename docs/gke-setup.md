```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
    end
    subgraph Resources
        gke-dev-connection>gke-dev-connection]
    end
  end
  subgraph Google Cloud
    direction TB
    gke-admin-gsa[\gke-admin-gsa/]
    subgraph GKE-dev
        subgraph ingress-controller
            nginx{{nginx}}
        end
    end
  end
  gke-dev-connection-.->gke-admin-gsa
  gke-admin-gsa-.->GKE-dev
```

```bash
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
CLUSTER_NAME=gke-dev
REGION=northamerica-northeast1
ZONE=${REGION}-a
```



## GKE cluster
```bash
gcloud services enable container.googleapis.com

gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --scopes cloud-platform \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-master-authorized-networks \
    --master-authorized-networks 34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32 \
    --no-enable-google-cloud-access
```

Other options:
```bash
gcloud services enable containersecurity.googleapis.com

--enable-workload-vulnerability-scanning \
--enable-workload-config-audit
```

## Ingress controller

Deploy the Ingress Controller:
```bash
kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml
```

Let’s grab the Public IP address of that Ingress Controller:
```bash
INGRESS_IP=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
```

## GSA to access GKE

```bash
SA_NAME=humanitec-dev
SA_ID=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${SA_NAME} \
	--display-name=${SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member "serviceAccount:${SA_ID}" \
	--role "roles/container.admin"
```

Let’s download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${SA_NAME}.json \
    --iam-account ${SA_ID}
```

## Create the GKE connection in Humanitec

```
HUMANITEC_ORG=FIXME
HUMANITEC_TOKEN=FIXME
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs \
  -X POST \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "
{
  "id": "my-cluster",
  "name": "My Cluster",
  "type": "k8s-cluster",
  "criteria": [
    {
      "env_type": "development"
    }
  ],
  "driver_type": "humanitec/k8s-cluster-gke",
  "driver_inputs": {
    "values": {
      "loadbalancer": ${INGRESS_IP}
      "name": ${CLUSTER_NAME}
      "project_id":${PROJECT_ID}
      "zone": ${ZONE}
    },
    "secrets": {
      "credentials": $(cat ${SA_NAME}.json)
    }
  }
}"
```
