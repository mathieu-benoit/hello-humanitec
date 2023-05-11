## Create the Sample Apps App

As Platform admin, in Humanitec.

```bash
SAMPLE_APPS_APP=sample-apps
humctl create app ${SAMPLE_APPS_APP} \
	--context /orgs/${HUMANITEC_ORG} \
	--name ${SAMPLE_APPS_APP}
```

## Deploy the Sample Apps Workloads

As Developer, in Humanitec.

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
humctl get active-resources /orgs/${HUMANITEC_ORG}/apps/${SAMPLE_APPS_APP}/envs/${ENVIRONMENT}/resources \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```