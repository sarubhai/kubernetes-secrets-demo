# kubernetes-secrets-demo

Demo to explore the different types of Kubernetes Secrets, methods of using them in Pods, advanced external secret management systems, and best practices to ensure your secrets are handled securely.

This repository contains the source code for Kubernetes Secrets Demo.

For a detailed guide, follow the articles: [Secret Management in Kubernetes](https://appdev24.com/pages/64/secret-management-in-kubernetes) and [External Secret Management in Kubernetes](https://appdev24.com/pages/65/external-secret-management-in-kubernetes)

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setup Instructions](#setup-instructions)
3. [Cleanup](#cleanup)

## Prerequisites
Ensure the following tools are installed on your local machine:

- [Docker](https://www.docker.com/)
- [Kubernetes](https://kubernetes.io/) (Docker Desktop Kubernetes is sufficient)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal)
```
brew install kubeseal
```

## Setup Instructions

### Step 1: Clone the Repository

Clone this repository to your local machine:
```
git clone https://github.com/sarubhai/kubernetes-secrets-demo.git
cd kubernetes-secrets-demo
```

### Step 2: Deploy Resources

#### AWS Access secrets
Create a Kubernetes Secrets file `aws-access-secret.yaml` with your AWS access credentials
```
apiVersion: v1
kind: Secret
metadata:
  name: aws-secret
  namespace: secrets-demo
type: Opaque
data:
  AWS_ACCESS_KEY_ID: XXXXX=
  AWS_SECRET_ACCESS_KEY: YYYYY==
```

#### AWS Secrets Manager
Create a AWS Secret:
- Region: `eu-central-1`
- Secret Name: `demo/aws-sm/ext-postgres-secret`
- Secret Type: Other type of secret
- Plaintext: `{"username":"admin","password":"S3cr3tPassw0rd"}`
- Encryption key: aws/secretsmanager

Finally Run the deployment script to start the services:
```
./installation.sh
```

## Cleanup
To clean up resources and reset the environment:

### Step 1: Run Cleanup Script
Run the cleanup script to remove all resources:
```
./cleanup.sh
```
