## Common setup

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph development
    end
    subgraph staging
    end
    subgraph production
    end
    subgraph Resources
        custom-namespace>custom-namespace]
        custom-sa>custom-sa]
        custom-workload>custom-workload]
	logging-connection>logging-connection]
    end
  end
  subgraph Google Cloud
    direction TB
    logging-reader-gsa[\logging-reader-gsa/]
  end
  logging-connection-.->logging-reader-gsa
  logging-reader-gsa-.->cloud-logging
```

```bash
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
```

### GSA to access Cloud Logging

```bash
LOGGING_READER_SA_NAME=humanitec-logging-dev
LOGGING_READER_SA_ID=${LOGGING_READER_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${LOGGING_READER_SA_NAME} \
	--display-name=${LOGGING_READER_SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member "serviceAccount:${LOGGING_READER_SA_ID}" \
	--role "roles/logging.viewer"
```

Let’s download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${LOGGING_READER_SA_NAME}.json \
    --iam-account ${LOGGING_READER_SA_ID}
```
