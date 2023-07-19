[_Next section: Common setup >>_](/docs/common.md)

## Humanitec default setup in Development

- [[PE-HUM] Create the Online Boutique App](#pe-hum-create-the-online-boutique-app)
- [[PE-HUM] Create the in-cluster Redis resource definition](#pe-hum-create-the-in-cluster-redis-resource-definition)
- [[DE-HUM] Deploy the Online Boutique Workloads in Development Environment](#de-hum-deploy-the-online-boutique-workloads-in-development-environment)
- [Test the Online Boutique website](#test-the-online-boutique-website)

```mermaid
flowchart LR
  subgraph Humanitec
    direction LR
    subgraph onlineboutique-app [Online Boutique App]
        subgraph Development
          direction LR
          cartservice-workload([cartservice])
          frontend-workload([frontend])
        end
    end
    subgraph Resources
        redis-cart-connection>redis-cart-connection]
    end
  end
  subgraph cloud [Humanitec's Cloud]
      direction LR
      subgraph onlineboutique
          frontend{{frontend}}-->cartservice{{cartservice}}
          cartservice-->redis-cart-db[(redis-cart)]
      end
  end
  onlineboutique-app-.->onlineboutique
  redis-cart-connection-.->redis-cart-db
  enduser((End user))-->frontend
```

```bash
HUMANITEC_ORG=FIXME
export HUMANITEC_CONTEXT=/orgs/${HUMANITEC_ORG}
export HUMANITEC_TOKEN=FIXME

ENVIRONMENT=development
```

Before starting, let's clone this current GitHub repository, you will need to have the files locally:
```bash
git clone https://github.com/mathieu-benoit/hello-humanitec
cd hello-humanitec/
```

## [PE-HUM] Create the Online Boutique App

As Platform Engineer, in Humanitec.

```bash
ONLINEBOUTIQUE_APP=onlineboutique
humctl create app ${ONLINEBOUTIQUE_APP} \
    --name ${ONLINEBOUTIQUE_APP}
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

## [PE-HUM] Create the in-cluster Redis resource definition

As Platform Engineer, in Humanitec.

Create the in-cluster Redis resource definition:
```bash
cat <<EOF > redis-in-cluster.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: redis-in-cluster
object:
  name: redis-in-cluster
  type: redis
  driver_type: humanitec/template
  driver_inputs:
    values:
      templates:
        init: |-
          name: redis
          port: 6379
        manifests: |-
          deployment.yaml:
            location: namespace
            data:
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: {{ .init.name }}
              spec:
                selector:
                  matchLabels:
                    app: {{ .init.name }}
                template:
                  metadata:
                    labels:
                      app: {{ .init.name }}
                  spec:
                    securityContext:
                      fsGroup: 1000
                      runAsGroup: 1000
                      runAsNonRoot: true
                      runAsUser: 1000
                      seccompProfile:
                        type: RuntimeDefault
                    containers:
                    - name: {{ .init.name }}
                      securityContext:
                        allowPrivilegeEscalation: false
                        capabilities:
                          drop:
                            - ALL
                        privileged: false
                        readOnlyRootFilesystem: true
                      image: redis:alpine
                      ports:
                      - containerPort: {{ .init.port }}
                      volumeMounts:
                      - mountPath: /data
                        name: redis-data
                    volumes:
                    - name: redis-data
                      emptyDir: {}
          service.yaml:
            location: namespace
            data:
              apiVersion: v1
              kind: Service
              metadata:
                name: {{ .init.name }}
              spec:
                type: ClusterIP
                selector:
                  app: {{ .init.name }}
                ports:
                - name: tcp-redis
                  port: {{ .init.port }}
                  targetPort: {{ .init.port }}
        outputs: |
          host: {{ .init.name }}
          port: {{ .init.port }}
  criteria:
    - {}
EOF
humctl create \
    -f redis-in-cluster.yaml
```

## [DE-HUM] Deploy the Online Boutique Workloads in Development Environment

As Developer, in Humanitec.

### On Linux

```bash
FIRST_WORKLOAD="adservice"
COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f samples/onlineboutique/${FIRST_WORKLOAD}/score.yaml --extensions samples/onlineboutique/${FIRST_WORKLOAD}/humanitec.score.yaml | jq -r .id)
WORKLOADS="cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
for w in ${WORKLOADS}; do \
    COMBINED_DELTA=$(score-humanitec delta \
        --app ${ONLINEBOUTIQUE_APP} \
        --env ${ENVIRONMENT} \
        --org ${HUMANITEC_ORG} \
        --token ${HUMANITEC_TOKEN} \
        --delta ${COMBINED_DELTA} \
        --retry \
        -f samples/onlineboutique/$w/score.yaml \
        --extensions samples/onlineboutique/$w/humanitec.score.yaml \
        | jq -r .id); \
done
humctl deploy delta ${COMBINED_DELTA} ${ENVIRONMENT} \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}
```

### On MacOS

```
FIRST_WORKLOAD="adservice"
COMBINED_DELTA=$(score-humanitec delta --app ${ONLINEBOUTIQUE_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f samples/onlineboutique/${FIRST_WORKLOAD}/score.yaml --extensions samples/onlineboutique/${FIRST_WORKLOAD}/humanitec.score.yaml | jq -r .id)
WORKLOADS=(cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice)
for ((i = 1; i < ${#WORKLOADS[@]}; i++)); do \
    COMBINED_DELTA=$(score-humanitec delta \
        --app ${ONLINEBOUTIQUE_APP} \
        --env ${ENVIRONMENT} \
        --org ${HUMANITEC_ORG} \
        --token ${HUMANITEC_TOKEN} \
        --delta ${COMBINED_DELTA} \
        --retry \
        -f samples/onlineboutique/${WORKLOADS[$i]}/score.yaml \
        --extensions samples/onlineboutique/${WORKLOADS[$i]}/humanitec.score.yaml \
        | jq -r .id); \
done
humctl deploy delta ${COMBINED_DELTA} ${ENVIRONMENT} \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}
```

_Note: `loadgenerator` is deployed to generate both: traffic on these apps and data in the database. If you don't want this, feel free to remove it from the above list of `WORKLOADS`._

## Test the Online Boutique website

Get the public DNS exposing the `frontend` Workload:
```bash
echo -e "https://$(humctl get active-resources \
    --context /orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT} \
    -o json \
    | jq -c '.[] | select(.object.type | contains("dns"))' \
    | jq -r .object.resource.host)"
```
<details>
  <summary>With curl.</summary>
  
  ```bash
  echo -e "https://$(curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT}/resources" \
      -s \
      -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
      -H "Content-Type: application/json" \
      | jq -c '.[] | select(.type | contains("dns"))' \
      | jq -r .resource.host)"
  ```
</details>

_Note: re-run the above command until you get a value._

[_Next section: Common setup >>_](/docs/common.md)
