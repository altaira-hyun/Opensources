#!/bin/bash

DOMAIN=tanzu-altair.com
APP=tetris
NAMESPACE=default
CLUSTER_DOMAIN=cluster.local
DIR=/root/.istioctl/2.App/${APP}


mkdir -p ${DIR}
# Create Gateway
cat <<EOF > ${DIR}/${APP}-gw.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ${APP}-gw
  namespace: ${NAMESPACE}
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
kubectl apply -f ${DIR}/${APP}-gw.yaml
# Create VirtualService
cat <<EOF > ${DIR}/${APP}-virtualsvc.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ${APP}-virtualsvc
  namespace: ${NAMESPACE}
spec:
  gateways:
  - ${NAMESPACE}/${APP}-gw
  hosts:
  - "${APP}.${DOMAIN}"
  http:
  - route:
    - destination:
        host: ${APP}-svc
        port:
          number: 80 # App service port
EOF
kubectl apply -f ${DIR}/${APP}-virtualsvc.yaml
# Create Destination Rule
#cat <<EOF > ${DIR}/${APP}-destrule.yaml
#apiVersion: networking.istio.io/v1alpha3
#kind: DestinationRule
#metadata:
#  name: ${APP}
#  namespace: ${NAMESPACE}
#spec:
#  host: ${APP}-svc
#  subsets:
#  - name: v1
#EOF
#kubectl apply -f ${DIR}/${APP}-destrule.yaml


#Check
kubectl get po,svc,gateway,virtualservice,destinationrule -n ${NAMESPACE}
