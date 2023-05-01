## Create the Sample Score App

```bash
SAMPLE_SCORE_APP=sample-score-app
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps" \
	-X POST \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	-d @- <<EOF
{
  "id": "${SAMPLE_SCORE_APP}", 
  "name": "${SAMPLE_SCORE_APP}"
}
EOF
```

## Deploy the Sample Score Workload

```bash
ENVIRONMENT=development
```

```bash
score-humanitec delta \
	--app ${SAMPLE_SCORE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f score.yaml \
	--extensions humanitec.score.yaml
```

## Get the public DNS exposing the Sample Score Workload

```bash
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${SAMPLE_SCORE_APP}/envs/${ENVIRONMENT}/resources" \
	-s \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	| jq -c '.[] | select(.type | contains("dns"))' \
	| jq -r .resource.host
```