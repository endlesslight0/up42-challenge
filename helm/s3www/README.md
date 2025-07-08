# s3www Helm Chart

A Helm chart for deploying s3www, a lightweight Go-based web server for serving static files from S3-compatible storage.

## Overview

This chart deploys the `y4m4/s3www` application on a Kubernetes cluster using Helm. The s3www application serves static files from S3-compatible storage backends like MinIO, AWS S3, or other compatible services.

Official website: https://s3www.y4m4.dev/

## Features

- **Lightweight**: Minimal resource footprint with configurable limits
- **Secure**: Non-root containers with security contexts and read-only filesystem
- **Configurable**: Support for various S3-compatible storage backends
- **Observable**: Optional Prometheus metrics integration
- **Production-ready**: Health checks, proper resource management, and security best practices

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- S3-compatible storage backend (MinIO, AWS S3, etc.)

## Installation

### Quick Start

```bash
# Install with default values (connects to MinIO)
helm install my-s3www ./s3www-chart

# Install with custom values
helm install my-s3www ./s3www-chart -f values.yaml
```

### Configuration

The chart can be configured through the `values.yaml` file or by using `--set` parameters:

```bash
helm install my-s3www ./s3www-chart \
  --set config.bucket=my-files \
  --set config.endpoint=https://s3.amazonaws.com \
  --set config.accessKey=AKIAIOSFODNN7EXAMPLE \
  --set config.secretKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## Configuration Parameters

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the full name | `""` |
| `replicaCount` | Number of replicas | `1` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `y4m4/s3www` |
| `image.tag` | Container image tag | `v0.9.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `service.targetPort` | Target port | `8080` |

### Application Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.bucket` | S3 bucket name | `files` |
| `config.endpoint` | S3 endpoint URL | `http://minio:9000` |
| `config.address` | Application bind address | `0.0.0.0:8080` |
| `config.accessKey` | S3 access key | `minioadmin` |
| `config.secretKey` | S3 secret key | `minioadmin` |
| `config.port` | Application port | `8080` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | `[{host: s3www.local, paths: [{path: /, pathType: Prefix}]}]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### Security Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext.fsGroup` | Pod security context fsGroup | `65534` |
| `podSecurityContext.runAsNonRoot` | Run as non-root user | `true` |
| `podSecurityContext.runAsUser` | User ID to run as | `65534` |
| `securityContext.allowPrivilegeEscalation` | Allow privilege escalation | `false` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |
| `securityContext.runAsNonRoot` | Run as non-root user | `true` |
| `securityContext.runAsUser` | User ID to run as | `65534` |

### Resource Management

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Service Account Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `serviceAccount.automountServiceAccountToken` | Auto-mount service account token | `false` |

### Health Check Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `healthCheck.enabled` | Enable health checks | `true` |
| `healthCheck.livenessProbe.initialDelaySeconds` | Liveness probe initial delay | `30` |
| `healthCheck.livenessProbe.periodSeconds` | Liveness probe period | `10` |
| `healthCheck.readinessProbe.initialDelaySeconds` | Readiness probe initial delay | `5` |
| `healthCheck.readinessProbe.periodSeconds` | Readiness probe period | `5` |

### Monitoring Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Enable monitoring | `false` |
| `monitoring.serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus | `false` |
| `monitoring.serviceMonitor.interval` | Scrape interval | `30s` |
| `monitoring.serviceMonitor.path` | Metrics path | `/metrics` |
| `monitoring.serviceMonitor.port` | Metrics port | `http` |

## Usage Examples

### Basic MinIO Integration

```yaml
# values-minio.yaml
config:
  bucket: "static-files"
  endpoint: "http://minio:9000"
  accessKey: "minioadmin"
  secretKey: "minioadmin"

service:
  type: LoadBalancer
```

### AWS S3 Integration

```yaml
# values-aws.yaml
config:
  bucket: "my-static-website"
  endpoint: "https://s3.amazonaws.com"
  accessKey: "AKIAIOSFODNN7EXAMPLE"
  secretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: static.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: static-example-com-tls
      hosts:
        - static.example.com
```

### Custom Storage Backend

```yaml
# values-custom.yaml
config:
  bucket: "files"
  endpoint: "https://storage.custom-provider.com"
  accessKey: "custom-access-key"
  secretKey: "custom-secret-key"
  port: 8080

service:
  type: NodePort
  port: 80
  targetPort: 8080
```

## Deployment Instructions

### 1. Deploy with MinIO (Local Development)

```bash
# Deploy MinIO first (if not already available)
helm repo add minio https://helm.min.io/
helm install minio minio/minio \
  --set rootUser=minioadmin \
  --set rootPassword=minioadmin

# Deploy s3www
helm install my-s3www ./s3www-chart
```

### 2. Deploy with AWS S3

```bash
# Create secret for AWS credentials
kubectl create secret generic s3-credentials \
  --from-literal=accessKey=AKIAIOSFODNN7EXAMPLE \
  --from-literal=secretKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Deploy with AWS configuration
helm install my-s3www ./s3www-chart \
  --set config.bucket=my-bucket \
  --set config.endpoint=https://s3.amazonaws.com \
  --set config.accessKey=AKIAIOSFODNN7EXAMPLE \
  --set config.secretKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### 3. Enable External Access

```bash
# Using LoadBalancer
helm upgrade my-s3www ./s3www-chart \
  --set service.type=LoadBalancer

# Using Ingress
helm upgrade my-s3www ./s3www-chart \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=s3www.example.com
```

## Accessing the Application

After deployment, you can access the application using:

### Port Forward (Development)

```bash
kubectl port-forward svc/my-s3www 8080:8080
# Access at http://localhost:8080
```

### LoadBalancer Service

```bash
kubectl get svc my-s3www
# Use the external IP provided
```

### Ingress

Configure your DNS to point to the ingress controller and access via the configured hostname.

## Monitoring

When monitoring is enabled, the application exposes Prometheus metrics at `/metrics`. The ServiceMonitor resource will automatically configure Prometheus to scrape these metrics.

```bash
# Enable monitoring
helm upgrade my-s3www ./s3www-chart \
  --set monitoring.enabled=true \
  --set monitoring.serviceMonitor.enabled=true
```

## Troubleshooting

### Common Issues

1. **Pod not starting**:
   ```bash
   kubectl describe pod -l app.kubernetes.io/name=s3www
   kubectl logs -l app.kubernetes.io/name=s3www
   ```

2. **S3 connection issues**:
   - Verify endpoint accessibility
   - Check credentials
   - Validate bucket permissions

3. **Health check failures**:
   - Verify the application is serving content at the root path
   - Check if the bucket contains accessible files

### Debug Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=s3www

# View logs
kubectl logs -l app.kubernetes.io/name=s3www -f

# Test connectivity
kubectl exec -it <pod-name> -- wget -qO- http://localhost:8080/

# Check service
kubectl get svc my-s3www
kubectl describe svc my-s3www
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## License

This chart is licensed under the Unlicense.