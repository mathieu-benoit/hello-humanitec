Deploying the Online Boutique sample apps in Humanitec consists in 4 main steps:
- [Create the Online Boutique App](#create-the-online-boutique-app)
- [Deploy the Online Boutique `redis-cart` database](#deploy-the-online-boutique-redis-cart-database)
- [Deploy the Online Boutique Workloads](#deploy-the-online-boutique-workloads)
- [Enjoy!](#test-the-online-boutique-website)

## Create the Online Boutique App

As Platform Admin, in Humanitec.

```bash
ONLINEBOUTIQUE_APP=onlineboutique
humctl create app ${ONLINEBOUTIQUE_APP} \
	--context /orgs/${HUMANITEC_ORG} \
	--name ${ONLINEBOUTIQUE_APP}
```

```bash
ENVIRONMENT=development
```

## Deploy the Online Boutique `redis-cart` database

As Platform Admin, in Humanitec.

```bash
REDIS_NAME=redis-cart
REDIS_PORT=6379
cat <<EOF > ${REDIS_NAME}-in-cluster.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${REDIS_NAME}-in-cluster
object:
  name: ${REDIS_NAME}-in-cluster
  type: redis
  driver_type: humanitec/template
  driver_inputs:
    values:
      templates:
        manifests: |-
          deployment.yaml:
            location: namespace
            data:
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: ${REDIS_NAME}
              spec:
                selector:
                  matchLabels:
                    app: ${REDIS_NAME}
                template:
                  metadata:
                    labels:
                      app: ${REDIS_NAME}
                  spec:
                    containers:
                    - name: redis
                      image: redis:alpine
                      ports:
                      - containerPort: ${REDIS_PORT}
          service.yaml:
            location: namespace
            data:
              apiVersion: v1
              kind: Service
              metadata:
                name: ${REDIS_NAME}
              spec:
                type: ClusterIP
                selector:
                  app: ${REDIS_NAME}
                ports:
                - name: tcp-redis
                  port: ${REDIS_PORT}
                  targetPort: ${REDIS_PORT}
        outputs: |
          host: ${REDIS_NAME}
          port: ${REDIS_PORT}
  criteria:
    - {}
EOF
humctl create \
	-f ${REDIS_NAME}-in-cluster.yaml
```

<details>
  <summary>Alternative with redis-cart as Workload.</summary>

  Deploy the `redis-cart` database as a Workload:
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

  Create the `redis-cart` connection string resource definition:
  ```bash
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
</details>

## Deploy the Online Boutique Workloads

As Developer, in Humanitec.

### All in once

```bash
FIRST_WORKLOAD="adservice"
COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f ${FIRST_WORKLOAD}/score.yaml --extensions ${FIRST_WORKLOAD}/humanitec.score.yaml | jq -r .id)
WORKLOADS="cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
for w in ${WORKLOADS}; do COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --delta ${COMBINED_DELTA} --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml | jq -r .id); done
humctl deploy delta ${COMBINED_DELTA} ${ENVIRONMENT} \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}
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

## Test the Online Boutique website

Get the public DNS exposing the `frontend` Workloads:
```bash
humctl get active-resources \
	--context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT} \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```
