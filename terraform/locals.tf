# Common labels and annotations for all resources
locals {
  # Common labels applied to all resources
  common_labels = {
    "app.kubernetes.io/name"       = "s3www"
    "app.kubernetes.io/part-of"    = "s3www"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/version"    = var.s3www_image_tag
    "environment"                  = var.environment
    "project"                      = "s3www"
  }

  # Component-specific labels
  minio_labels = merge(local.common_labels, {
    "app.kubernetes.io/component" = "storage"
    "app.kubernetes.io/name"      = "minio"
  })

  s3www_labels = merge(local.common_labels, {
    "app.kubernetes.io/component" = "webserver"
    "app.kubernetes.io/name"      = "s3www"
  })

  namespace_labels = merge(local.common_labels, {
    "name" = var.namespace
  })

  job_labels = merge(local.common_labels, {
    "app.kubernetes.io/component" = "initialization"
    "app.kubernetes.io/name"      = "file-uploader"
  })

  # Common annotations
  common_annotations = {
    "managed-by"          = "terraform"
    "terraform.io/module" = "s3www"
  }

}