## Common setup

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
    end
    subgraph Resources
        custom-namespace>custom-namespace]
        custom-sa>custom-sa]
        custom-workload>custom-workload]
    end
  end
  subgraph Google Cloud
    gke-admin-gsa
  end
```
