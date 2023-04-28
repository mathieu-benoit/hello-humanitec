## Create the Sample Apps App

```bash
SAMPLE_APPS_APP=sample-apps
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps \
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
WORKLOADS="sample-app sample-service"
for w in ${WORKLOADS}; do score-humanitec delta --app ${SAMPLE_APPS_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml; done
```
_Note: should be optimized to just [generate 1 deployment by using this new feature](https://github.com/score-spec/score-humanitec/pull/38#issue-1652223070)._

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
