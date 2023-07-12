WORK IN PROGRESS - NOT READY - ROUGH DRAFT MODE

# GKE basic setup with ASM/Istio in Staging

```bash
gcloud container fleet memberships register ${CLUSTER_NAME} \
    --gke-cluster ${ZONE}/${CLUSTER_NAME} \
    --enable-workload-identity

gcloud services enable anthos.googleapis.com \
    mesh.googleapis.com

gcloud container fleet mesh enable

gcloud container fleet mesh update \
    --management automatic \
    --memberships ${CLUSTER_NAME}
```

```bash
gcloud container fleet mesh describe
```

```bash
kubectl apply -f samples/asm-ingressgateway/namespace.yaml
kubectl apply -f samples/asm-ingressgateway/
```

```bash
k get svc -n asm-ingress
```

## Create a custom Ingress template:

For `init`:
```yaml
id: {{ index (regexSplit "\\." "$${context.res.id}" -1) 1 }}
```

For `manifests`:
```yaml
virtual-service.yaml:
  location: namespace
  data:
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      name: {{ .init.id }}
      namespace: {{ .resource.namespace }}
    spec:
      hosts:
      {{- range $i, $host := (splitList ";" .resource.host ) }}
      - {{ $host }}
      {{- end }}
      gateways:
      - asm-ingress/asm-ingressgateway
      http:
      {{- range $path, $param := .resource.rules.http }}
      - route:
        - destination:
            host: {{ $param.name }}
            port:
              number: {{ $param.port }}
        {{- if not (eq $path "*") }}
          match:
            - uri:
                prefix: {{ $path }}
        {{- end}}
      {{- end }}
```

Current issue:
```
curl https://strosinbaumbachkoch.newapp.io/
curl: (7) Failed to connect to strosinbaumbachkoch.newapp.io port 443 after 133 ms: Connection refused
```

I even tried with:
```
host: '*'
```
Or:
```
    tls:
    - match:
      - port: 443
        sniHosts:
        - '*'
      route:
      - destination:
          host: frontend
          port:
            number: 80
```

Some investigations:
- https://ibm.github.io/cloud-native-starter-security-workshop/app-env-exercise-01/SETUP_ISTIO_INGRESS_TLS/
- https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/
- https://istio.io/latest/docs/ops/deployment/requirements/

Annotate onlineboutique ns

Redeploy
