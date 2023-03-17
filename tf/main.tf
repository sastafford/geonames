terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

# Use Databricks CLI authentication.
provider "databricks" {
  profile = var.databricks_connection_profile
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "personal_compute" {
  cluster_name            = var.personal_compute_name
  spark_version           = data.databricks_spark_version.latest_lts.id
  custom_tags             = {"project": "geonames"}
  node_type_id            = "i3.xlarge"
  autotermination_minutes = 60
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  data_security_mode = "SINGLE_USER"
}

data "databricks_current_user" "me" {
}

resource "databricks_notebook" "read_geonames_csv" {
  format = "JUPYTER"
  source = "${path.module}/../geonames/read_geonames_csv.ipynb"
  path   = "${data.databricks_current_user.me.home}/geonames/read_geonames_csv"
  language = "PYTHON"
}
