kubectl edit deploy ingress-nginx-controller -n ingress-nginx
- --tcp-services-configmap=ingress-nginx/tcp-services

kubectl edit svc ingress-nginx-controller -n ingress-nginx
- appProtocol: http
    name: mysql-svc
    nodePort: 32281
    port: 3306
    protocol: TCP
    targetPort: 3306