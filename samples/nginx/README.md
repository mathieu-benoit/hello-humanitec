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
_Note: should be optimized to just [generate 1 deployment by using this new feature](https://github.com/score-spec/score-humanitec/pull/38#issue-1652223070)._

### One by one

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
