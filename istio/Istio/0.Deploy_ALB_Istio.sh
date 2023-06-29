#!/bin/bash

# Install Istio
echo '###Install Istio###'
curl -sL https://istio.io/downloadIstio | sh -
rm -rf ~/.istioctl
echo y | mv istio-* ~/.istioctl 
export PATH=$HOME/.istioctl/bin:$PATH
istioctl x precheck
echo y | istioctl install --set profile=default --set values.gateways.istio-ingressgateway.type=NodePort

# Enable Sidecar
echo '###Enable Sidecar###'
kubectl label namespace default istio-injection=enabled

# Istio Port Number
ISTIO_DEFAULT_PORT=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="status-port")].nodePort}')

# Update Istio-Operator
echo '###Update IStio-Operator###'
touch ~/.istioctl/istio-operator.yaml
cat <<EOF > ~/.istioctl/istio-operator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
        service:
          type: NodePort # ingress gateway 의 NodePort 사용
        serviceAnnotations:  # Health check 관련 정보
          alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
          alb.ingress.kubernetes.io/healthcheck-port: "${ISTIO_DEFAULT_PORT}" # 위에서 얻은 port number를 사용
    pilot:
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
  meshConfig:
    enableTracing: true
    defaultConfig:
      holdApplicationUntilProxyStarts: true
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
EOF

# Apply Istio
echo y | istioctl install -f ~/.istioctl/istio-operator.yaml


# Deploy ALB Ingress
echo '###Deploy ALB Ingress###'
cat <<EOF > ~/.istioctl/ALB-Ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-alb
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80},{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "${ACM_TLS_ARN}"
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: ssl-redirect
            port:
              name: use-annotation
        pathType: Prefix
        path: /
      - backend:
          service:
            name: istio-ingressgateway
            port:
              number: 80
        path: /
        pathType: Prefix
      - backend:
          service:
            name: istio-ingressgateway
            port:
              number: 443
        path: /
        pathType: Prefix
EOF
kubectl apply -f  ~/.istioctl/ALB-Ingress.yaml
