# Senior Cloud Engineer Challenge - Technical Design Document

## Executive Summary

This document outlines the technical decisions, design considerations, and implementation approach for deploying the s3www application with MinIO dependency using Helm and Terraform. The solution prioritizes production readiness, maintainability, and operational excellence while providing a foundation for future enhancements.

## Architecture Overview

The solution implements a microservices architecture with the following components:
- **s3www**: Go-based web server for serving files from S3-compatible storage
- **MinIO**: S3-compatible object storage solution for local development
- **Kubernetes**: Container orchestration platform
- **Helm**: Package manager for Kubernetes applications
- **Terraform**: Infrastructure as Code for deployment automation

## Considerations and Decisions

### 1. Terraform

- Write the solution as a terraform module.

Decision: Skip; could be done easily later if needed.

- Use locals.tf and predefined separate environments connected to workspaces. 

Decision: Skip, as this would make it harder to later reuse as module.

- Use terragrunt.

Decision: Skip. While it would simplify DRY setup in a more complex setup, it is overkill for the current one.

- Setup CI/CD using gitlab-ci or github actions

Decision: Skip. Out of scope.

- Setup KISS solution

Decision: **Selected approach*** that allows for more flexibility in the future and takes less time to implement.

### 2. Helm and File Provisioning Strategy

- Write a helm chart for s3www with minio chart as dependency and use initContainer or Kubernetes Job with helm hook to provision the bucket and download/upload gif + index.html file as part of minio (official chart offers support) or s3www chart. 

Decision: Skip. Job with pre-install hook would likely not work, because minio is not setup yet. Job with post-install hook would likely have issues as s3www needs to use a provisioned minio bucket before it is succesfully deployed. 

- Write a dedicated helm chart for s3www and use official minio chart separately. Use a separate Kubernetes Job deployed using terraform. Manage deployment order using terraform dependencies.

Decision: **Selected solution**. It allows to manage each component in a more flexible way, e.g. update gif file without updating s3www or minio charts/pods.

* Use ArgoCD to deploy the charts.

Decision: Skip. Although more preferable for production in my opinion, it would be an overkill to implement as part of this challenge.

## Current Limitations

- Local Terraform state (not suitable for team collaboration)
- Single replica deployment
- Persistent Storage is not in use (data loss risk)
- No backup/restore procedures

## Future Enhancements and Areas for Improvement

### Infrastructure as Code

- Create reusable modules for common patterns
- Implement S3 backend with state locking (DynamoDB)
- Enable encryption at rest for sensitive data
- Support for dev/staging/prod environments using tfvars
- Consider Terragrunt for DRY configuration management
- Dedicated IaC git repo and using CI/CD, pull request for any staging and production changes
- Automated terraform code testing
- Setup tools for automated generation of terraform code documentation
- Consider adding terraform.tfvars.example
- Makefile for common operations (setup, deploy, cleanup, debug)

### Kubernetes & Helm

- Develop organization-specific base charts
- Implement multiple replicas with proper anti-affinity for cross-zone redundancy
- Configure HPA (Horizontal Pod Autoscaler) or VPA (Vertical Pod Autoscaler)
- Integrate External Secrets Operator for advanced secrets management
- Define proper resource requests and limits
- Implement chart testing and validation
- Use persistent storage for MinIO
- Deploy MinIO in distributed mode

### Operational Excellence

- ArgoCD for GitOps-based deployments
- Enhanced observability with custom dashboards and alerts

### Security Enhancements

- Implement RBAC for fine-grained role-based access control
- Implement admission controllers
- Add Network Policies to restrict network communication between pods
- Implement Pod Security Standards
- Implement image scanning and vulnerability management
- Automated secret rotation mechanisms
- Adjust s3www helm chart to use existing secret for minio access
- Use a dedicated restricted user for s3www-minio connection

### Disaster Recovery

- Regular backup testing
- Documented recovery procedures
- Infrastructure as Code versioning
- Cross-region replication for critical data
- Set up alerts for backup failures
