## Create the Online Boutique App

```bash
ONLINEBOUTIQUE_APP=onlineboutique
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps \
	-X POST \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	-d @- <<EOF
{
  "id": "${ONLINEBOUTIQUE_APP}", 
  "name": "${ONLINEBOUTIQUE_APP}"
}
EOF
```

## Deploy all the Workloads

### All in once

```bash
WORKLOADS="adservice cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice shippingservice"
FOR w in $WORKLOADS; DO score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml; DONE 
```

### Juste one

```bash
WORKLOAD=adservice
score-humanitec delta \
	--app ${ONLINEBOUTIQUE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f ${WORKLOAD}/score.yaml \
	--extensions ${WORKLOAD}/humanitec.score.yaml
```
