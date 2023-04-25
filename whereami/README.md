```bash
WHEREAMI_APP=whereami
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps \
  -X POST \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "id": "${WHEREAMI_APP}", 
  "name": "${WHEREAMI_APP}"
}
EOF
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
