#!/bin/sh

cd /tmp
# Enable KV secrets engine
vault secrets enable -path=kv-secrets kv-v2
# Create a secret
vault kv put kv-secrets/postgres/config username="admin" password="S3cr3tPassw0rd"

# Enable and configure Kubernetes authentication
vault auth enable -path kubernetes-auth kubernetes
vault write auth/kubernetes-auth/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"


# Create a policy & role for Kubernetes
tee kv-secrets-policy.hcl <<EOF
path "kv-secrets/data/postgres/config" {
   capabilities = ["read", "list"]
}
EOF

vault policy write kv-secrets-policy kv-secrets-policy.hcl

vault write auth/kubernetes-auth/role/vault-k8s-role \
    bound_service_account_names=vault-sa \
    bound_service_account_namespaces=secrets-demo \
    policies=kv-secrets-policy \
    audience=vault \
    ttl=24h
