# Terraform

```
terraform plan -var-file="local.tfvars"
terraform apply -var-file="local.tfvars"
```

# Clusters

## Create cluster

```
databricks clusters create --json-file ./databricks/clusters/personal.json > personal_cluster_id.json
```

## Start cluster

```
databricks clusters start
```

# Best Practices

 * [Enable idempotent writes across jobs](https://docs.databricks.com/delta/idempotent-writes.html)
