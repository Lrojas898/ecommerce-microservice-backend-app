# E-Commerce Microservices - Terraform Infrastructure

Infrastructure as Code (IaC) for deploying the E-Commerce microservices platform on Digital Ocean Kubernetes.

## 📋 **Table of Contents**

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Modules](#modules)
7. [Outputs](#outputs)
8. [Cost Estimation](#cost-estimation)
9. [Troubleshooting](#troubleshooting)

---

## 🏗️ **Overview**

This Terraform configuration provisions:

- **Digital Ocean Kubernetes Cluster (DOKS)** with 3 nodes (24GB total RAM)
- **NGINX Ingress Controller** for routing external traffic
- **cert-manager** for automatic SSL certificate management
- **Kubernetes Namespaces**: prod, staging, tracing, monitoring
- **Storage Classes** for persistent volumes
- **Auto-scaling** for node pools

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Digital Ocean Cloud                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │       Kubernetes Cluster (DOKS)                    │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │ │
│  │  │  Node 1  │  │  Node 2  │  │  Node 3  │        │ │
│  │  │  8GB RAM │  │  8GB RAM │  │  8GB RAM │        │ │
│  │  │  4 vCPUs │  │  4 vCPUs │  │  4 vCPUs │        │ │
│  │  └──────────┘  └──────────┘  └──────────┘        │ │
│  │                                                    │ │
│  │  ┌────────────────────────────────────────────┐  │ │
│  │  │          NGINX Ingress Controller          │  │ │
│  │  │      (LoadBalancer: $12/month)             │  │ │
│  │  └────────────────────────────────────────────┘  │ │
│  │                                                    │ │
│  │  Namespaces:                                      │ │
│  │  • prod       → Production services               │ │
│  │  • staging    → Staging environment               │ │
│  │  • tracing    → Jaeger distributed tracing        │ │
│  │  • monitoring → Prometheus + Grafana              │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ **Prerequisites**

### 1. Install Required Tools

```bash
# Terraform (>= 1.5.0)
brew install terraform  # macOS
# Or download from: https://www.terraform.io/downloads

# Digital Ocean CLI (doctl)
brew install doctl  # macOS
# Or download from: https://docs.digitalocean.com/reference/doctl/how-to/install/

# kubectl
brew install kubectl  # macOS
```

### 2. Digital Ocean Account

1. Create a Digital Ocean account: https://www.digitalocean.com/
2. Generate an API token:
   - Go to: https://cloud.digitalocean.com/account/api/tokens
   - Click "Generate New Token"
   - Name: `terraform-ecommerce`
   - Scopes: Read + Write
   - Copy the token (you won't see it again!)

### 3. Authenticate doctl

```bash
doctl auth init
# Paste your API token when prompted

# Verify authentication
doctl account get
```

---

## 🚀 **Quick Start**

### Step 1: Clone and Navigate

```bash
cd infrastructure/terraform
```

### Step 2: Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vi terraform.tfvars
```

**Minimum required variables:**
```hcl
do_token          = "dop_v1_your_token_here"
letsencrypt_email = "your-email@example.com"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (Digital Ocean, Kubernetes, Helm)
- Initialize the backend
- Prepare modules

### Step 4: Plan the Infrastructure

```bash
terraform plan
```

Review the resources that will be created:
- 1 Kubernetes cluster
- 3 worker nodes
- 4 namespaces
- 1 LoadBalancer
- NGINX Ingress Controller
- cert-manager
- ClusterIssuers for SSL

### Step 5: Apply the Configuration

```bash
terraform apply

# Review the plan
# Type 'yes' to confirm
```

⏱️ **This will take 5-10 minutes** to provision the cluster.

### Step 6: Configure kubectl

```bash
# Option A: Using doctl (recommended)
doctl kubernetes cluster kubeconfig save $(terraform output -raw cluster_name)

# Option B: Using Terraform output
terraform output -raw kubeconfig > ~/.kube/config-ecommerce
export KUBECONFIG=~/.kube/config-ecommerce

# Verify access
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Step 7: Get LoadBalancer IP

```bash
# Get the IP for DNS configuration
terraform output loadbalancer_ip

# Example output: 64.225.123.45
```

### Step 8: Configure DNS (Optional but Recommended)

If you have a domain, create A records pointing to the LoadBalancer IP:

```
api.yourdomain.com     → 64.225.123.45
jaeger.yourdomain.com  → 64.225.123.45
grafana.yourdomain.com → 64.225.123.45
```

### Step 9: Deploy Applications

```bash
# Navigate to Kubernetes configs
cd ../kubernetes

# Deploy to prod namespace
kubectl apply -f base/ -n prod

# Deploy tracing
kubectl apply -f tracing/

# Deploy monitoring
cd monitoring
./deploy-monitoring.sh
```

---

## 🔄 **GitHub Actions Pipeline**

### Overview

Además del uso manual de Terraform, este proyecto incluye una pipeline automatizada de GitHub Actions para gestionar la infraestructura de manera segura y controlada.

### Configuración de Secretos (OBLIGATORIO)

Antes de usar la pipeline, configura estos secretos en GitHub:

```
Settings → Secrets and variables → Actions → New repository secret
```

| Secreto | Valor |
|---------|-------|
| `DO_TOKEN` | Tu token de API de Digital Ocean |
| `LETSENCRYPT_EMAIL` | Tu email para certificados SSL |

### Configuración de Environments (OBLIGATORIO)

Para aprobaciones manuales, crea estos ambientes en GitHub:

```
Settings → Environments → New environment
```

| Ambiente | Configuración |
|----------|---------------|
| `prod` | Required reviewers: Tu usuario |
| `dev` | Required reviewers: Tu usuario |
| `prod-destroy` | Required reviewers + Wait timer: 5 min |
| `dev-destroy` | Required reviewers: Tu usuario |

### Uso de la Pipeline

#### 1. Plan (Ver cambios)
```
Actions → Terraform Infrastructure → Run workflow
- Action: plan
- Environment: prod
```

Muestra qué recursos se crearían/modificarían sin hacer cambios reales.

#### 2. Apply (Crear/Actualizar infraestructura)
```
Actions → Terraform Infrastructure → Run workflow
- Action: apply
- Environment: prod
- Auto-approve: false
```

1. Ejecuta plan
2. Espera aprobación manual
3. Aplica cambios
4. Guarda estado como artifact

**Aprobación manual:**
1. Ve a Actions → Click en el workflow
2. Click en "Review deployments"
3. Selecciona el ambiente
4. Click en "Approve and deploy"

#### 3. Destroy (Eliminar infraestructura)
```
Actions → Terraform Infrastructure → Run workflow
- Action: destroy
- Environment: prod
- Auto-approve: false (SIEMPRE)
```

⚠️ **PELIGROSO**: Elimina todos los recursos. Úsalo con extrema precaución.

### Triggers Automáticos

La pipeline también se ejecuta automáticamente en estos casos:

- **Push a master/main**: Ejecuta `terraform plan` automáticamente
- **Pull Requests**: Comenta el plan en el PR para revisión

### Gestión del Estado

El estado de Terraform se guarda como artifact de GitHub con retención de 30 días. Para trabajo en equipo, se recomienda configurar backend remoto en Digital Ocean Spaces (ver sección abajo).

---

## ⚙️ **Configuration**

### terraform.tfvars

Key variables to customize:

```hcl
# Cluster configuration
cluster_region  = "nyc1"           # Region closest to you
node_pool_size  = "s-4vcpu-8gb"    # Node size (8GB RAM)
node_pool_count = 3                # Number of nodes (24GB total)

# Auto-scaling
node_pool_auto_scale = true
node_pool_min_nodes  = 3           # Minimum nodes
node_pool_max_nodes  = 6           # Maximum nodes

# SSL configuration
enable_cert_manager  = true
letsencrypt_email    = "you@example.com"

# Ingress
enable_ingress_nginx = true
```

### Node Size Options

| Size | RAM | vCPUs | Price/month | Nodes for 20GB+ | Total Cost |
|------|-----|-------|-------------|-----------------|------------|
| `s-2vcpu-4gb` | 4GB | 2 | $24 | 5 | $120 |
| `s-4vcpu-8gb` | 8GB | 4 | $48 | 3 | $144 | ✓ **Recommended** |
| `s-6vcpu-16gb` | 16GB | 6 | $96 | 2 | $192 |

---

## 📚 **Modules**

### 1. Kubernetes Module

Located in: `modules/kubernetes/`

Creates:
- Digital Ocean Kubernetes cluster
- Node pools with auto-scaling
- Kubernetes namespaces (prod, staging, tracing, monitoring)
- Storage classes
- Container registry (optional)

### 2. Networking Module

Located in: `modules/networking/`

Creates:
- NGINX Ingress Controller (via Helm)
- cert-manager (via Helm)
- ClusterIssuers for Let's Encrypt (prod & staging)
- LoadBalancer service

### 3. Monitoring Module (Future)

Located in: `modules/monitoring/`

Will create:
- Prometheus deployment
- Grafana deployment
- AlertManager
- Pre-configured dashboards

---

## 📤 **Outputs**

### View All Outputs

```bash
terraform output
```

### Important Outputs

```bash
# Cluster information
terraform output cluster_name
terraform output cluster_region

# LoadBalancer IP for DNS
terraform output loadbalancer_ip

# Get kubeconfig
terraform output -raw kubeconfig > kubeconfig.yaml

# Infrastructure summary
terraform output infrastructure_summary

# Next steps guide
terraform output next_steps
```

---

## 💰 **Cost Estimation**

### Monthly Costs (Production)

| Resource | Quantity | Unit Price | Total |
|----------|----------|------------|-------|
| Worker Nodes (s-4vcpu-8gb) | 3 | $48/month | $144 |
| LoadBalancer | 1 | $12/month | $12 |
| Block Storage (100GB) | 1 | $10/month | $10 |
| **Total** | | | **~$166/month** |

### Cost Optimization Tips

1. **Use Smaller Nodes for Dev**:
   ```hcl
   node_pool_size = "s-2vcpu-4gb"  # $24/month per node
   node_pool_count = 2              # $48 total for dev
   ```

2. **Enable Auto-Scaling**:
   - Scale down during off-hours
   - Only scale up when needed

3. **Use Staging Environment**:
   - Keep prod cluster always on
   - Deploy staging cluster only when needed
   - Destroy after testing

4. **Monitor Resource Usage**:
   ```bash
   kubectl top nodes
   kubectl top pods -n prod
   ```

---

## 🛠️ **Common Operations**

### Scaling Nodes

```hcl
# Edit terraform.tfvars
node_pool_count = 5  # Scale up to 5 nodes

# Apply changes
terraform apply
```

### Upgrading Kubernetes Version

```bash
# Check available versions
doctl kubernetes options versions

# Update terraform.tfvars
cluster_version = "1.29.0-do.0"

# Apply upgrade
terraform apply
```

### Adding a New Node Pool

```hcl
# In main.tf, add to kubernetes_cluster resource
node_pool {
  name       = "memory-intensive-pool"
  size       = "s-8vcpu-16gb"
  node_count = 2
  tags       = ["memory-intensive"]
}
```

### Destroying Infrastructure

```bash
# ⚠️ WARNING: This will delete everything!
terraform destroy

# To be safe, review first
terraform plan -destroy
```

---

## 🐛 **Troubleshooting**

### Issue: `Error: API rate limit exceeded`

**Solution**: Wait a few minutes and try again. Digital Ocean has API rate limits.

### Issue: `Cluster creation timeout`

**Solution**: Increase timeout in `modules/kubernetes/main.tf`:
```hcl
timeouts {
  create = "30m"
}
```

### Issue: `LoadBalancer stuck in pending`

**Check**:
```bash
kubectl get svc -n ingress-nginx
kubectl describe svc ingress-nginx-controller -n ingress-nginx
```

**Solution**: Wait 2-5 minutes. If still pending, check Digital Ocean dashboard for LoadBalancer status.

### Issue: `cert-manager not creating certificates`

**Check**:
```bash
kubectl get certificaterequest -A
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

**Solution**: Verify `letsencrypt_email` is set correctly and DNS is pointing to LoadBalancer IP.

### Issue: `Terraform state locked`

**Solution**:
```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

---

## 📖 **Additional Resources**

### Digital Ocean Documentation
- [Kubernetes on DO](https://docs.digitalocean.com/products/kubernetes/)
- [DOKS Pricing](https://www.digitalocean.com/pricing/kubernetes)
- [doctl Reference](https://docs.digitalocean.com/reference/doctl/)

### Terraform Documentation
- [Digital Ocean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

### Project Documentation
- [Main README](../../README.md)
- [Kubernetes Configs](../kubernetes/README.md)
- [Monitoring Setup](../kubernetes/monitoring/README.md)

---

## 🤝 **Contributing**

When modifying Terraform configs:

1. **Always run `terraform fmt`** before committing
2. **Never commit `terraform.tfvars`** (contains secrets)
3. **Update this README** if adding new variables or modules
4. **Test in a separate environment** before applying to prod

---

## 📝 **Notes**

- **State Management**: Currently using local state. For team collaboration, configure remote state backend (S3, Terraform Cloud, etc.)
- **Secrets**: API tokens are sensitive. Use environment variables or secret management tools in CI/CD.
- **Backups**: Digital Ocean automatically backs up Kubernetes cluster state, but application data should have separate backup strategy.

---

**Created by**: DevOps Team
**Last Updated**: November 2025
**Terraform Version**: >= 1.5.0
