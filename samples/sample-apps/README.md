## Create the Sample Apps App

```bash
SAMPLE_APPS_APP=sample-apps
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps" \
	-X POST \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	-d @- <<EOF
{
  "id": "${SAMPLE_APPS_APP}", 
  "name": "${SAMPLE_APPS_APP}"
}
EOF
```

## Deploy the Sample Apps Workloads

```bash
ENVIRONMENT=development
```

### All in once

```bash
COMBINED_DELTA=$(score-humanitec delta --app ${SAMPLE_APPS_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --retry -f sample-app/score.yaml --extensions sample-app/humanitec.score.yaml | jq -r .id)
score-humanitec delta \
	--app ${SAMPLE_APPS_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--delta ${COMBINED_DELTA} \
	--retry \
	-f sample-service/score.yaml \
	--extensions sample-service/humanitec.score.yaml
```

### One by one

```bash
WORKLOAD=sample-app #sample-service
score-humanitec delta \
	--app ${SAMPLE_APPS_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f ${WORKLOAD}/score.yaml \
	--extensions ${WORKLOAD}/humanitec.score.yaml
```

## Get the public DNS exposing the Sample App Workload

```bash
curl -s "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${SAMPLE_APPS_APP}/envs/${ENVIRONMENT}/resources" \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	| jq -c '.[] | select(.type | contains("dns"))' \
	| jq -r .resource.host
```