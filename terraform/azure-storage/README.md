## Test the Azure Storage Terraform locally

```bash
terraform init
terraform plan -var-file terraform.tfvars.example
```

## Deploy the Azure Storage Terraform Resource Definition

```bash
HUMANITEC_ORG=
LOCATION=
RESOURCE_GROUP=
AZURE_SUBCRIPTION_ID=
AZURE_SUBCRIPTION_TENANT_ID=
AZURE_SERVICE_PRINCIPAL_ID=
AZURE_SERVICE_PRINCIPAL_SECRET=

cat <<EOF > azure-storage-terraform.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: azure-storage-terraform
object:
  name: azure-storage-terraform
  type: azure-blob
  driver_type: ${HUMANITEC_ORG}/terraform
  driver_inputs:
    values:
      source:
        path: terraform/azure-storage/
        rev: refs/heads/main
        url: https://github.com/mathieu-benoit/hello-humanitec.git
      variables:
        storage_account_location: ${LOCATION}
        resource_group_name: ${RESOURCE_GROUP}
    secrets:
      variables:
        credentials:
          azure_subscription_id: ${AZURE_SUBCRIPTION_ID}
          azure_subscription_tenant_id: ${AZURE_SUBCRIPTION_TENANT_ID}
          service_principal_id: ${AZURE_SERVICE_PRINCIPAL_ID}
          service_principal_password: ${AZURE_SERVICE_PRINCIPAL_SECRET}
EOF

humctl create \
    -f azure-storage-terraform.yaml
```
