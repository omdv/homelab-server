#!/bin/bash
kubectl apply -k kubernetes/general

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install metrics bitnami/kube-prometheus --values=kubernetes/charts/prometheus-chart-values.yaml -n kube-system

helm repo add traefik https://helm.traefik.io/traefik
helm install traefik traefik/traefik --values=kubernetes/charts/traefik-chart-values.yaml -n apps

kubectl apply -k kubernetes/