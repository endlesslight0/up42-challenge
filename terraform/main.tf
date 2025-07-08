# Create namespace
resource "kubernetes_namespace" "s3www" {
  metadata {
    name        = var.namespace
    labels      = local.namespace_labels
    annotations = local.common_annotations
  }
}

# Generate random password for MinIO
resource "random_password" "minio_password" {
  length  = 32
  special = true
}

# Create secret for MinIO credentials
resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "s3www-minio"
    namespace = kubernetes_namespace.s3www.metadata[0].name

    labels      = local.minio_labels
    annotations = local.common_annotations
  }

  data = {
    "rootUser"     = var.minio_access_key
    "rootPassword" = random_password.minio_password.result
  }

  type = "Opaque"

  depends_on = [random_password.minio_password]
}

resource "helm_release" "minio" {
  name       = "minio"
  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = var.minio_chart_version
  namespace  = kubernetes_namespace.s3www.metadata[0].name

  values = [
    templatefile("${path.module}/values/minio.yaml", {
      existingSecret = kubernetes_secret.minio_credentials.metadata[0].name
    })
  ]
  depends_on = [kubernetes_secret.minio_credentials, kubernetes_namespace.s3www]
}

resource "kubernetes_job" "file_upload" {
  depends_on = [kubernetes_namespace.s3www, helm_release.minio]

  metadata {
    name        = "upload-gif-file"
    namespace   = kubernetes_namespace.s3www.metadata[0].name
    labels      = local.job_labels
    annotations = local.common_annotations
  }

  spec {
    template {
      metadata {
        labels      = local.job_labels
        annotations = local.common_annotations
      }
      spec {
        restart_policy = "Never"
        container {
          name    = "file-uploader"
          image   = var.uploader_job_image
          command = ["/bin/sh", ]
          args    = ["-c", file("${path.module}/scripts/file_upload.sh")]

          env {
            name  = "MINIO_ENDPOINT"
            value = "http://minio.${var.namespace}.svc.cluster.local:9000"
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = var.minio_access_key
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = random_password.minio_password.result
          }
          env {
            name  = "GIPHY_LINK"
            value = var.giphy_link
          }
          env {
            name  = "HOST_ARCH"
            value = var.host_arch
          }
        }
      }
    }
  }
}

# Deploy the s3www application
resource "helm_release" "s3www" {
  name      = "s3www"
  chart     = "../helm/s3www"
  namespace = kubernetes_namespace.s3www.metadata[0].name
  timeout   = 600

  values = [
    templatefile("${path.module}/values/s3www.yaml", {
      s3www_tag = var.s3www_image_tag
      accessKey = var.minio_access_key
      secretKey = random_password.minio_password.result
    })
  ]

  depends_on = [kubernetes_namespace.s3www, helm_release.minio, kubernetes_job.file_upload]
}
