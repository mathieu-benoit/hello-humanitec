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

## `sample-service`

```bash
score-humanitec delta \
	--app ${SAMPLE_APPS_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f sample-service/score.yaml \
	--extensions sample-service/humanitec.score.yaml
```
