# ✅ Checklist Pre-Despliegue - E-Commerce Microservices

Este checklist asegura que todo esté listo antes de ejecutar `terraform apply` y desplegar la aplicación.

---

## 📋 FASE 1: Configuración de DigitalOcean

### 1.1 Crear DigitalOcean Space

- [ ] **Ir a**: https://cloud.digitalocean.com/spaces
- [ ] **Crear Space** con estas configuraciones:
  ```
  Nombre: ecommerce-terraform-state
  Región: nyc3
  CDN: Deshabilitado
  File Listing: Restricted (Private)
  ```
- [ ] **Verificar**: Space aparece en el listado

### 1.2 Generar Access Keys para Spaces

- [ ] **Ir a**: https://cloud.digitalocean.com/account/api/spaces
- [ ] **Generate New Key**:
  ```
  Nombre: terraform-backend
  ```
- [ ] **Guardar las credenciales** (se muestran una sola vez):
  - [ ] Access Key ID: `DO00...`
  - [ ] Secret Access Key: `abc...`

### 1.3 Verificar Límites de la Cuenta

- [ ] **Droplet limit**: Mínimo 3 (actual: 3) ✅
- [ ] **Región preferida**: nyc1 disponible ✅
- [ ] **Email verificado**: Sí ✅

---

## 📋 FASE 2: Configuración de GitHub

### 2.1 Secrets de GitHub

Ir a: **Settings** → **Secrets and variables** → **Actions**

- [ ] `DO_TOKEN` - Token de API de DigitalOcean
  ```
  Valor: dop_v1_...
  ```

- [ ] `SPACES_ACCESS_KEY` - Access Key ID de Spaces
  ```
  Valor: DO00...
  ```

- [ ] `SPACES_SECRET_KEY` - Secret Access Key de Spaces
  ```
  Valor: abc...
  ```

- [ ] `LETSENCRYPT_EMAIL` - Email para certificados SSL
  ```
  Valor: tu-email@example.com
  ```

### 2.2 Verificar Secrets

```bash
# Ir a Actions → Terraform Infrastructure → Run workflow
# Si no hay errores de "secret not found", están bien configurados
```

---

## 📋 FASE 3: Verificación Local de Archivos

### 3.1 Archivos de Terraform Corregidos

- [x] `infrastructure/terraform/versions.tf` - Backend configurado ✅
- [x] `infrastructure/terraform/variables.tf` - Versión K8s actualizada ✅
- [x] `infrastructure/terraform/variables.tf` - max_nodes = 3 ✅
- [x] `.github/workflows/terraform.yml` - Versión K8s actualizada ✅

### 3.2 Archivos de Kubernetes Corregidos

- [x] `infrastructure/kubernetes/postgres-deployment.yaml` - Storage class corregido ✅
- [x] `infrastructure/kubernetes/postgres-secret.yaml` - Secret creado ✅
- [x] `infrastructure/kubernetes/base/api-gateway.yaml` - ClusterIP configurado ✅
- [x] `infrastructure/kubernetes/ingress.yaml` - Ingress creado ✅
- [x] `infrastructure/kubernetes/monitoring/prometheus.yaml` - Storage class corregido ✅
- [x] `infrastructure/kubernetes/monitoring/grafana.yaml` - Storage class corregido ✅

### 3.3 Scripts de Deployment

- [x] `infrastructure/kubernetes/deploy.sh` - Script creado y ejecutable ✅
- [x] `infrastructure/kubernetes/DEPLOYMENT_GUIDE.md` - Guía completa creada ✅

---

## 📋 FASE 4: Preparación del Estado de Terraform

### 4.1 Si es la Primera Vez

```bash
cd infrastructure/terraform

# Configurar credenciales
export AWS_ACCESS_KEY_ID="tu_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="tu_spaces_secret_key"

# Inicializar
terraform init

# Salida esperada:
# Terraform has been successfully initialized!
```

- [ ] `terraform init` ejecutado sin errores
- [ ] Backend remoto configurado (Spaces)

### 4.2 Si Ya Existe Estado Local

```bash
# Hacer backup
cp terraform.tfstate terraform.tfstate.backup

# Migrar al backend remoto
terraform init -migrate-state

# Cuando pregunte, responder: yes
```

- [ ] Estado migrado a Spaces
- [ ] Backup del estado local guardado

---

## 📋 FASE 5: Validación de Terraform

### 5.1 Validar Configuración

```bash
cd infrastructure/terraform

terraform validate
# Salida esperada: Success! The configuration is valid.
```

- [ ] Terraform validate exitoso

### 5.2 Ver Plan (Sin Aplicar)

```bash
terraform plan

# Revisar que muestre:
# Plan: 15 to add, 0 to change, 0 to destroy
```

- [ ] Plan revisado
- [ ] Recursos a crear son correctos:
  - [ ] 1 Kubernetes cluster
  - [ ] 1 Node pool
  - [ ] 4 Namespaces
  - [ ] 1 Storage class
  - [ ] Helm releases (Ingress NGINX, Cert-Manager)

---

## 📋 FASE 6: Recursos y Costos

### 6.1 Estimación de Costos

| Recurso | Cantidad | Costo Mensual |
|---------|----------|---------------|
| Kubernetes Nodes | 3 × s-4vcpu-8gb | $144 |
| Load Balancer | 1 | $12 |
| Block Storage | ~25 GB | ~$2.50 |
| Spaces | 1 GB | $5 |
| **TOTAL** | | **~$163.50/mes** |

- [ ] **Presupuesto aprobado**: ~$164/mes

### 6.2 Distribución de RAM

| Componente | RAM Requerida | Disponible |
|------------|---------------|------------|
| Sistema Kubernetes | ~4GB | 24GB |
| Microservicios (9) | ~10GB | 20GB |
| PostgreSQL | 1GB | 19GB |
| **Disponible para monitoring** | | **~9GB** |

- [ ] **RAM suficiente**: 24GB total ✅

---

## 📋 FASE 7: Imágenes Docker

### 7.1 Verificar que las Imágenes Existen

```bash
# Verificar en Docker Hub
docker pull luisrojasc/service-discovery:latest
docker pull luisrojasc/api-gateway:latest
docker pull luisrojasc/user-service:latest
docker pull luisrojasc/product-service:latest
docker pull luisrojasc/order-service:latest
docker pull luisrojasc/payment-service:latest
docker pull luisrojasc/shipping-service:latest
docker pull luisrojasc/favourite-service:latest
docker pull luisrojasc/proxy-client:latest
```

- [ ] Todas las imágenes existen en Docker Hub
- [ ] Tag `latest` disponible para todas

---

## 📋 FASE 8: Preparar Contraseña de PostgreSQL

### 8.1 Generar Contraseña Segura

```bash
# Generar contraseña
openssl rand -base64 32

# O usar este comando para generarla y guardarla
POSTGRES_PASSWORD=$(openssl rand -base64 32)
echo "PostgreSQL Password: $POSTGRES_PASSWORD" > postgres-credentials.txt
chmod 600 postgres-credentials.txt
```

- [ ] Contraseña generada
- [ ] Contraseña guardada en lugar seguro
- [ ] **NO commitear** `postgres-credentials.txt` al repositorio

---

## 📋 FASE 9: Pre-Flight Final

### 9.1 Verificaciones Finales

- [ ] **CLI Tools instalados**:
  - [ ] `kubectl` instalado
  - [ ] `doctl` instalado
  - [ ] `terraform` instalado (>= 1.5.0)
  - [ ] `git` instalado

- [ ] **Conectividad**:
  - [ ] Internet disponible
  - [ ] Acceso a DigitalOcean
  - [ ] Acceso a GitHub

- [ ] **Credenciales**:
  - [ ] DO Token válido
  - [ ] Spaces Keys válidas
  - [ ] GitHub Secrets configurados

---

## 🚀 LISTO PARA DESPLEGAR

Si todos los checkboxes están marcados, estás listo para:

### Opción 1: GitHub Actions (Recomendado)

```
1. Ir a: Actions → Terraform Infrastructure
2. Click: Run workflow
3. Configurar:
   - action: plan
   - environment: prod
   - auto_approve: false
4. Revisar el plan
5. Ejecutar nuevamente con action: apply
```

### Opción 2: Local

```bash
cd infrastructure/terraform

# Configurar credenciales
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
export DIGITALOCEAN_TOKEN="your_token"

# Aplicar
terraform apply

# Tiempo estimado: 10-15 minutos
```

---

## 📝 Orden de Despliegue Post-Terraform

Después de `terraform apply`, ejecutar en este orden:

1. **Configurar kubectl**
   ```bash
   doctl kubernetes cluster kubeconfig save $(terraform output -raw cluster_id)
   ```

2. **Crear PostgreSQL Secret**
   ```bash
   kubectl create secret generic postgres-secret \
     --from-literal=POSTGRES_PASSWORD='tu_contraseña_segura' \
     --from-literal=POSTGRES_USER='ecommerce_user' \
     --from-literal=POSTGRES_DB='ecommerce_users' \
     -n prod
   ```

3. **Ejecutar Script de Deployment**
   ```bash
   cd infrastructure/kubernetes
   ./deploy.sh prod
   ```

4. **Verificar Deployment**
   ```bash
   kubectl get pods -n prod
   kubectl get ingress -n prod
   ```

---

## ⚠️ Problemas Comunes y Soluciones

### Terraform apply falla con "insufficient quota"

**Solución**: Contacta a DigitalOcean para aumentar el límite de droplets

### Pods en estado Pending

**Solución**: Verifica que el storage class sea `do-block-storage`

### ImagePullBackOff

**Solución**: Verifica que las imágenes existan en Docker Hub

### Ingress sin IP

**Solución**: Espera 2-5 minutos, el LoadBalancer tarda en asignarse

---

## 📞 Recursos de Ayuda

- **Documentación completa**: `infrastructure/kubernetes/DEPLOYMENT_GUIDE.md`
- **Backend de Terraform**: `infrastructure/terraform/BACKEND_SETUP.md`
- **Issues del proyecto**: GitHub Issues

---

**✅ Estás listo para desplegar cuando todos los checkboxes estén marcados!**
