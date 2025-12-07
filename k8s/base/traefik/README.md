# Traefik Deployment (EKS + Helm)

This component installs **Traefik** as the ingress controller for the EKS cluster using Helm.  
Configuration is provided via `values.yaml` and is optimized for:

- AWS **Network Load Balancer (NLB)**
- Automatic **HTTP → HTTPS redirect**
- **ACME (Let’s Encrypt)** TLS certificates
- Default ingress class: `traefik`

---

## 1. Add Traefik Helm Repository

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

---

## 2. Create Namespace

```bash
kubectl create namespace traefik
```

---

## 3. Install or Upgrade Traefik

```bash
helm upgrade --install traefik traefik/traefik   --namespace traefik   --version 37.4.0   --values k8s/base/traefik/values.yaml
```

---

# 4. Verification

These checks confirm that Traefik, its Load Balancer, and routing components are functioning correctly.

---

## 4.1 Check Pod Status

```bash
kubectl get pods -n traefik
```

Expected: Pods should be **Running** and **Ready**.

---

## 4.2 Check Service and NLB Creation

```bash
kubectl get svc -n traefik
```

Look for:

- `type: LoadBalancer`
- `EXTERNAL-IP` assigned (NLB hostname)

---

## 4.3 Describe the Service (verify NLB annotations)

```bash
kubectl describe svc traefik -n traefik
```

Confirm:

- `service.beta.kubernetes.io/aws-load-balancer-type: nlb`
- Inbound ports **80** and **443**

---

## 4.4 Check Traefik Logs

```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

Look for:

- ACME initialization
- Router creation events
- No TLS or backend errors

---

## 4.5 Test Ingress Routing (internal curl)

```bash
curl -k -H "Host: demo.ccore.ai" https://<NLB-DNS-NAME>
```

If routing works, you will receive the application response.

---

## 4.6 Test ACME Certificate Issuance

```bash
kubectl exec -n traefik deploy/traefik -- traefik show acmejson
```

Note: Only works if ACME persistence is enabled.  
In demo mode, ACME is in-memory and recreated on restart.

---

# 5. Cleanup

```bash
helm uninstall traefik -n traefik
kubectl delete namespace traefik
```

---

# Summary

This component provides:

- Fully functional Traefik ingress controller on EKS  
- NLB integration  
- Automatic HTTPS  
- Verified routing path: **NLB → Traefik → Service → Pod**  
- Simple and reproducible installation workflow
