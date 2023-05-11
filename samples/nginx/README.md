## Create the Nginx App

As Platform admin, in Humanitec.

```bash
NGINX_APP=nginx
humctl create app ${NGINX_APP} \
    --context /orgs/${HUMANITEC_ORG} \
    --name ${NGINX_APP}
```

## Deploy the Sample Apps Workloads

As Developer, in Humanitec.

```bash
ENVIRONMENT=development
```

### All in once

```bash
COMBINED_DELTA=$(score-humanitec delta --app ${NGINX_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f nginx/score.yaml --extensions nginx/humanitec.score.yaml | jq -r .id)
COMBINED_DELTA=$(score-humanitec delta --app ${NGINX_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --delta ${COMBINED_DELTA} --retry -f nginx-unprivileged/score.yaml --extensions nginx-unprivileged/humanitec.score.yaml | jq -r .id)
score-humanitec delta \
    --app ${NGINX_APP} \
    --env ${ENVIRONMENT} \
    --org ${HUMANITEC_ORG} \
    --token ${HUMANITEC_TOKEN} \
    --deploy \
    --delta ${COMBINED_DELTA} \
    --retry \
    -f nginx-secured/score.yaml \
    --extensions nginx-secured/humanitec.score.yaml
```

### One by one

```bash
WORKLOAD=nginx #nginx-unprivileged nginx-secured
score-humanitec delta \
    --app ${NGINX_APP} \
    --env ${ENVIRONMENT} \
    --org ${HUMANITEC_ORG} \
    --token ${HUMANITEC_TOKEN} \
    --deploy \
    --retry \
    -f ${WORKLOAD}/score.yaml \
    --extensions ${WORKLOAD}/humanitec.score.yaml
```

## Get the public DNS exposing the Nginx Workloads

```bash
humctl get active-resources /orgs/${HUMANITEC_ORG}/apps/${NGINX_APP}/envs/${ENVIRONMENT}/resources \
    -o json \
    | jq -c '.[] | select(.object.type | contains("dns"))' \
    | jq -r .object.resource.host
```