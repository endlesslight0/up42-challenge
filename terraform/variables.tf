
variable "namespace" {
  description = "Kubernetes namespace for the deployment"
  type        = string
  default     = "s3www"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

variable "s3www_replicas" {
  description = "Number of s3www replicas"
  type        = number
  default     = 1
}

variable "s3www_image_tag" {
  description = "Docker image tag for s3www"
  type        = string
  default     = "v0.9.0"
}

variable "uploader_job_image" {
  description = "Docker image used for file_upload Kubernetes Job"
  type        = string
  default     = "alpine:3.22"
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = "s3www.local"
}

variable "minio_chart_version" {
  description = "Official MinIO helm chart version"
  type        = string
  default     = "5.4.0"
}

variable "minio_access_key" {
  description = "MinIO access key"
  type        = string
  default     = "minioadmin"
}

variable "minio_secret_key" {
  description = "MinIO secret key"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "giphy_link" {
  description = "Link to gif file from giphy.com"
  type        = string
  default     = "https://media.giphy.com/media/VdiQKDAguhDSi37gn1/giphy.gif"
}

variable "host_arch" {
  description = "Host CPU architecture"
  type        = string
  default     = "arm64"
}
