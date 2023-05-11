## Create the Whereami App

As Platform admin, in Humanitec.

```bash
WHEREAMI_APP=whereami
humctl create app ${WHEREAMI_APP} \
	--context /orgs/${HUMANITEC_ORG} \
	--name ${WHEREAMI_APP}
```

## Deploy the Whereami Workload

As Developer, in Humanitec.

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
humctl get active-resources \
	--context /orgs/${HUMANITEC_ORG}/apps/${WHEREAMI_APP}/envs/${ENVIRONMENT} \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```