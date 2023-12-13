Repo now archived, not maintained, and content now splitted:
- https://github.com/Humanitec-DemoOrg/onlineboutique-demo
- https://github.com/Humanitec-DemoOrg/google-cloud-reference-architecture
- https://github.com/Humanitec-DemoOrg/azure-reference-architecture

# hello-humanitec

2 personas:
- **Platform Engineer** (PE) interacting with either Google Cloud (**PE-GCP**), Azure (**PE-AZ**) or Humanitec (**PE-HUM**)
- **Developer** (DE) interacting with Humanitec (**DE-HUM**)

![personas](/images/personas.png)

Agenda:
- [Humanitec default setup in Development](./docs/humanitec-default.md)
  - [PE-HUM] Create Online Boutique App
  - [PE-HUM] Create an in-cluster Redis database
  - [DE-HUM] Deploy Online Boutique Workloads in the Development Environment
- [Common setup](./docs/common.md)
  - [PE-HUM] Create `staging` and `production` Environment types
  - [PE-HUM] Create custom name `Namespace`
  - [PE-HUM] Create custom `ServiceAccount`
  - [PE-HUM] Create custom unprivileged Workload
- [GKE basic setup in Staging](./docs/gke-basic.md)
  - [PE-GCP] Create basic GKE setup
  - [PE-GCP] Deploy a simple Nginx Ingress controller
  - [PE-HUM] Create Staging Environment
  - [PE-GCP] Create a Memorystore (Redis) database
  - [PE-HUM] Deploy the Staging Environment
- [AKS basic setup in Staging](./docs/aks-basic.md)
  - [PE-AZ] Create basic AKS setup
  - [PE-AZ] Deploy a simple Nginx Ingress controller
  - [PE-HUM] Create Staging Environment
  - [PE-AZ] Create a Memorystore (Redis) database
  - [PE-HUM] Deploy the Staging Environment
- [GKE advanced setup in Production](./docs/gke-advanced.md)
  - [PE-GCP] Create advanced and secured GKE setup
  - [PE-GCP] Deploy an Nginx Ingress controller
  - [PE-GCP] Protect the Nginx Ingress controller behind a Global Cloud Load Balancer (GCLB) and Cloud Armor (WAF)
  - [PE-GCP] Use Cloud Logging for Workload's logs
  - [PE-HUM] Create Production Environment
  - [PE-GCP] Create a Spanner database
  - [PE-GCP] Create Kubernetes and Google Service Accounts to access Spanner via Workload Identity
  - [DE-HUM] Deploy `cartservice` Workload connected to the Spanner database in the Production Environment


Backlog and future considerations:
- Azure advanced setup
- Sample Apps with PostreSQL
- Istio Service Mesh
- Dynamic infra (databases) provisioning via Humanitec and Terraform
- `NetworkPolicies`
- Terraform snippets in addition to the existing CLI commands
