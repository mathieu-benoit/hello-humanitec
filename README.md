# hello-humanitec

```
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
CLUSTER_NAME=gke-dev
REGION=northamerica-northeast1
ZONE=${REGION}-a
```

## Minimum setup:
```
gcloud services enable container.googleapis.com

gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --workload-pool=${PROJECT_ID}.svc.id.goog
```

## Advanced setup:
```
gcloud services enable container.googleapis.com
gcloud services enable containersecurity.googleapis.com

gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-workload-vulnerability-scanning \
    --enable-workload-config-audit
```
