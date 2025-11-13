# Guía de Despliegue Paso a Paso - E-Commerce Microservices

Esta guía te llevará desde cero hasta tener tu aplicación completamente desplegada en DigitalOcean Kubernetes.

**Tiempo estimado total: 30-40 minutos**

---

## Requisitos Previos

Antes de empezar, asegúrate de tener:

- [ ] Cuenta de DigitalOcean con al menos $20 de crédito
- [ ] Cuenta de GitHub con acceso al repositorio
- [ ] Acceso de administrador al repositorio (para configurar Secrets)
- [ ] Terminal/consola en tu máquina local
- [ ] Git instalado localmente

---

## FASE 1: Configurar DigitalOcean Space (10 minutos)

### Paso 1.1: Crear el Space para Estado de Terraform

1. **Abrir navegador** e ir a: https://cloud.digitalocean.com/spaces

2. **Click en "Create Space"** (botón azul en la esquina superior derecha)

3. **Configurar el Space con estos valores EXACTOS:**
   ```
   Choose a datacenter region: New York 3 (NYC3)

   Enable CDN: NO (dejarlo deshabilitado)

   Space name: ecommerce-terraform-state

   Select a project: Default Project (o el proyecto que prefieras)

   File Listing: Restrict File Listing (Private)
   ```

4. **Click en "Create a Space"**

5. **Verificar**: Deberías ver el Space creado en la lista

**IMPORTANTE:** Usa exactamente `ecommerce-terraform-state` como nombre, ya que está hardcodeado en `infrastructure/terraform/versions.tf:17`

---

### Paso 1.2: Generar Access Keys para Spaces

1. **Ir a**: https://cloud.digitalocean.com/account/api/spaces

2. **Click en "Generate New Key"**

3. **Configurar:**
   ```
   Name: terraform-backend
   ```

4. **Click en "Generate Key"**

5. **GUARDAR INMEDIATAMENTE** (se muestran solo una vez):
   ```
   Access Key ID: DO00XXXXXXXXXXXXXXXXX
   Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

6. **Copiar a un archivo temporal** en tu máquina (NO commitear):
   ```bash
   # En tu terminal local
   cat > ~/do-credentials.txt << 'EOF'
   SPACES_ACCESS_KEY=DO00XXXXXXXXXXXXXXXXX
   SPACES_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   EOF

   chmod 600 ~/do-credentials.txt
   ```

---

### Paso 1.3: Generar Token de API de DigitalOcean

1. **Ir a**: https://cloud.digitalocean.com/account/api/tokens

2. **Click en "Generate New Token"**

3. **Configurar:**
   ```
   Token name: ecommerce-k8s-deployment
   Scopes: Read and Write (ambos checkboxes marcados)
   Expiration: No expiration (o 90 days si prefieres)
   ```

4. **Click en "Generate Token"**

5. **GUARDAR INMEDIATAMENTE** (se muestra solo una vez):
   ```
   Token: dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

6. **Añadir al archivo temporal:**
   ```bash
   echo "DO_TOKEN=dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" >> ~/do-credentials.txt
   ```

---

## FASE 2: Configurar GitHub Secrets (5 minutos)

### Paso 2.1: Ir a la Configuración de Secrets

1. **Ir a tu repositorio en GitHub:**
   ```
   https://github.com/Lrojas898/ecommerce-microservice-backend-app
   ```

2. **Navegar a:**
   ```
   Settings → Secrets and variables → Actions
   ```

3. **Click en "New repository secret"**

---

### Paso 2.2: Crear los 4 Secrets Requeridos

**Secret 1: DO_TOKEN**
```
Name: DO_TOKEN
Secret: dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
(El token que generaste en Paso 1.3)

Click "Add secret"

---

**Secret 2: SPACES_ACCESS_KEY**
```
Name: SPACES_ACCESS_KEY
Secret: DO00XXXXXXXXXXXXXXXXX
```
(El Access Key ID del Paso 1.2)

Click "Add secret"

---

**Secret 3: SPACES_SECRET_KEY**
```
Name: SPACES_SECRET_KEY
Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
(El Secret Access Key del Paso 1.2)

Click "Add secret"

---

**Secret 4: LETSENCRYPT_EMAIL**
```
Name: LETSENCRYPT_EMAIL
Secret: tu-email@example.com
```
(Tu email real para recibir notificaciones de certificados SSL)

Click "Add secret"

---

### Paso 2.3: Verificar Secrets

Deberías ver 4 secrets en la lista:
- `DO_TOKEN`
- `SPACES_ACCESS_KEY`
- `SPACES_SECRET_KEY`
- `LETSENCRYPT_EMAIL`

---

## FASE 3: Ejecutar Pipeline de Terraform (15 minutos)

### Paso 3.1: Ir a GitHub Actions

1. **En tu repositorio, click en la pestaña "Actions"**

2. **En el menú izquierdo, buscar y click en:**
   ```
   Terraform Infrastructure
   ```

---

### Paso 3.2: Ejecutar Plan (Revisión)

1. **Click en "Run workflow"** (botón gris/azul en la derecha)

2. **Configurar el workflow:**
   ```
   Use workflow from: Branch: master

   Terraform action: plan

   Environment: prod

   Kubernetes version: 1.31.9-do.5

   Node pool min nodes: 3

   Node pool max nodes: 3

   Auto approve: false
   ```

3. **Click en "Run workflow"** (botón verde)

4. **Esperar 2-3 minutos** hasta que termine

5. **Click en el workflow ejecutándose** para ver los detalles

6. **Revisar el plan en los logs:**
   - Debe mostrar: `Plan: 15 to add, 0 to change, 0 to destroy`
   - Verificar que va a crear:
     - 1 Kubernetes cluster
     - 1 Node pool (3 nodos)
     - 4 Namespaces
     - 1 Storage class
     - Helm releases (Ingress NGINX, Cert-Manager)

---

### Paso 3.3: Ejecutar Apply (Crear Infraestructura)

**SOLO SI EL PLAN SE VIO CORRECTO**, proceder:

1. **Click en "Run workflow"** nuevamente

2. **Configurar el workflow:**
   ```
   Use workflow from: Branch: master

   Terraform action: apply

   Environment: prod

   Kubernetes version: 1.31.9-do.5

   Node pool min nodes: 3

   Node pool max nodes: 3

   Auto approve: false
   ```

3. **Click en "Run workflow"**

4. **Esperar 10-15 minutos** (DigitalOcean está creando el cluster)

5. **Monitorear el progreso** en los logs

6. **Al finalizar, deberías ver:**
   ```
   Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

   Outputs:

   cluster_id = "abc-123-def-456-ghi-789"
   cluster_endpoint = "https://abc123.k8s.ondigitalocean.com"
   ingress_ip = "157.245.xxx.xxx"
   ```

7. **GUARDAR EL cluster_id** - lo necesitarás en el siguiente paso

---

## FASE 4: Configurar kubectl Local (5 minutos)

### Paso 4.1: Instalar doctl (si no lo tienes)

**Ubuntu/Debian:**
```bash
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin
```

**macOS:**
```bash
brew install doctl
```

**Windows (WSL):**
```bash
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin
```

**Verificar instalación:**
```bash
doctl version
```

---

### Paso 4.2: Autenticar doctl

```bash
doctl auth init
```

**Cuando pregunte:**
```
Please authenticate doctl for use with your DigitalOcean account. You can generate a token in the control panel at https://cloud.digitalocean.com/account/api/tokens

Enter your access token:
```

**Pegar tu DO_TOKEN** (el que guardaste en ~/do-credentials.txt)

**Verificar:**
```bash
doctl account get
```

Deberías ver la información de tu cuenta.

---

### Paso 4.3: Configurar kubectl

```bash
# Reemplaza abc-123-def-456-ghi-789 con el cluster_id que obtuviste en Paso 3.3
doctl kubernetes cluster kubeconfig save abc-123-def-456-ghi-789
```

**Salida esperada:**
```
Notice: Adding cluster credentials to kubeconfig file found in "/home/user/.kube/config"
Notice: Setting current-context to do-nyc1-ecommerce-k8s-cluster
```

---

### Paso 4.4: Verificar Conexión al Cluster

```bash
# Ver información del cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Deberías ver 3 nodos en estado Ready:
# NAME                   STATUS   ROLES    AGE   VERSION
# pool-xxxxx-xxxxx       Ready    <none>   5m    v1.31.9
# pool-xxxxx-yyyyy       Ready    <none>   5m    v1.31.9
# pool-xxxxx-zzzzz       Ready    <none>   5m    v1.31.9
```

**Si ves los 3 nodos en Ready, ¡perfecto!** Continúa al siguiente paso.

---

## FASE 5: Verificar Imágenes Docker (2 minutos)

Antes de desplegar, verifica que tus imágenes existen en Docker Hub.

```bash
# Verificar que puedes hacer pull de las imágenes
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

**Si alguna imagen falla:**
- Necesitas ejecutar el pipeline de build primero
- O verificar que las imágenes estén publicadas en Docker Hub

**Si todas funcionan:** Continúa al siguiente paso.

---

## FASE 6: Crear Secret de PostgreSQL (2 minutos)

### Paso 6.1: Generar Contraseña Segura

```bash
# Generar contraseña aleatoria de 32 caracteres
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Mostrarla en pantalla
echo "PostgreSQL Password: $POSTGRES_PASSWORD"

# Guardarla en archivo seguro (NO commitear)
echo "PostgreSQL Password: $POSTGRES_PASSWORD" > ~/postgres-credentials.txt
chmod 600 ~/postgres-credentials.txt

# Guardar también en tus notas/password manager
```

**IMPORTANTE:** Guarda esta contraseña en un lugar seguro. La necesitarás si alguna vez necesitas acceder directamente a PostgreSQL.

---

### Paso 6.2: Crear Secret en Kubernetes

```bash
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_USER='ecommerce_user' \
  --from-literal=POSTGRES_DB='ecommerce_users' \
  -n prod
```

**Salida esperada:**
```
secret/postgres-secret created
```

---

### Paso 6.3: Verificar Secret

```bash
kubectl get secret postgres-secret -n prod

# Salida esperada:
# NAME              TYPE     DATA   AGE
# postgres-secret   Opaque   3      10s
```

---

## FASE 7: Desplegar Aplicaciones (10 minutos)

### Paso 7.1: Navegar al Directorio de Kubernetes

```bash
cd infrastructure/kubernetes
```

---

### Paso 7.2: Dar Permisos de Ejecución al Script

```bash
chmod +x deploy.sh
```

---

### Paso 7.3: Ejecutar Script de Despliegue

```bash
./deploy.sh prod
```

**El script te mostrará:**
```
============================================================
  E-Commerce Microservices Deployment
============================================================

Environment: prod
Cluster: do-nyc1-ecommerce-k8s-cluster

Continue with deployment? (y/n)
```

**Escribir: `y` y presionar ENTER**

---

### Paso 7.4: Monitorear el Despliegue

El script ejecutará automáticamente:

1. ✓ Verificando prerrequisitos
2. ✓ Creando namespaces
3. ✓ Verificando postgres-secret
4. ✓ Desplegando PostgreSQL
5. ✓ Esperando a que PostgreSQL esté listo
6. ✓ Desplegando Service Discovery (Eureka)
7. ✓ Esperando 30s para que Eureka se estabilice
8. ✓ Desplegando microservicios (user, product, order, payment, shipping, favourite, proxy-client)
9. ✓ Desplegando API Gateway
10. ✓ Desplegando Ingress
11. ✓ Verificando deployment
12. ✓ Mostrando información de acceso

**Tiempo estimado:** 5-10 minutos

---

### Paso 7.5: Resultado Esperado

Al finalizar, deberías ver:

```
============================================================
  Deployment Complete!
============================================================
✓ All services have been deployed to namespace 'prod'

Monitor pods: kubectl get pods -n prod --watch
View logs: kubectl logs -f -l app=api-gateway -n prod
Port forward: kubectl port-forward -n prod svc/api-gateway 8080:80

API Gateway URL: http://157.245.xxx.xxx
```

---

## FASE 8: Verificar Deployment (5 minutos)

### Paso 8.1: Verificar Pods

```bash
kubectl get pods -n prod
```

**Resultado esperado:** Todos los pods en estado `Running`

```
NAME                                READY   STATUS    RESTARTS   AGE
postgresql-xxxxx                    1/1     Running   0          8m
service-discovery-xxxxx             1/1     Running   0          7m
user-service-xxxxx                  1/1     Running   0          6m
product-service-xxxxx               1/1     Running   0          6m
order-service-xxxxx                 1/1     Running   0          6m
payment-service-xxxxx               1/1     Running   0          6m
shipping-service-xxxxx              1/1     Running   0          6m
favourite-service-xxxxx             1/1     Running   0          6m
proxy-client-xxxxx                  1/1     Running   0          6m
api-gateway-xxxxx                   1/1     Running   0          5m
```

**Si algún pod está en estado `Pending`, `CrashLoopBackOff`, o `ImagePullBackOff`:**

```bash
# Ver detalles del pod
kubectl describe pod <nombre-del-pod> -n prod

# Ver logs del pod
kubectl logs <nombre-del-pod> -n prod
```

---

### Paso 8.2: Verificar Servicios

```bash
kubectl get svc -n prod
```

**Resultado esperado:**

```
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
postgresql          ClusterIP   10.245.x.x       <none>        5432/TCP   8m
service-discovery   ClusterIP   10.245.x.x       <none>        8761/TCP   7m
user-service        ClusterIP   10.245.x.x       <none>        8081/TCP   6m
product-service     ClusterIP   10.245.x.x       <none>        8082/TCP   6m
order-service       ClusterIP   10.245.x.x       <none>        8083/TCP   6m
payment-service     ClusterIP   10.245.x.x       <none>        8084/TCP   6m
shipping-service    ClusterIP   10.245.x.x       <none>        8085/TCP   6m
favourite-service   ClusterIP   10.245.x.x       <none>        8086/TCP   6m
proxy-client        ClusterIP   10.245.x.x       <none>        8087/TCP   6m
api-gateway         ClusterIP   10.245.x.x       <none>        80/TCP     5m
```

---

### Paso 8.3: Verificar Ingress

```bash
kubectl get ingress -n prod
```

**Resultado esperado:**

```
NAME                CLASS   HOSTS   ADDRESS          PORTS   AGE
ecommerce-ingress   nginx   *       157.245.xxx.xxx  80      5m
```

**IMPORTANTE:** Espera 2-5 minutos si el ADDRESS aparece como `<pending>`. El LoadBalancer de DigitalOcean tarda un poco en asignarse.

---

### Paso 8.4: Obtener IP Pública

```bash
INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "API Gateway URL: http://$INGRESS_IP"
```

**Guardar esta IP** - es la URL pública de tu aplicación.

---

### Paso 8.5: Probar Endpoints

```bash
# Health check del API Gateway
curl http://$INGRESS_IP/actuator/health

# Resultado esperado:
# {"status":"UP"}

# Eureka dashboard (en navegador)
echo "Eureka: http://$INGRESS_IP/eureka/web"

# Test de API de productos
curl http://$INGRESS_IP/app/api/products

# Test de API de usuarios
curl http://$INGRESS_IP/app/api/users
```

**Si todos funcionan:** ¡Felicidades! Tu aplicación está desplegada y funcionando.

---

## FASE 9: Monitoreo (Opcional - 5 minutos)

Si quieres desplegar Prometheus y Grafana:

### Paso 9.1: Desplegar Monitoreo

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

---

### Paso 9.2: Acceder a Grafana

```bash
# Port-forward a Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# En tu navegador, ir a:
# http://localhost:3000

# Credenciales por defecto:
# Usuario: admin
# Contraseña: admin123
```

**IMPORTANTE:** Cambia la contraseña de Grafana en el primer login.

---

## Resumen de URLs y Credenciales

Guarda esta información en un lugar seguro:

### URLs Públicas

```
API Gateway: http://INGRESS_IP
Eureka Dashboard: http://INGRESS_IP/eureka/web
Health Check: http://INGRESS_IP/actuator/health
```

### Acceso a Servicios (Port-Forward)

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# URL: http://localhost:3000
# Usuario: admin / Contraseña: admin123

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# URL: http://localhost:9090

# Jaeger (si lo desplegaste)
kubectl port-forward -n tracing svc/jaeger-query 16686:16686
# URL: http://localhost:16686
```

### Credenciales PostgreSQL

```
Host (interno): postgresql.prod.svc.cluster.local
Port: 5432
Database: ecommerce_users
User: ecommerce_user
Password: (ver ~/postgres-credentials.txt)
```

---

## Comandos Útiles Post-Despliegue

### Ver logs en tiempo real

```bash
# API Gateway
kubectl logs -f -l app=api-gateway -n prod

# Eureka
kubectl logs -f -l app=service-discovery -n prod

# Todos los pods
kubectl logs -f -l app=user-service -n prod
```

---

### Ver métricas de recursos

```bash
# Uso de nodos
kubectl top nodes

# Uso de pods
kubectl top pods -n prod
```

---

### Reiniciar un deployment

```bash
kubectl rollout restart deployment/user-service -n prod
```

---

### Escalar un servicio

```bash
kubectl scale deployment/user-service --replicas=2 -n prod
```

---

## Troubleshooting

### Problema: Pod en estado Pending

```bash
kubectl describe pod <pod-name> -n prod

# Causas comunes:
# - Insufficient resources
# - PVC no bound
# - Image pull error
```

**Solución:**
```bash
# Ver eventos del cluster
kubectl get events -n prod --sort-by='.lastTimestamp'
```

---

### Problema: ImagePullBackOff

```bash
kubectl describe pod <pod-name> -n prod

# Causa: Imagen no existe en Docker Hub
```

**Solución:** Ejecuta el pipeline de build para crear las imágenes.

---

### Problema: CrashLoopBackOff

```bash
kubectl logs <pod-name> -n prod --previous

# Causas comunes:
# - Error en configuración
# - Base de datos no accesible
# - Puerto ya en uso
```

---

### Problema: Ingress sin IP

```bash
kubectl get ingress -n prod

# Si ADDRESS está <pending>
```

**Solución:** Espera 2-5 minutos. El LoadBalancer de DigitalOcean tarda en asignarse.

---

### Problema: Eureka no muestra servicios

```bash
# Verificar que Eureka está running
kubectl get pods -l app=service-discovery -n prod

# Ver logs de Eureka
kubectl logs -l app=service-discovery -n prod

# Verificar variables de entorno de un servicio
kubectl exec <pod-name> -n prod -- env | grep EUREKA
```

---

## Costos Mensuales Estimados

| Recurso | Cantidad | Costo Mensual |
|---------|----------|---------------|
| Kubernetes Nodes (s-4vcpu-8gb) | 3 | $144.00 |
| Load Balancer (Ingress) | 1 | $12.00 |
| Block Storage (PostgreSQL) | 10 GB | $1.00 |
| Block Storage (Prometheus) | 10 GB | $1.00 |
| Block Storage (Grafana) | 5 GB | $0.50 |
| Spaces (Terraform State) | <1 GB | $5.00 |
| **TOTAL** | | **$163.50/mes** |

---

## Limpieza de Recursos (Destruir Todo)

**ADVERTENCIA:** Esto eliminará TODA la infraestructura y TODOS los datos.

### Opción 1: Via GitHub Actions

```
1. Ir a: Actions → Terraform Infrastructure
2. Run workflow
3. Configurar:
   - action: destroy
   - environment: prod
   - auto_approve: false
4. Run workflow
```

---

### Opción 2: Via Local

```bash
cd infrastructure/terraform

export AWS_ACCESS_KEY_ID="tu_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="tu_spaces_secret_key"
export DIGITALOCEAN_TOKEN="tu_do_token"

terraform destroy

# Escribir: yes cuando pregunte
```

---

## Soporte y Ayuda

Si encuentras problemas:

1. **Revisar logs:** `kubectl logs <pod-name> -n prod`
2. **Revisar eventos:** `kubectl describe pod <pod-name> -n prod`
3. **Revisar documentación:** `infrastructure/kubernetes/DEPLOYMENT_GUIDE.md`
4. **Consultar checklist:** `PRE_DEPLOYMENT_CHECKLIST.md`

---

## ✅ Checklist Final

- [ ] Space creado en DigitalOcean (nyc3)
- [ ] Access Keys generadas
- [ ] DO Token generado
- [ ] GitHub Secrets configurados (4 secrets)
- [ ] Terraform apply ejecutado exitosamente
- [ ] kubectl configurado y conectado
- [ ] PostgreSQL secret creado
- [ ] Aplicaciones desplegadas
- [ ] Todos los pods en estado Running
- [ ] Ingress con IP pública asignada
- [ ] Endpoints funcionando correctamente

**Si todos están marcados:** ¡Tu aplicación está completamente desplegada! 🎉

---

**Última actualización:** 2025-01-12
**Versión Kubernetes:** 1.31.9-do.5
**Región:** NYC3 (New York 3)
