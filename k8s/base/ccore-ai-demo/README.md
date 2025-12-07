# ccore-ai-demo — Kubernetes Application Deployment (EKS + Traefik + Kustomize)

This component contains the **demo application** deployed on AWS EKS, using:

- **Deployment**
- **Service (ClusterIP)**
- **Ingress (Traefik)**
- **Namespace isolation**
- **Kustomize bundling**

This serves as a minimal but production-aligned example of how workloads are onboarded into the platform.

---

# 1. Directory Structure

```
k8s/base/ccore-ai-demo/
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── kustomization.yaml
```

---

# 2. Deployment Components

## 2.1 Namespace

Ensures workload isolation:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ccore-ai-demo
```

---

## 2.2 Deployment

Defines:

- Container image  
- Replicas  
- Resource limits  
- Health probes  
- Routing labels for Traefik  

Key features:

- Stateless workload  
- Designed for NLB → Traefik → Service → Pod flow  
- Minimal configuration for demo speed  

---

## 2.3 Service

ClusterIP service exposing the application internally:

```yaml
type: ClusterIP
port: 8501
```

Acts as the stable backend for Traefik routing.

---

## 2.4 Ingress

Defines domain routing:

```yaml
spec:
  ingressClassName: traefik
  rules:
    - host: demo.ccore.ai
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ccore-ai-demo
                port:
                  number: 8501
```

Traefik provides:

- TLS termination  
- ACME support  
- Path & hostname routing  

---

# 3. Deploying the Demo Application

## Option A: Apply Kustomize bundle (recommended)

```bash
kubectl apply -k k8s/base/ccore-ai-demo
```

## Option B: Apply manifests manually

```bash
kubectl apply -f k8s/base/ccore-ai-demo/namespace.yaml
kubectl apply -f k8s/base/ccore-ai-demo/deployment.yaml
kubectl apply -f k8s/base/ccore-ai-demo/service.yaml
kubectl apply -f k8s/base/ccore-ai-demo/ingress.yaml
```

---

# 4. Verification

These commands confirm the application, routing, and ingress path are all working correctly.

---

## 4.1 Check Namespace

```bash
kubectl get ns | grep ccore-ai-demo
```

---

## 4.2 Check Pods

```bash
kubectl get pods -n ccore-ai-demo
```

Expected: Pods in **Running / Ready** state.

---

## 4.3 Check Service

```bash
kubectl get svc -n ccore-ai-demo
```

Expected:

- Service type: **ClusterIP**
- Port: **8501**

---

## 4.4 Check Ingress

```bash
kubectl get ingress -n ccore-ai-demo
kubectl describe ingress -n ccore-ai-demo
```

Look for:

- `traefik` ingress class  
- Correct host (`demo.ccore.ai`)  
- TLS enabled  

---

## 4.5 Test Routing (direct to NLB)

Get Traefik NLB DNS:

```bash
kubectl get svc traefik -n traefik
```

Then test:

```bash
curl -k -H "Host: demo.ccore.ai" https://<NLB-DNS-NAME>
```

Expected: application HTML response.

---

## 4.6 Logs

Application logs:

```bash
kubectl logs -n ccore-ai-demo -l app=ccore-ai-demo
```

Traefik routing logs:

```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

Look for:

- Router created  
- Backend discovered  
- No 404 / TLS errors  

---

# 5. Cleanup

```bash
kubectl delete -k k8s/base/ccore-ai-demo
```

---

# 6. Summary

This directory demonstrates:

- Clean, production-aligned Kubernetes workload structure  
- Complete routing chain: **NLB → Traefik → Service → Pod**  
- Full Kustomize workflow  
- TLS-enabled ingress routing  
- Ideal example of workload onboarding in EKS environments  
