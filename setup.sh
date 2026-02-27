#!/bin/bash

k3d cluster create argo -p "80:80@loadbalancer" -p "443:443@loadbalancer"

kubectl create ns argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pod -n argocd --all --timeout=300s
kubectl port-forward svc/argocd-server -n argocd 8080:443 2>/dev/null &

PWD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "$PWD" --insecure

kubectl create namespace dev

argocd app create website \
  --repo https://github.com/Christellaa/argocd-pgimeno.git \
  --path ./confs \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

argocd app set website --sync-policy automated

echo "Access the website with http://172.19.0.2/ or localhost"
echo "Access ArgoCD UI with http://localhost:8080/ (username: admin, password: $PWD)"
