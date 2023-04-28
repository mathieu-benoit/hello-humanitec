## Online Boutique

- [(Platform admin) Create the Online Boutique App in Humanitec](#create-the-online-boutique-app-in-humanitec)
- [(Developer) Deploy the Online Boutique Workloads in `development` Environment](#deploy-the-online-boutique-workloads-in-development-environment)

```mermaid
flowchart LR
  subgraph Humanitec
    direction LR
    subgraph onlineboutique [Online Boutique App]
        direction LR
        adservice-workload([adservice])
        cartservice-workload([cartservice])
        checkoutservice-workload([checkoutservice])
        currencyservice-workload([currencyservice])
        emailservice-workload([emailservice])
        frontend-workload([frontend])
        loadgenerator-workload([loadgenerator])
        paymentservice-workload([paymentservice])
        productcatalogservice-workload([productcatalogservice])
        recommendationservice-workload([recommendationservice])
        shippingservice-workload([shippingservice])
        redis-workload([redis])
    end
  end
  subgraph cloud [Humanitec's Cloud]
      direction LR
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
      loadgenerator{{loadgenerator}}-->frontend
      recommendationservice{{recommendationservice}}-->productcatalogservice
      cartservice-->redis[(redis)]
  end
  Humanitec-->cloud
  enduser((End user))-->frontend
```

## Create the Online Boutique App in Humanitec

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

## Deploy the Online Boutique Workloads in `development` Environment

```bash
ENVIRONMENT=development
WORKLOADS="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice redis shippingservice"
for w in ${WORKLOADS}; do score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f samples/onlineboutique/$w/score.yaml --extensions samples/onlineboutique/$w/humanitec.score.yaml; done
```