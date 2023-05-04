## Online Boutique

- [[PA-HUM] Create the Online Boutique App](#pa-hum-create-the-online-boutique-app)
- [[DE-HUM] Deploy the Online Boutique Workloads (with in-cluster `redis`) in `development` Environment](#de-hum-deploy-the-online-boutique-workloads-with-in-cluster-redis-in-development-environment)

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

```bash
HUMANITEC_ORG=FIXME
export HUMANITEC_TOKEN=FIXME
```

## [PA-HUM] Create the Online Boutique App

As Platform Admin, in Humanitec.

```bash
ONLINEBOUTIQUE_APP=onlineboutique
humctl create app /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}
```

<details>
  <summary>With curl.</summary>
  
  ```bash
  ONLINEBOUTIQUE_APP=onlineboutique
  curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps" \
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
</details>

## [DE-HUM] Deploy the Online Boutique Workloads (with in-cluster `redis`) in `development` Environment

As Developer, in Humanitec.

```bash
FIRST_WORKLOAD="adservice"
COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f ${FIRST_WORKLOAD}/score.yaml --extensions ${FIRST_WORKLOAD}/humanitec.score.yaml | jq -r .id)
WORKLOADS="cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice redis"
for w in ${WORKLOADS}; do COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --delta ${COMBINED_DELTA} --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml | jq -r .id); done
LAST_WORKLOAD="shippingservice"
score-humanitec delta \
	--app ${ONLINEBOUTIQUE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--delta ${COMBINED_DELTA} \
	--retry \
	-f ${LAST_WORKLOAD}/score.yaml \
	--extensions ${LAST_WORKLOAD}/humanitec.score.yaml
```
_Note: `loadgenerator` is deployed to generate both: traffic on these apps and data in the database. If you don't want this, feel free to remove it from the above list of `WORKLOADS`._

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

[_Next section: Common setup >>_](/docs/common.md)