## Create the Online Boutique App

```bash
ONLINEBOUTIQUE_APP=onlineboutique
humctl create app ${ONLINEBOUTIQUE_APP} \
	--context /orgs/${HUMANITEC_ORG} \
	--name ${ONLINEBOUTIQUE_APP}
```

## Deploy the Online Boutique Workloads

```bash
ENVIRONMENT=development
```

### All in once

```bash
FIRST_WORKLOAD="adservice"
COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f ${FIRST_WORKLOAD}/score.yaml --extensions ${FIRST_WORKLOAD}/humanitec.score.yaml | jq -r .id)
WORKLOADS="cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice"
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

### One by one

```bash
WORKLOAD=adservice #cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice
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

## Deploy the Online Boutique `redis-cart` database

_This section is dedicated to the Platform admin, not the Developer._

### Deploy the `redis-cart` database

```bash
REDIS_NAME=redis-cart
```

3 options:

- `redis-cart` as Workload:

```bash
score-humanitec delta \
	--app ${ONLINEBOUTIQUE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f ${REDIS_NAME}/score.yaml \
	--extensions ${REDIS_NAME}/humanitec.score.yaml
```

- `redis-cart` as Kubernetes `Deployment`:

```bash
kubectl apply \
	-f ${REDIS_NAME}/${REDIS_NAME}.yaml \
	-n ${ENVIRONMENT}-${ONLINEBOUTIQUE_APP}
```

- `redis-cart` as Resource type:

FIXME - _Coming soon... stay tuned!_

## Create the `redis-cart` connection string resource definition

```bash
REDIS_PORT=6379
cat <<EOF > ${REDIS_NAME}-${ENVIRONMENT}.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${REDIS_NAME}-${ENVIRONMENT}
object:
  name: ${REDIS_NAME}-${ENVIRONMENT}
  type: redis
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${REDIS_NAME}
      port: ${REDIS_PORT}
  criteria:
    - env_id: ${ENVIRONMENT}
EOF
humctl create \
    -f ${REDIS_NAME}-${ENVIRONMENT}.yaml
```

## Get the public DNS exposing the `frontend` Workloads

```bash
humctl get active-resources /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT}/resources \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```