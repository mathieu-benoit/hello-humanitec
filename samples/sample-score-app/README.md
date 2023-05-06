## Create the Sample Score App

```bash
SAMPLE_SCORE_APP=sample-score-app
humctl create app /orgs/${HUMANITEC_ORG}/apps/${SAMPLE_SCORE_APP} \
	--name ${SAMPLE_SCORE_APP}
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
humctl get active-resources /orgs/${HUMANITEC_ORG}/apps/${SAMPLE_SCORE_APP}/envs/${ENVIRONMENT}/resources \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
    | jq -r .object.resource.host
```