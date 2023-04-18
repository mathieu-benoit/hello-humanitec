# hello-humanitec

## Sample Apps

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
        direction LR
        subgraph sample-apps
            direction LR
            sample-app-workload[sample-app]
            sample-service-workload[sample-service]
        end
    end
    subgraph Resources
        custom-namespace
        gke-dev-connection
    end
  end
  subgraph GCP
    direction TB
    subgraph GKE-dev
        subgraph ingress-controller
            nginx
        end
        subgraph sample-apps-dev
            sample-app-->sample-service
        end
        nginx-->sample-app
    end
    sample-service-->cloud-sql-dev
  end
  sample-apps-->sample-apps-dev
  gke-dev-connection-.->GKE-dev
```

## Online Boutique

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
        direction LR
        subgraph onlineboutique-app
            direction LR
            adservice-workload[adservice]
            cartservice-workload[cartservice]
            checkoutservice-workload[checkoutservice]
            currencyservice-workload[currencyservice]
            emailservice-workload[emailservice]
            frontend-workload[frontend]
            paymentservice-workload[paymentservice]
            productcatalogservice-workload[productcatalogservice]
            recommendationservice-workload[recommendationservice]
            shippingservice-workload[shippingservice]
            redis-workload[redis]
        end
    end
    subgraph Resources
        custom-namespace
        gke-dev-connection
        memorystore-dev-connection
    end
  end
  subgraph GCP
    direction TB
    subgraph GKE-dev
        subgraph ingress-controller
            nginx
        end
        subgraph onlineboutique-dev
            frontend-->adservice
            frontend-->checkoutservice
            frontend-->currencyservice
            checkoutservice-->emailservice
            checkoutservice-->paymentservice
            checkoutservice-->currencyservice
            checkoutservice-->shippingservice
            checkoutservice-->productcatalogservice
            checkoutservice-->cartservice
            frontend-->cartservice
            frontend-->cartservice
            cartservice-->redis
            recommendationservice-->productcatalogservice
        end
        nginx-->frontend
    end
    gke-dev-connection-.->GKE-dev
    memorystore-dev-connection-.->memorystore-dev
    onlineboutique-app-->onlineboutique-dev
    cartservice-->memorystore-dev
    cartservice-->spanner-dev
  end
```

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
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-master-authorized-networks \
    --master-authorized-networks 34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32 \
    --no-enable-google-cloud-access
```

## Advanced setup:
```
gcloud services enable container.googleapis.com
gcloud services enable containersecurity.googleapis.com

gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-master-authorized-networks \
    --master-authorized-networks 34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32 \
    --no-enable-google-cloud-access \
    --enable-workload-vulnerability-scanning \
    --enable-workload-config-audit
```
