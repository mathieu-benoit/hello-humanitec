## Common setup

- [Custom Namespace resource definition](#custom-namespace-resource-definition)
- [Custom Workload resource definition](#custom-workload-resource-definition)

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph Resources
        custom-namespace>custom-namespace]
        custom-workload>custom-workload]
    end
  end
```

```bash
HUMANITEC_ORG=FIXME
HUMANITEC_TOKEN=FIXME
```

### Custom Namespace resource definition

FIXME - custom name, without the gsa/wi annotation yet

### Custom Workload resource definition

```bash
cat <<EOF > custom-workload.yaml
id: custom-workload
name: custom-workload
type: workload
driver_type: humanitec/template
driver_inputs:
  values:
    templates:
      outputs: |
        update:
          - op: add
            path: /spec/automountServiceAccountToken
            value: false
	        - op: add
            path: /spec/serviceAccountName
            value: ${resources.k8s-service-account.outputs.name}
          - op: add
            path: /spec/securityContext
            value:
              seccompProfile:
                type: RuntimeDefault
              runAsNonRoot: true
              fsGroup: 1000
              runAsGroup: 1000
              runAsUser: 1000
          {{- range \$containerId, \$value := .resource.spec.containers }}
          - op: add
            path: /spec/containers/{{ \$containerId }}/securityContext
            value:
              privileged: false
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities:
                drop:
                  - ALL
          {{- end }}
criteria:
  - {}
EOF
yq -o json custom-workload.yaml > custom-workload.json
curl -X POST "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
  	-H "Content-Type: application/json" \
	-H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  	-d @custom-workload.json
```
