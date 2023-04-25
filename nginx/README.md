```bash
NGINX_APP=nginx
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

## `nginx`

```bash
score-humanitec delta \
	--app ${NGINX_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f nginx/score.yaml \
	--extensions nginx/humanitec.score.yaml
```

## `nginx-unprivileged`

```bash
score-humanitec delta \
	--app ${NGINX_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy \
	--retry \
	-f nginx-unprivileged/score.yaml \
	--extensions nginx-unprivileged/humanitec.score.yaml
```
