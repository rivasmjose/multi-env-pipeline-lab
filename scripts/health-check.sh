#!/bin/bash
set -e

NAMESPACE=$1
SERVICE_NAME=$2
MAX_RETRIES=30
RETRY_INTERVAL=5

if [ -z "$NAMESPACE" ] || [ -z "$SERVICE_NAME" ]; then
  echo "Uso: $0 <namespace> <service-name>"
  exit 1
fi

echo "🔍 Verificando la salud de $SERVICE_NAME en el namespace $NAMESPACE..."

for i in $(seq 1 $MAX_RETRIES); do
  echo "Intento $i/$MAX_RETRIES..."

  # Contar pods en ejecución con la etiqueta del servicio
  RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" -l "app=$SERVICE_NAME" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
  TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" -l "app=$SERVICE_NAME" --no-headers | wc -l)

  echo "  Pods en ejecución: $RUNNING_PODS/$TOTAL_PODS"

  if [ "$RUNNING_PODS" -gt 0 ]; then
    # Probar conectividad al servicio
    if kubectl run tmp-healthcheck --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" -- \
      curl -f -s "http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local" > /dev/null 2>&1; then
      echo "✅ ¡Verificación de salud aprobada! El servicio está saludable."
      exit 0
    else
      echo "  Servicio no accesible aún, esperando..."
    fi
  else
    echo "  Ningún pod en ejecución
