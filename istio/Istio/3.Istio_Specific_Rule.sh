#!/bin/bash

DOMAIN=mzc-altair.com
DASHBOARD_NAME=argocd-server
DASHBOARD_SERVICE=argocd-server
NAMESPACE=argocd
CLUSTER_DOMAIN=${NAMESPACE}.svc.cluster.local
DIR=/root/.istioctl/1.Dashboard/${DASHBOARD_NAME}
SVC_PORT=443

mkdir -p ${DIR}/${DASHBOARD_NAME}

# Create Gateway
cat <<EOF > ${DIR}/${DASHBOARD_NAME}-gw.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ${DASHBOARD_NAME}-gw
  namespace: ${NAMESPACE}
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      credentialName: test
      mode: SIMPLE

EOF
kubectl apply -f ${DIR}/${DASHBOARD_NAME}-gw.yaml

# Create VirtualService
cat <<EOF > ${DIR}/${DASHBOARD_NAME}-virtualsvc.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ${DASHBOARD_NAME}-virtualsvc
  namespace: ${NAMESPACE}
spec:
  gateways:
  - ${NAMESPACE}/${DASHBOARD_NAME}-gw
  hosts:
  - "${DASHBOARD_NAME}.${DOMAIN}"
  http:
  - route:
    - destination:
        host: ${DASHBOARD_SERVICE}.${CLUSTER_DOMAIN}
        port:
          number: ${SVC_PORT} # App service port
EOF
kubectl apply -f ${DIR}/${DASHBOARD_NAME}-virtualsvc.yaml

# Check
kubectl get po,svc,gateway,virtualservice,destinationrule -n ${NAMESPACE}
