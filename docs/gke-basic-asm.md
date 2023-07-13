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

## Issue with Istio setup

Current issue:
```
curl https://strosinbaumbachkoch.newapp.io/
curl: (7) Failed to connect to strosinbaumbachkoch.newapp.io port 443 after 133 ms: Connection refused
```

I think the issue comes with the fact that we need to configure the TLS certificate/termination at the `Gateway` level, in the shared `asm-ingress` namespace. The `Secret` with the TLS certificate is in the App/Env's namespace.

Typically, doing something like [this](https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/).

[See also the Gateway deployment topologies](https://istio.io/latest/docs/setup/additional-setup/gateway/#gateway-deployment-topologies).

I'm also not sure that the new Kubernetes's Gateway will solve that issue. Even with the notion of [`ReferenceGrant`](https://gateway-api.sigs.k8s.io/api-types/referencegrant/) meant for having the `Secret` in the App/Env's namespace, we still need to refer it and edit the `Gateway` in the share `asm-ingress` namespace.

I think the solution, like we have with the [GKE advanced setup](gke-advanced.md), is to have the certificate managed/terminated outside of the Kubernetes clusters, at the GCLB/Edge. Typically following [this setup](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress).



