## Create the Sample Score App

As Platform admin, in Humanitec.

```bash
SAMPLE_SCORE_APP=sample-score-app
humctl create app ${SAMPLE_SCORE_APP} \
	--context /orgs/${HUMANITEC_ORG} \
	--name ${SAMPLE_SCORE_APP}
```

## Deploy the Sample Score Workload

As Developer, in Humanitec.

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
humctl get active-resources \
	--context /orgs/${HUMANITEC_ORG}/apps/${SAMPLE_SCORE_APP}/envs/${ENVIRONMENT} \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```