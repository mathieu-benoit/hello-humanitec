## Online Boutique

- [(Platform admin) Create the Online Boutique App in Humanitec](#platform-admin-create-the-online-boutique-app-in-humanitec)
- [(Developer) Deploy the Online Boutique Workloads in `development` Environment](#developer-deploy-the-online-boutique-workloads-in-development-environment)

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph gke-basic
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
        end
    end
    subgraph Resources
        custom-namespace>custom-namespace]
        custom-workload>custom-workload]
        gke-basic-connection>gke-basic-connection]
        memorystore-connection>memorystore-connection]
    end
  end
  subgraph Google Cloud
    direction TB
    subgraph gke-basic
        subgraph ingress-controller
            nginx{{nginx}}
        end
        subgraph onlineboutique
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
        end
        nginx-->frontend
    end
    gke-basic-connection-.->gke-basic
    memorystore-connection-.->memorystore[(memorystore)]
    onlineboutique-app-->onlineboutique
    cartservice-->memorystore
  end
  enduser((End user))-->frontend
```

## (Platform admin) Create the Online Boutique App in Humanitec

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

## (Developer) Deploy the Online Boutique Workloads in `development` Environment

```bash
ENVIRONMENT=development
WORKLOADS="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice redis shippingservice"
for w in ${WORKLOADS}; do score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f samples/onlineboutique/$w/score.yaml --extensions samples/onlineboutique/$w/humanitec.score.yaml; done
```