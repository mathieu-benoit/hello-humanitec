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

```yaml
id: "${context.res.id}"

virtual-service.yaml:
  location: namespace
  data:
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      name: ${context.res.id}
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

Annotate onlineboutique ns

Redeploy
