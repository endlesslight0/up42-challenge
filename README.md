# S3WWW Application Deployment

A production-ready deployment solution for the s3www application using Helm and Terraform on Kubernetes. This solution provides a robust, scalable, and maintainable approach to deploying a Go-based web server with MinIO object storage backend.

## Architecture Overview

The deployment consists of:
- **s3www application**: A Go-based web server for serving files from S3-compatible storage
- **MinIO**: S3-compatible object storage solution for local file storage
- **Automated file upload**: Kubernetes job that fetches and uploads content to MinIO
- **Monitoring integration**: ServiceMonitor for Prometheus metrics collection
- **External access**: Ingress configuration for external traffic routing

## Prerequisites

- Kubernetes cluster (local or cloud-based)
- Helm 3.x
- Terraform >= 1.0
- kubectl configured to access your cluster
- Ingress controller (e.g., NGINX Ingress Controller)
- Prometheus Operator (for metrics collection)

### Local Development Setup

Recommend options:
- **Podman Desktop** with **Kind**
- **Minikube**
- **Docker Desktop**
- **K3d**

## Quick Start

### 1. Clone the Repository

```bash
git clone git@github.com:endlesslight0/up42-challenge.git
cd up42-challenge
```

### 2. Configure Variables

The following table lists all accepted input variables for the Terraform configuration:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `namespace` | `string` | `"s3www"` | Kubernetes namespace for the deployment |
| `environment` | `string` | `"dev"` | Environment name (dev, staging, prod) |
| `kubeconfig_path` | `string` | `"~/.kube/config"` | Path to kubeconfig file |
| `kubeconfig_context` | `string` | `""` | Kubernetes context to use |
| `s3www_replicas` | `number` | `1` | Number of s3www replicas |
| `s3www_image_tag` | `string` | `"v0.9.0"` | Docker image tag for s3www |
| `uploader_job_image` | `string` | `"alpine:3.22"` | Docker image used for file_upload Kubernetes Job |
| `ingress_host` | `string` | `"s3www.local"` | Hostname for ingress |
| `minio_chart_version` | `string` | `"5.4.0"` | Official MinIO helm chart version |
| `minio_access_key` | `string` | `"minioadmin"` | MinIO access key |
| `giphy_link` | `string` | `"https://media.giphy.com/media/VdiQKDAguhDSi37gn1/giphy.gif"` | Link to gif file from giphy.com |
| `host_arch` | `string` | `"arm64"` | Host CPU architecture |


### 3. Deploy the Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Access the Application

After deployment, the application will be available at:
- **Local access**: `http://localhost:8080` (via port-forward)
- **Ingress**: `http://s3www.local` (configure your local DNS or hosts file)

## Detailed Configuration

### Terraform Configuration

The Terraform configuration manages:

#### Infrastructure Resources
- **Namespace**: Isolated environment for the application
- **Secrets**: Secure credential management for MinIO
- **Helm Releases**: Orchestrated deployment of MinIO and s3www

#### Key Components

1. **Namespace Management**
   ```hcl
   resource "kubernetes_namespace" "s3www" {
     metadata {
       name        = var.namespace
       labels      = local.namespace_labels
       annotations = local.common_annotations
     }
   }
   ```

2. **Secret Management**
   - Automatically generates secure MinIO credentials
   - Stores credentials in Kubernetes secrets
   - Follows least-privilege principles

3. **File Upload Automation**
   - Kubernetes Job downloads content from external URL
   - Automatically creates MinIO buckets and uploads files
   - Handles different CPU architectures (amd64/arm64)
   - Uses custom shell script for multi-step file processing

### s3www Helm Chart Structure

The Helm chart follows best practices for production deployments:

```
helm/s3www/
├── Chart.yaml          # Chart metadata and dependencies
├── values.yaml         # Default configuration values
└── templates/
    ├── _helpers.tpl    # Template helpers and common labels
    ├── deployment.yaml # Application deployment
    ├── service.yaml    # Service configuration
    ├── ingress.yaml    # External access configuration
    ├── serviceaccount.yaml  # ServiceAccount configuration
    ├── servicemonitor.yaml  # Prometheus monitoring
    └── NOTES.txt       # Post-installation instructions
```

#### Key Features

- **Security**: Non-root containers, security contexts, and resource limits
- **Accessibility**: Ingress template for external access
- **Monitoring**: ServiceMonitor template to enable Prometheus metrics endpoint

### File Upload Automation

The deployment includes an automated file upload mechanism that runs as a Kubernetes Job:

#### Script Location
- **Script**: `terraform/scripts/file_upload.sh`
- **Execution**: Runs in an Alpine Linux container as a Kubernetes Job

#### Script Functionality

The upload script performs the following operations:

1. **Environment Setup**
   ```bash
   # Installs required tools
   apk add --no-cache curl
   ```

2. **File Download**
   ```bash
   # Downloads the GIF file from the provided URL
   curl -L -o /tmp/giphy.gif $GIPHY_LINK
   ```

3. **MinIO Client Installation**
   ```bash
   # Downloads and installs MinIO client for the correct architecture
   curl -L https://dl.min.io/client/mc/release/linux-$HOST_ARCH/mc -o /usr/bin/mc
   chmod +x /usr/bin/mc
   ```

4. **MinIO Configuration**
   ```bash
   # Configures MinIO client with connection details
   mc alias set minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
   ```

5. **HTML Template Creation**
   - Creates a responsive HTML index page with dark theme
   - Includes CSS styling for centered, responsive image display
   - References the uploaded GIF file

6. **File Upload**
   ```bash
   # Creates bucket and uploads files
   mc mb --ignore-existing minio/files
   mc cp /tmp/index.html minio/files/
   mc cp /tmp/giphy.gif minio/files/
   ```

#### Script Features

- **Architecture Support**: Automatically detects and downloads the correct MinIO client binary (amd64/arm64)
- **Error Handling**: Uses `set -e` to exit on any command failure
- **Idempotent Operations**: Bucket creation ignores existing buckets
- **Multi-file Upload**: Handles both HTML and media files
- **Responsive Design**: Generated HTML works on various screen sizes

#### Job Configuration

The Kubernetes Job is configured in Terraform:

```hcl
resource "kubernetes_job" "file_upload" {
  depends_on = [kubernetes_namespace.s3www, helm_release.minio]
  
  metadata {
    name      = "upload-gif-file"
    namespace = kubernetes_namespace.s3www.metadata[0].name
  }
  
  spec {
    template {
      spec {
        restart_policy = "Never"
        container {
          name    = "file-uploader"
          image   = "alpine:3.22"
          command = ["/bin/sh"]
          args    = ["-c", file("${path.module}/scripts/file_upload.sh")]
          # Environment variables configured here
        }
      }
    }
  }
}
```

### MinIO Configuration

MinIO is deployed using the official Helm chart with custom values:

```yaml
# terraform/values/minio.yaml
service:
  type: ClusterIP
  port: 9000

existingSecret: ${existingSecret}

resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 200m

persistence:
  enabled: false

mode: standalone

buckets:
  - name: files
    policy: public
    purge: false
    versioning: false
    objectlocking: false
```

For additional configuration options see https://github.com/minio/minio/blob/master/helm/minio/README.md and official MinIO documentation https://min.io/docs/minio/linux/index.html .

### S3WWW Application Configuration

The s3www application is configured to:
- Connect to MinIO using generated credentials
- Serve files from the configured bucket
- Expose metrics for monitoring
- Handle graceful shutdowns

## Deployment Process

### Step-by-Step Deployment for Local Development

1. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan Deployment**
   ```bash
   terraform plan
   ```

3. **Apply Configuration**
   ```bash
   terraform apply
   ```

4. **Verify Deployment**
   ```bash
   kubectl get pods -n s3www
   kubectl get services -n s3www
   ```
### Deployment for Production environment

Use CI/CD company pipeline that includes safety measures, such as linting checks, security scans, peer reviewed pull requests.

### Deployment Dependencies

The deployment follows this order:
1. Namespace creation
2. Secret generation and creation
3. MinIO deployment
4. File upload job execution
5. S3WWW application deployment

## Configuration Options

### Terraform Variables

Edit `terraform/variables.tf` or create a `terraform.tfvars` file:

```hcl
namespace = "s3www"
environment = "development"
minio_access_key = "admin"
giphy_link = "https://media.giphy.com/media/example/giphy.gif"
host_arch = "amd64"  # or "arm64" for Apple Silicon
```

### Helm Values Customization

You can customize the deployment by modifying:
- `terraform/values/minio.yaml`: MinIO configuration
- `terraform/values/s3www.yaml`: s3www configuration
- `helm/s3www/values.yaml`: Default s3www chart values

## Monitoring and Observability

### Prometheus Integration

The deployment includes disabled by default:
- **ServiceMonitor**: Automatically discovered by Prometheus Operator
- **Metrics endpoint**: `/metrics` on port 8080

To enable, modify as per example below:

```yaml
# terraform/values/s3www.yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics
    port: http
```

## Troubleshooting

### Common Issues

1. **Pod Not Starting**
   ```bash
   kubectl describe pod <pod-name> -n s3www
   kubectl logs <pod-name> -n s3www
   ```

2. **Service Not Accessible**
   ```bash
   kubectl get svc -n s3www
   kubectl describe ingress -n s3www
   ```

3. **File Upload Job Failed**
   ```bash
   kubectl logs job/upload-gif-file -n s3www
   ```

### Debug Commands

```bash
# Check all resources
kubectl get all -n s3www

# Check secrets
kubectl get secrets -n s3www

# Check ingress
kubectl get ingress -n s3www

# Port-forward for direct access
kubectl port-forward svc/s3www 8080:8080 -n s3www
```

## Security Considerations

### Implemented Security Measures

- **Non-root containers**: All containers run as non-root users
- **Resource limits**: CPU and memory limits prevent resource exhaustion
- **Secret management**: Credentials stored in Kubernetes secrets

## Maintenance and Updates

### Application Updates or Rollback

#### S3WWW container image tag

Update `s3www_image_tag` in `terraform/variables.tf` then follow the deployment process documented above.

#### MinIO chart version

Update `minio_chart_version` in `terraform/variables.tf` then follow the deployment process documented above.

## Contributing

When contributing to this deployment:

1. Follow Terraform and Helm best practices
2. Update documentation for any configuration changes
3. Test changes in a development environment
4. Ensure security considerations are addressed

## License

This deployment configuration is provided as-is for the UP42 Senior Cloud Engineer challenge.

## Support

For questions or issues:
1. Check the troubleshooting section
2. Review Kubernetes and Helm documentation
3. Examine logs and resource descriptions
4. Refer to the CHALLENGE.md for implementation decisions