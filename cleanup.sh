#!/bin/sh

# Reloader
kubectl delete -f reloader-deploy.yaml
helm uninstall reloader -n kube-system
helm repo remove stakater

# External Secrets
kubectl delete -f external-secret.yaml
kubectl delete -f secret-store.yaml
kubectl delete -f aws-access-secret.yaml

helm uninstall external-secrets -n external-secrets
helm repo remove external-secrets

kubectl delete namespace external-secrets

# Hashicorp Vault Secrets Operator
kubectl delete -f vault-auth.yaml
kubectl delete -f vault-postgres-secret.yaml
helm uninstall vault-secrets-operator -n kube-system
helm uninstall vault -n vault
helm repo remove hashicorp
kubectl delete namespace vault

# Bitnami Sealed Secrets
kubectl delete -f postgres-sealed-secret.yaml
helm uninstall sealed-secrets -n kube-system
helm repo remove sealed-secrets

# Kubernetes Secrets
kubectl delete -f pass-secrets-pod.yaml
kubectl delete -f nginx-tls-secret-pod.yaml
kubectl delete -f postgres-secret-pod.yaml
kubectl delete secret demo-local-tls-secret --namespace=secrets-demo
kubectl delete -f docker-secret.yaml

kubectl delete namespace secrets-demo
