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

## Deploy the Online Boutique Workloads

```bash
ENVIRONMENT=development
```

### All in once

```bash
WORKLOADS="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice redis shippingservice"
for w in ${WORKLOADS}; do score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml; done
```
_Note: should be optimized to just [generate 1 deployment by using this new feature](https://github.com/score-spec/score-humanitec/pull/38#issue-1652223070)._

### One by one

```bash
WORKLOAD=adservice #cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice redis shippingservice
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
