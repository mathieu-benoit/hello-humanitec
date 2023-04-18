# hello-humanitec

## Sample Apps

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
        direction LR
        subgraph sample-apps
            direction LR
            sample-app-workload([sample-app])
            sample-service-workload([sample-service])
        end
    end
    subgraph Resources
        custom-namespace>custom-namespace]
        gke-dev-connection>gke-dev-connection]
    end
  end
  subgraph Google Cloud
    direction TB
    subgraph GKE-dev
        subgraph ingress-controller
            nginx{{nginx}}
        end
        subgraph sample-apps-dev
            sample-app{{sample-app}}-->sample-service{{sample-service}}
        end
        nginx-->sample-app
    end
    sample-service-->cloud-sql-dev[(cloud-sql-dev)]
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
            adservice-workload([adservice])
            cartservice-workload([cartservice])
            checkoutservice-workload([checkoutservice])
            currencyservice-workload([currencyservice])
            emailservice-workload([emailservice])
            frontend-workload([frontend])
            paymentservice-workload([paymentservice])
            productcatalogservice-workload([productcatalogservice])
            recommendationservice-workload([recommendationservice])
            shippingservice-workload([shippingservice])
            redis-workload([redis])
        end
    end
    subgraph Resources
        custom-namespace>custom-namespace]
        gke-dev-connection>gke-dev-connection]
        memorystore-dev-connection>memorystore-dev-connection]
    end
  end
  subgraph Google Cloud
    direction TB
    subgraph GKE-dev
        subgraph ingress-controller
            nginx{{nginx}}
        end
        subgraph onlineboutique-dev
            frontend{{frontend}}-->adservice{{adservice}}
            frontend-->checkoutservice{{checkoutservice}}
            frontend-->currencyservice{{currencyservice}}
            checkoutservice-->emailservice{{emailservice}}
            checkoutservice-->paymentservice{{paymentservice}}
            checkoutservice-->currencyservice
            checkoutservice-->shippingservice{{shippingservice}}
            checkoutservice-->productcatalogservice{{productcatalogservice}}
            checkoutservice-->cartservice{{cartservice}}
            frontend-->cartservice
            recommendationservice{{recommendationservice}}-->productcatalogservice
            cartservice-.->cartservice-ksa[/cartservice-ksa\]
            cartservice-->redis[(redis)]
        end
        nginx-->frontend
    end
    gke-dev-connection-.->GKE-dev
    memorystore-dev-connection-.->memorystore-dev[(memorystore-dev)]
    onlineboutique-app-->onlineboutique-dev
    cartservice-->memorystore-dev
    spanner-reader-gsa-->spanner-dev[(spanner-dev)]
    cartservice-ksa-->spanner-reader-gsa[\spanner-reader-gsa/]
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
