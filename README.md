# hello-humanitec

- [Humanitec default setup](./docs/humanitec-default.md)
  - (Platform admin) Create Online Boutique App
  - (Developer) Deploy Online Boutique Workloads (in-cluster `redis`) in `development` Environment
- [Common setup](./docs/common.md)
  - (Platform admin) Create custom name `Namespace`
  - (Platform admin) Create custom unprivilged Workload
- [GKE basic setup](./docs/gke-basic.md)
  - (Platform admin) Create basic GKE setup
  - (Platform admin) Deploy a simple Nginx Ingress controller
  - (Platform admin) Create `gke-basic` Environment
  - (Platform admin) Create a Memorystore (Redis) database
  - (Developer) Deploy `cartservice` Workload connecting to Memorystore (Redis) database in `gke-basic` Environment
- [GKE advanced setup](./docs/gke-advanced.md)
  - (Platform admin) Create advanced and secured GKE setup
  - (Platform admin) Deploy an Nginx Ingress controller
  - (Platform admin) Protect the Nginx Ingress controller behind a Global Cloud Load Balancer (GCLB) and Cloud Armor (WAF)
  - (Platform admin) Create `gke-advanced` Environment
  - (Platform admin) Create a Spanner database
  - (Platform admin) Create Kubernetes and Google Service Accounts to access Spanner via Workload Identity
  - (Developer) Deploy `cartservice` Workload connecting to Memorystore (Redis) database in `gke-advanced` Environment


Backlog and future considerations:
- Azure setup
- Sample Apps with PostreSQL
- Istio Service Mesh
- Dynamic infra (databases) provisioning via Humanitec and Terraform