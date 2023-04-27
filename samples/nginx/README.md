## Create the Nginx App

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

## Deploy the Sample Apps Workloads

```bash
ENVIRONMENT=development
```

### All in once

```bash
WORKLOADS="nginx nginx-unprivileged nginx-secured"
for w in ${WORKLOADS}; do score-humanitec delta --app ${NGINX_APP} --env ${ENVIRONMENT} --org ${HUMANITEC_ORG} --token ${HUMANITEC_TOKEN} --deploy --retry -f $w/score.yaml --extensions $w/humanitec.score.yaml; done
```

### Juste one

```bash
WORKLOAD=nginx #nginx-unprivileged nginx-secured
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
