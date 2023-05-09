# hello-humanitec

2 personas:
- **Platform admin** (PA) interacting with either Google Cloud (**PA-GCP**) or Humanitec (**PA-HUM**)
- **Developer** (DE) interacting with Humanitec (**DE-HUM**)

![personas](/images/personas.png)

Agenda:
- [Humanitec default setup](./docs/humanitec-default.md)
  - [PA-HUM] Create Online Boutique App
  - [PA-HUM] Create an in-cluster Redis database
  - [DE-HUM] Deploy Online Boutique Workloads in `development` Environment
- [Common setup](./docs/common.md)
  - [PA-HUM] Create custom name `Namespace`
  - [PA-HUM] Create custom `ServiceAccount`
  - [PA-HUM] Create custom unprivileged Workload
- [GKE basic setup](./docs/gke-basic.md)
  - [PA-GCP] Create basic GKE setup
  - [PA-GCP] Deploy a simple Nginx Ingress controller
  - [PA-HUM] Create `gke-basic` Environment
  - [PA-GCP] Create a Memorystore (Redis) database
  - [PA-HUM] Deploy the new `gke-basic` Environment
- [GKE advanced setup - _under construction_](./docs/gke-advanced.md)
  - [PA-GCP] Create advanced and secured GKE setup
  - [PA-GCP] Deploy an Nginx Ingress controller
  - [PA-GCP] Protect the Nginx Ingress controller behind a Global Cloud Load Balancer (GCLB) and Cloud Armor (WAF)
  - [PA-GCP] Use Cloud Logging for Workload's logs
  - [PA-HUM] Create `gke-advanced` Environment
  - [PA-GCP] Create a Spanner database
  - [PA-GCP] Create Kubernetes and Google Service Accounts to access Spanner via Workload Identity
  - [PA-HUM] Deploy the new `gke-advanced` Environment


Backlog and future considerations:
- Azure setup
- Sample Apps with PostreSQL
- Istio Service Mesh
- Dynamic infra (databases) provisioning via Humanitec and Terraform