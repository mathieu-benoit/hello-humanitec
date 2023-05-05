## Create the Whereami App

```bash
WHEREAMI_APP=whereami
humctl create app /orgs/${HUMANITEC_ORG}/apps/${WHEREAMI_APP} \
	--name ${WHEREAMI_APP}
```

## Deploy the Whereami Workload

```bash
ENVIRONMENT=development
```

```bash
score-humanitec delta \
	--app ${WHEREAMI_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f score.yaml \
	--extensions humanitec.score.yaml
```

## Get the public DNS exposing the Whereami Workload

```bash
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/${WHEREAMI_APP}/envs/${ENVIRONMENT}/resources" \
	-s \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	| jq -c '.[] | select(.type | contains("dns"))' \
	| jq -r .resource.host
```