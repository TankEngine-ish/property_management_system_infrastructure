#!/bin/bash
set -e

echo "Downloading Istio..."
ISTIO_VERSION=1.25.0
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH

echo "Installing Istio with minimal gateway-focused configuration, no full mesh..."
istioctl install -f istio-minimal-values.yaml -y

echo "Creating namespace for property-app and enabling Istio injection"
kubectl create namespace property-app --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace property-app istio-injection=enabled --overwrite

echo "Creating Istio Gateway and VirtualServices"
kubectl apply -f property-gateway.yaml

echo "waiting for Istio Gateway deployment to be ready..."
kubectl wait --namespace istio-system \
  --for=condition=available deployment/istio-ingressgateway \
  --timeout=120s || true

# Get the NodePort for port 80 (needed for HAProxy configuration)
NODE_PORT=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')

MASTER_PRIVATE_IP=$(grep "master ansible_host" inventory/hosts.ini | awk '{print $2}')
if [ -z "$MASTER_PRIVATE_IP" ]; then
  # Fallback to checking nodes directly
  MASTER_PRIVATE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi


HAPROXY_IP=$(grep "haproxy ansible_host" inventory/hosts.ini | awk '{print $2}')
if [ -z "$HAPROXY_IP" ]; then
  # fallback to hard-coded value if the old one has changed for some goddamn reason
  HAPROXY_IP="13.51.86.244" 
fi

echo "- HAProxy Public IP: ${HAPROXY_IP}"
echo ""
echo "My application will be accessible at:"
echo "- Frontend: http://${HAPROXY_IP}/"
echo "- Backend API: http://${HAPROXY_IP}/api/"

echo "=========================================================="
echo "Istio Gateway has been deployed successfully!"
echo "=========================================================="
echo ""
echo "Gateway Information:"
echo "- Istio Gateway NodePort: ${NODE_PORT}"
echo "- Master Node Private IP: ${MASTER_PRIVATE_IP}"
echo ""
echo "Verification: When configuring HAProxy, I am using master node IP: ${MASTER_PRIVATE_IP} with port: ${NODE_PORT}"
