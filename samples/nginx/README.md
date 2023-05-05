## Create the Nginx App

```bash
NGINX_APP=nginx
humctl create app /orgs/${HUMANITEC_ORG}/apps/${NGINX_APP} \
	--name ${NGINX_APP}
```

## Deploy the Sample Apps Workloads

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
	-f nginx/score.yaml \
	--extensions nginx/humanitec.score.yaml
```

## Get the public DNS exposing the Nginx Workloads

```bash
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${NGINX_APP}/envs/${ENVIRONMENT}/resources" \
	-s \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	| jq -c '.[] | select(.type | contains("dns"))' \
	| jq -r .resource.host
```