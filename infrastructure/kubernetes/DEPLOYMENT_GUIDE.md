# Guía de Despliegue - DigitalOcean Kubernetes

Esta guía te ayudará a desplegar la aplicación E-Commerce en DigitalOcean Kubernetes después de ejecutar `terraform apply`.

---

## 📋 Pre-requisitos

✅ **Completado** (ya hecho):
- [x] Terraform configurado con backend remoto (Spaces)
- [x] Manifiestos de Kubernetes actualizados para DO
- [x] Storage classes corregidos a `do-block-storage`
- [x] API Gateway configurado con Ingress (sin LoadBalancer extra)
- [x] Secrets creados para PostgreSQL

⚠️ **Pendiente** (debes hacer):
- [ ] Crear Space en DigitalOcean
- [ ] Configurar Secrets de GitHub (SPACES_ACCESS_KEY, SPACES_SECRET_KEY)
- [ ] Ejecutar `terraform apply` para crear el cluster
- [ ] Configurar kubectl localmente
- [ ] Actualizar contraseña de PostgreSQL en el Secret

---

## 🚀 Paso 1: Ejecutar Terraform Apply

### Opción A: Desde GitHub Actions (Recomendado)

1. **Ir a**: https://github.com/tu-usuario/tu-repo/actions
2. **Seleccionar**: Terraform Infrastructure workflow
3. **Click en**: "Run workflow"
4. **Configurar**:
   ```
   action: plan
   environment: prod
   auto_approve: false
   ```
5. **Revisar el plan** y luego ejecutar nuevamente con `action: apply`

### Opción B: Desde tu máquina local

```bash
cd infrastructure/terraform

# Configurar credenciales
export AWS_ACCESS_KEY_ID="tu_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="tu_spaces_secret_key"
export DIGITALOCEAN_TOKEN="tu_do_token"

# Inicializar y planear
terraform init
terraform plan

# Aplicar (creará el cluster - toma ~10-15 minutos)
terraform apply
```

**Tiempo estimado**: 10-15 minutos

**Salida esperada**:
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

cluster_id = "abc123..."
cluster_endpoint = "https://abc123.k8s.ondigitalocean.com"
ingress_ip = "157.245.xxx.xxx"
```

---

## 🔧 Paso 2: Configurar kubectl

Una vez que el cluster esté creado:

```bash
# Obtener el cluster ID de la salida de Terraform
CLUSTER_ID=$(terraform output -raw cluster_id)

# Descargar kubeconfig
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# Verificar conexión
kubectl cluster-info
kubectl get nodes

# Output esperado:
# NAME                   STATUS   ROLES    AGE   VERSION
# worker-pool-xxxxx      Ready    <none>   5m    v1.31.9
# worker-pool-yyyyy      Ready    <none>   5m    v1.31.9
# worker-pool-zzzzz      Ready    <none>   5m    v1.31.9
```

---

## 🔐 Paso 3: Crear Secret de PostgreSQL

**IMPORTANTE**: Actualiza la contraseña antes de aplicar el secret.

```bash
# Generar contraseña segura
POSTGRES_PASSWORD=$(openssl rand -base64 32)
echo "Guarda esta contraseña en un lugar seguro: $POSTGRES_PASSWORD"

# Crear el secret
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_USER='ecommerce_user' \
  --from-literal=POSTGRES_DB='ecommerce_users' \
  -n prod

# Crear secret de conexión para aplicaciones
kubectl create secret generic postgres-connection \
  --from-literal=DATABASE_URL="postgresql://ecommerce_user:$POSTGRES_PASSWORD@postgresql:5432/ecommerce_users" \
  -n prod

# Verificar
kubectl get secrets -n prod
```

**Alternativa**: Editar y aplicar el archivo `postgres-secret.yaml`:

```bash
# 1. Editar el archivo y cambiar la contraseña
vi infrastructure/kubernetes/postgres-secret.yaml

# 2. Aplicar
kubectl apply -f infrastructure/kubernetes/postgres-secret.yaml
```

---

## 📦 Paso 4: Desplegar Infraestructura Base

```bash
cd infrastructure/kubernetes

# Crear namespaces
kubectl apply -f monitoring/namespace.yaml
kubectl apply -f tracing/namespace.yaml
kubectl apply -f logging/namespace.yaml

# Desplegar PostgreSQL
kubectl apply -f postgres-deployment.yaml

# Verificar que PostgreSQL esté funcionando
kubectl wait --for=condition=ready pod -l app=postgresql -n prod --timeout=300s
kubectl logs -l app=postgresql -n prod --tail=50
```

**Verificación**:
```bash
# Debería mostrar: 1/1 Running
kubectl get pods -n prod -l app=postgresql
```

---

## 🌐 Paso 5: Desplegar Servicios de Infraestructura

```bash
# Service Discovery (Eureka)
kubectl apply -f base/service-discovery.yaml

# Esperar a que esté listo
kubectl wait --for=condition=ready pod -l app=service-discovery --timeout=300s

# Verificar
kubectl logs -l app=service-discovery --tail=50
```

---

## 🚀 Paso 6: Desplegar Microservicios

```bash
# Desplegar todos los microservicios
kubectl apply -f base/user-service.yaml
kubectl apply -f base/product-service.yaml
kubectl apply -f base/order-service.yaml
kubectl apply -f base/payment-service.yaml
kubectl apply -f base/shipping-service.yaml
kubectl apply -f base/favourite-service.yaml
kubectl apply -f base/proxy-client.yaml

# API Gateway (último)
kubectl apply -f base/api-gateway.yaml

# Verificar que todos estén funcionando
kubectl get pods --watch

# Esperar a que todos estén en estado Running (puede tomar 5-10 minutos)
```

---

## 🌍 Paso 7: Configurar Ingress

```bash
# Aplicar Ingress
kubectl apply -f ingress.yaml

# Obtener la IP externa del Load Balancer
kubectl get ingress -A

# Output esperado:
# NAMESPACE   NAME                CLASS   HOSTS   ADDRESS            PORTS   AGE
# prod        ecommerce-ingress   nginx   *       157.245.xxx.xxx    80      1m
# dev         ecommerce-ingress   nginx   *       157.245.xxx.xxx    80      1m
```

**Guardar esta IP** - es la IP pública de tu aplicación.

---

## 🎯 Paso 8: Verificar Acceso

```bash
# Obtener la IP del Ingress
INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "API Gateway URL: http://$INGRESS_IP"

# Probar endpoints
curl http://$INGRESS_IP/actuator/health
curl http://$INGRESS_IP/app/api/products

# Resultado esperado:
# {"status":"UP"}
```

---

## 📊 Paso 9: Desplegar Monitoreo (Opcional)

```bash
# Prometheus
kubectl apply -f monitoring/prometheus-config.yaml
kubectl apply -f monitoring/prometheus-alert-rules.yaml
kubectl apply -f monitoring/prometheus.yaml

# Grafana
kubectl apply -f monitoring/grafana-config.yaml
kubectl apply -f monitoring/grafana.yaml

# Alertmanager
kubectl apply -f monitoring/alertmanager-config.yaml
kubectl apply -f monitoring/alertmanager.yaml

# Verificar
kubectl get pods -n monitoring
```

**Acceder a Grafana**:
```bash
# Port-forward local
kubectl port-forward -n monitoring svc/grafana 3000:80

# Abrir en navegador: http://localhost:3000
# Usuario: admin
# Contraseña: admin (cambiar al primer login)
```

---

## 🔍 Paso 10: Desplegar Tracing (Opcional)

```bash
# Jaeger
kubectl apply -f tracing/jaeger-all-in-one.yaml

# Verificar
kubectl get pods -n tracing

# Acceder a Jaeger UI
kubectl port-forward -n tracing svc/jaeger-query 16686:16686

# Abrir: http://localhost:16686
```

---

## ✅ Verificación Final

### Checklist de Verificación

```bash
# 1. Todos los pods están Running
kubectl get pods -A | grep -v Running | grep -v Completed

# Si hay pods no Running, investigar:
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# 2. Servicios expuestos
kubectl get svc -A

# 3. Ingress configurado
kubectl get ingress -A

# 4. PVCs bound
kubectl get pvc -A

# 5. Secrets creados
kubectl get secrets -A
```

### Test de Endpoints

```bash
INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Health checks
curl http://$INGRESS_IP/actuator/health

# Eureka dashboard
curl http://$INGRESS_IP/eureka/web

# Test API
curl http://$INGRESS_IP/app/api/products
curl http://$INGRESS_IP/app/api/users
```

---

## 🐛 Troubleshooting

### Problema: Pods en estado Pending

```bash
# Ver eventos del pod
kubectl describe pod <pod-name> -n <namespace>

# Causas comunes:
# 1. Insufficient resources
# 2. PVC no bound
# 3. Image pull error
```

**Solución para PVC**:
```bash
# Verificar PVC
kubectl get pvc -A

# Si está en Pending, verificar storage class
kubectl get pvc <pvc-name> -n <namespace> -o yaml | grep storageClassName
# Debería ser: do-block-storage
```

### Problema: ImagePullBackOff

```bash
# Ver detalles
kubectl describe pod <pod-name> -n <namespace>

# Causas:
# - Imagen no existe en Docker Hub
# - Tag incorrecto
# - Credenciales incorrectas

# Solución: Verificar que las imágenes existan
docker pull luisrojasc/<service-name>:latest
```

### Problema: CrashLoopBackOff

```bash
# Ver logs
kubectl logs <pod-name> -n <namespace> --previous

# Causas comunes:
# - Error en variables de entorno
# - Base de datos no accesible
# - Puerto incorrecto
```

### Problema: Servicios no se registran en Eureka

```bash
# Verificar logs de Eureka
kubectl logs -l app=service-discovery --tail=100

# Verificar variables de entorno del servicio
kubectl exec <pod-name> -n <namespace> -- env | grep EUREKA

# Debería tener:
# EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka/
```

---

## 📈 Monitoreo Continuo

```bash
# Ver logs en tiempo real
kubectl logs -f -l app=api-gateway

# Ver métricas de recursos
kubectl top nodes
kubectl top pods -A

# Ver eventos recientes
kubectl get events -A --sort-by='.lastTimestamp' | head -20
```

---

## 🔄 Actualización de Servicios

Después de ejecutar el pipeline de build, para desplegar una nueva versión:

```bash
# Obtener la nueva versión del build
VERSION_TAG="v0.1.0-20250112-123456"

# Actualizar la imagen
kubectl set image deployment/user-service \
  user-service=luisrojasc/user-service:$VERSION_TAG \
  -n prod

# Monitorear el rollout
kubectl rollout status deployment/user-service -n prod

# Si hay problemas, rollback
kubectl rollout undo deployment/user-service -n prod
```

**Usando el workflow de GitHub Actions**:
1. Ir a: Actions → Deploy to Production
2. Run workflow
3. Ingresar `service_versions`: `{"user-service":"v0.1.0-20250112-123456"}`

---

## 💰 Costos Estimados

| Recurso | Cantidad | Costo Mensual |
|---------|----------|---------------|
| Kubernetes Nodes (s-4vcpu-8gb) | 3 | $144 |
| Load Balancer (Ingress) | 1 | $12 |
| Block Storage (PostgreSQL) | 10 GB | ~$1 |
| Block Storage (Prometheus) | 10 GB | ~$1 |
| Block Storage (Grafana) | 5 GB | ~$0.50 |
| Spaces (Terraform State) | <1 GB | $5 |
| **TOTAL** | | **~$163.50/mes** |

---

## 📞 Soporte

Si encuentras problemas:

1. **Verificar logs**: `kubectl logs <pod-name> -n <namespace>`
2. **Verificar eventos**: `kubectl describe pod <pod-name> -n <namespace>`
3. **Verificar recursos**: `kubectl top pods -A`
4. **Consultar documentación**: `infrastructure/kubernetes/DEPLOYMENT_GUIDE.md`

---

**✅ Despliegue Completado!**

Tu aplicación E-Commerce ahora está funcionando en DigitalOcean Kubernetes con:
- ✅ Alta disponibilidad (3 nodos)
- ✅ Almacenamiento persistente
- ✅ Monitoreo con Prometheus y Grafana
- ✅ Tracing distribuido con Jaeger
- ✅ Ingress con NGINX
- ✅ Escalado automático configurado
