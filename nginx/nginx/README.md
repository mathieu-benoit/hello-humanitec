```bash
NGINX_APP=whereami
curl https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps \
	-X POST \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
	-H "Content-Type: application/json" \
	-d @- <<EOF
{
  "id": "${NGINX_APP}", 
  "name": "${NGINX_APP}"
}
EOF
```

```bash
score-humanitec delta \
	--app ${NGINX_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f score.yaml \
	--extensions humanitec.score.yaml
```
