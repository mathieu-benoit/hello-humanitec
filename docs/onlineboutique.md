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
        custom-workload>custom-workload]
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

## Humanitec App

```bash
ONLINEBOUTIQUE_APP=onlineboutique
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps \
  -X POST \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "id": "${ONLINEBOUTIQUE_APP}", 
  "name": "Online Boutique"
}
EOF
```

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
curl -X POST "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
  	-H "Content-Type: application/json" \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  	-d @custom-sa.json
```

## Memorystore (Redis) database

```bash
gcloud services enable redis.googleapis.com

REDIS_NAME=redis-cart
gcloud redis instances create ${REDIS_NAME} \
    --size 1 \
    --region ${REGION} \
    --zone ${ZONE} \
    --redis-version redis_6_x \
    --enable-auth
```

```bash
gcloud redis instances describe ${REDIS_NAME} \
   --region ${REGION} \
   --format 'get(host)'

gcloud redis instances describe ${REDIS_NAME} \
   --region ${REGION} \
   --format 'get(port)'

gcloud redis instances get-auth-string ${REDIS_NAME} \
   --region ${REGION}
```

FIXME - create a static Redis resource definition