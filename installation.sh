#!/bin/sh

# Secret Verification Helper Function
function verify_kubernetes_secret () {
    kubectl get secret $1 --namespace=secrets-demo --template={{.data.username}} | base64 -d
    echo ""
    kubectl get secret $1 --namespace=secrets-demo --output jsonpath="{.data.password}" | base64 -d
    echo ""
}

# Demo Namespace
kubectl create namespace secrets-demo


# Kubernetes Secrets
# Opaque Secrets
kubectl apply -f postgres-secret.yaml
verify_kubernetes_secret postgres-secret

# Docker Config Secrets
kubectl apply -f docker-secret.yaml

# TLS Secret
kubectl create secret tls demo-local-tls-secret \
  --cert=demo-local-tls.crt \
  --key=demo-local-tls.key \
  --namespace=secrets-demo

# Using Secrets as Environment Variables
kubectl apply -f postgres-secret-pod.yaml
# Verify
while [[ $(kubectl get pod postgres -n secrets-demo -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    printf '.'
    sleep 2
done
kubectl exec postgres --namespace=secrets-demo -- env PGPASSWORD=S3cr3tPassw0rd psql admin -U admin -h localhost -p 5432 -c "\l"

# Using Secrets as Volume Mounts
kubectl apply -f nginx-tls-secret-pod.yaml
# Verify
while [[ $(kubectl get pod nginx -n secrets-demo -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    printf '.'
    sleep 1
done
kubectl exec nginx --namespace=secrets-demo -- cat /etc/nginx/ssl/tls.crt
kubectl exec nginx --namespace=secrets-demo -- cat /etc/nginx/ssl/tls.key
kubectl exec nginx --namespace=secrets-demo -- printenv
kubectl exec nginx --namespace=secrets-demo -- sh -c 'echo $NGINX_TLS_CRT'

# Passing Secrets to Container Command Arguments
kubectl apply -f pass-secrets-pod.yaml
# Verify
while [[ $(kubectl get pod mlflow -n secrets-demo -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    printf '.'
    sleep 1
done
kubectl logs -p mlflow -n secrets-demo
kubectl logs -p mlflow -n secrets-demo --previous=false



# Bitnami Sealed Secrets

# Install Sealed Secrets Controller
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
sleep 30

# Install the client-side tool
# brew install kubeseal

# Retrieve the Public certificate used for Encryption
kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --fetch-cert > sealed-secrets-cert.pem

# Create a Sealed Secret file
kubectl create secret generic ss-postgres-secret --namespace=secrets-demo \
    --from-literal=username=admin \
    --from-literal=password='S3cr3tPassw0rd' \
    --dry-run=client -o yaml | \
    kubeseal --cert sealed-secrets-cert.pem --format yaml > postgres-sealed-secret.yaml

# The generated file can be safely commited to Version Control System.


# Apply Sealed Secret
kubectl apply -f postgres-sealed-secret.yaml

# Verify Kubernetes Secret
verify_kubernetes_secret ss-postgres-secret



# Hashicorp Vault Secrets

# Install Vault Dev Cluster
kubectl create namespace vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault \
    --set server.dev.enabled=true \
    --set ui.enabled=true \
    --set injector.enabled=false

# Configure Vault
while [[ $(kubectl get pod vault-0 -n vault -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    printf '.'
    sleep 1
done

kubectl cp vault-config.sh vault-0:/tmp/vault-config.sh -n vault
kubectl exec -it vault-0 -n vault -- /bin/sh /tmp/vault-config.sh


# Install the Vault Secrets Operator
helm install vault-secrets-operator hashicorp/vault-secrets-operator -n kube-system --values vault-operator-values.yaml


# Deploy and sync a Secret
kubectl apply -f vault-auth.yaml
kubectl apply -f vault-postgres-secret.yaml


# Verify Kubernetes Secret
sleep 30
verify_kubernetes_secret vault-postgres-secret


# Rotate Vault Secret
kubectl exec -it vault-0 -n vault -- \
    vault kv put kv-secrets/postgres/config username="admin" password="S3cr3tPassw0rd1234"

sleep 30
verify_kubernetes_secret vault-postgres-secret



# External Secrets

# Install External Secrets Operator
kubectl create namespace external-secrets
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets

kubectl apply -f aws-access-secret.yaml

sleep 30
kubectl apply -f secret-store.yaml
kubectl apply -f external-secret.yaml

while ! kubectl get secret ext-postgres-secret --namespace secrets-demo; do echo "."; sleep 1; done
verify_kubernetes_secret ext-postgres-secret



# Reloader
helm repo add stakater https://stakater.github.io/stakater-charts
helm install reloader stakater/reloader -n kube-system

kubectl apply -f reloader-deploy.yaml

while [[ $(kubectl get pod -n secrets-demo -l app=reloader-demo-pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    printf '.'
    sleep 1
done
pod_name=`kubectl get pod -n secrets-demo -l app=reloader-demo-pod --output=json | jq -r '.items[0].metadata.name'`
kubectl exec -it $pod_name -n secrets-demo -- /bin/sh -c 'echo $POSTGRES_USER'
kubectl exec -it $pod_name -n secrets-demo -- /bin/sh -c 'echo $POSTGRES_PASSWORD'
