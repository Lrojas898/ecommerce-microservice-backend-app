# Estado de Servicios de Logging (ELK Stack)

**Fecha:** 2025-11-13
**Cluster:** DigitalOcean Kubernetes

---

## 📋 Resumen Ejecutivo

### ✅ Configuración Lista
- ✅ Directorio `infrastructure/kubernetes/logging/` existe
- ✅ Manifiestos completos de ELK Stack
- ✅ Script de deployment automatizado
- ✅ Namespace `logging` creado en el cluster

### ❌ Servicios NO Desplegados
- ❌ **0 pods** en el namespace logging
- ❌ **0 servicios** activos
- ❌ **0 ingress** configurados
- ❌ ELK Stack **NO está activo**

---

## 🔍 Comparación con Grafana/Prometheus

| Aspecto | Grafana/Prometheus | ELK Stack (Logging) |
|---------|-------------------|---------------------|
| **Configuración** | ✅ Archivos YAML listos | ✅ Archivos YAML listos |
| **Namespace** | ✅ `monitoring` existe | ✅ `logging` existe |
| **Pods Desplegados** | ✅ 3/3 Running | ❌ 0 pods |
| **Servicios Activos** | ✅ Grafana, Prometheus, Alertmanager | ❌ Ninguno |
| **Ingress** | ✅ monitoring-ingress activo | ❌ No configurado |
| **Acceso Público** | ✅ http://137.184.240.48/grafana/ | ❌ No accesible |
| **Estado** | 🟢 **ACTIVO** | 🔴 **NO DESPLEGADO** |

---

## 📦 Componentes Configurados (No Activos)

### 1. Elasticsearch 8.11.0
**Propósito:** Motor de búsqueda y almacenamiento de logs

**Configuración:**
```yaml
Archivo: elasticsearch.yaml
Imagen: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
Recursos:
  - Memory: 2Gi request, 4Gi limit
  - CPU: 500m request, 1000m limit
  - Storage: PersistentVolumeClaim 5Gi
Modo: single-node (desarrollo)
Puerto: 9200 (ClusterIP)
NodePort: 30920 (acceso externo)
```

### 2. Kibana 8.11.0
**Propósito:** UI para visualización y análisis de logs

**Configuración:**
```yaml
Archivo: kibana.yaml
Imagen: docker.elastic.co/kibana/kibana:8.11.0
Recursos:
  - Memory: 512Mi request, 1Gi limit
  - CPU: 200m request, 500m limit
Puerto: 5601 (ClusterIP)
NodePort: 30561 (acceso externo)
```

### 3. Filebeat 8.11.0
**Propósito:** Recolector de logs de containers

**Configuración:**
```yaml
Archivo: filebeat.yaml
Imagen: docker.elastic.co/beats/filebeat:8.11.0
Tipo: DaemonSet (corre en cada nodo)
Recolecta: Logs de /var/log/containers/
Envía a: Elasticsearch
```

---

## 🚀 Cómo Desplegar ELK Stack

### Opción 1: Script Automatizado (RECOMENDADO)

```bash
cd infrastructure/kubernetes/logging

# Dar permisos de ejecución
chmod +x deploy-elk.sh

# Desplegar
./deploy-elk.sh
```

**Tiempo estimado:** 5-7 minutos

**El script hace:**
1. ✅ Crea namespace logging
2. ✅ Despliega Elasticsearch (espera ~3 min)
3. ✅ Despliega Kibana (espera ~2 min)
4. ✅ Despliega Filebeat ConfigMap
5. ✅ Despliega Filebeat DaemonSet
6. ✅ Verifica deployment

### Opción 2: Despliegue Manual

```bash
cd infrastructure/kubernetes/logging

# 1. Crear namespace
kubectl apply -f namespace.yaml

# 2. Desplegar Elasticsearch
kubectl apply -f elasticsearch.yaml

# Esperar a que esté listo (2-3 minutos)
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n logging

# 3. Desplegar Kibana
kubectl apply -f kibana.yaml

# Esperar a que esté listo (1-2 minutos)
kubectl wait --for=condition=available --timeout=240s deployment/kibana -n logging

# 4. Desplegar Filebeat
kubectl apply -f filebeat-config.yaml
kubectl apply -f filebeat.yaml

# 5. Verificar
kubectl get all -n logging
```

---

## 🌐 URLs de Acceso (Después de Desplegar)

### Usando NodePort (DigitalOcean K8s)

**Kibana UI:**
```bash
# Obtener IP de un nodo
kubectl get nodes -o wide

# Acceder vía NodePort
http://<NODE-IP>:30561
```

**Elasticsearch API:**
```bash
http://<NODE-IP>:30920
```

### Usando Port-Forward (Recomendado para Testing)

**Kibana:**
```bash
kubectl port-forward -n logging svc/kibana 5601:5601

# Acceder en navegador
http://localhost:5601
```

**Elasticsearch:**
```bash
kubectl port-forward -n logging svc/elasticsearch 9200:9200

# Verificar salud
curl http://localhost:9200/_cluster/health | jq '.'
```

### Configurar Ingress (Para Acceso Similar a Grafana)

Actualmente **NO existe** un Ingress para ELK Stack. Para tener acceso similar a Grafana:

**Crear `logging-ingress.yaml`:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: logging-ingress
  namespace: logging
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
    nginx.ingress.kubernetes.io/use-regex: "true"
  labels:
    app: logging
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      # Kibana
      - path: /kibana(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: kibana
            port:
              number: 5601

      # Elasticsearch (opcional, mejor no exponer públicamente)
      - path: /elasticsearch(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: elasticsearch
            port:
              number: 9200
```

**Aplicar:**
```bash
kubectl apply -f logging-ingress.yaml

# Acceder igual que Grafana/Prometheus
http://137.184.240.48/kibana/
```

---

## 📊 Recursos Necesarios

### Por Componente

| Componente | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|------------|-------------|-----------|----------------|--------------|---------|
| Elasticsearch | 500m | 1000m | 2Gi | 4Gi | 5Gi PVC |
| Kibana | 200m | 500m | 512Mi | 1Gi | - |
| Filebeat (por nodo) | 100m | 200m | 100Mi | 200Mi | - |

### Total para Cluster de 3 Nodos

- **CPU:** 1.2 cores (sin Filebeat) + 0.3 cores (Filebeat × 3 nodos) = **1.5 cores**
- **Memory:** ~3.6Gi (sin Filebeat) + 0.3Gi (Filebeat × 3 nodos) = **~4Gi**
- **Storage:** 5Gi PersistentVolume

### Cluster Actual (DigitalOcean)

```
Nodos: 3x s-4vcpu-8gb
  - CPU: 4 cores por nodo = 12 cores total
  - RAM: 8GB por nodo = 24GB total
```

**Conclusión:** ✅ **Tienes suficientes recursos** para desplegar ELK Stack

---

## 🧪 Verificación Post-Deployment

### 1. Verificar Pods

```bash
kubectl get pods -n logging

# Esperado:
NAME                             READY   STATUS    RESTARTS   AGE
elasticsearch-xxxxxxxxx-xxxxx    1/1     Running   0          5m
kibana-xxxxxxxxx-xxxxx           1/1     Running   0          3m
filebeat-xxxxx                   1/1     Running   0          1m
filebeat-xxxxx                   1/1     Running   0          1m
filebeat-xxxxx                   1/1     Running   0          1m
```

### 2. Verificar Servicios

```bash
kubectl get svc -n logging

# Esperado:
NAME                    TYPE        CLUSTER-IP       PORT(S)
elasticsearch           ClusterIP   10.245.x.x       9200/TCP
elasticsearch-external  NodePort    10.245.x.x       9200:30920/TCP
kibana                  ClusterIP   10.245.x.x       5601/TCP
kibana-external         NodePort    10.245.x.x       5601:30561/TCP
```

### 3. Verificar Salud de Elasticsearch

```bash
kubectl exec -n logging deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cluster/health | jq '.'

# Esperado:
{
  "cluster_name": "ecommerce-logs",
  "status": "green",
  "number_of_nodes": 1,
  "active_primary_shards": 1,
  "active_shards": 1
}
```

### 4. Verificar Índices Creados

```bash
kubectl exec -n logging deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cat/indices?v

# Esperado:
health status index                    uuid    docs.count
green  open   ecommerce-logs-2025.11.13 abc123  1234
```

### 5. Verificar Filebeat Recolectando Logs

```bash
kubectl logs -n logging daemonset/filebeat --tail=50

# Esperado: Ver líneas como:
# "Publish event"
# "Successfully connected to Elasticsearch"
```

---

## 🎯 Primeros Pasos en Kibana (Después de Desplegar)

### 1. Abrir Kibana UI

```
http://localhost:5601 (port-forward)
o
http://<NODE-IP>:30561 (NodePort)
o
http://137.184.240.48/kibana/ (si configuras Ingress)
```

### 2. Crear Index Pattern

1. Ir a: **☰ Menu** → **Management** → **Stack Management**
2. Click en **Index Patterns** (bajo Kibana)
3. Click **Create index pattern**
4. Ingresar pattern: `ecommerce-logs-*`
5. Click **Next step**
6. Seleccionar **@timestamp** como Time field
7. Click **Create index pattern**

### 3. Ver Logs en Discover

1. Ir a: **☰ Menu** → **Analytics** → **Discover**
2. Seleccionar index pattern: `ecommerce-logs-*`
3. Deberías ver logs de tus microservicios

### 4. Filtros Útiles

**Por servicio:**
```
kubernetes.labels.app: "order-service"
```

**Por namespace:**
```
kubernetes.namespace: "dev"
```

**Por nivel de log:**
```
level: "ERROR"
```

**Buscar texto:**
```
message: "Exception"
```

---

## 🚨 Troubleshooting

### Elasticsearch Pod en Pending

**Síntomas:**
```bash
kubectl get pods -n logging
# elasticsearch-xxx  0/1  Pending
```

**Causa:** PersistentVolume no disponible

**Solución:**
```bash
# Verificar PVC
kubectl get pvc -n logging

# Ver detalles
kubectl describe pvc elasticsearch-pvc -n logging

# Si no hay StorageClass, usar emptyDir (solo dev):
# Editar elasticsearch.yaml y cambiar PVC por emptyDir
```

### Elasticsearch Pod CrashLooping

**Síntomas:**
```bash
kubectl get pods -n logging
# elasticsearch-xxx  0/1  CrashLoopBackOff
```

**Verificar logs:**
```bash
kubectl logs -n logging deployment/elasticsearch

# Común: Error de memoria
```

**Solución:** Reducir memory limits en elasticsearch.yaml
```yaml
resources:
  limits:
    memory: "2Gi"  # Reducir de 4Gi
```

### Kibana Muestra "Kibana server is not ready yet"

**Causa:** Elasticsearch aún no está listo

**Solución:** Esperar 2-3 minutos, Kibana intentará reconectar

### No Aparecen Logs en Kibana

**Verificar Filebeat:**
```bash
# Ver si Filebeat está corriendo
kubectl get pods -n logging -l app=filebeat

# Ver logs de Filebeat
kubectl logs -n logging daemonset/filebeat --tail=100

# Debe mostrar: "Successfully connected to Elasticsearch"
```

**Verificar que hay índices:**
```bash
kubectl exec -n logging deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cat/indices?v
```

---

## 📈 Integración con Servicios E-Commerce

Una vez desplegado ELK Stack, Filebeat recolectará automáticamente logs de:

- ✅ api-gateway
- ✅ service-discovery
- ✅ user-service
- ✅ product-service
- ✅ order-service
- ✅ payment-service
- ✅ shipping-service
- ✅ favourite-service
- ✅ proxy-client

**No requiere cambios en los servicios** - Filebeat lee logs de `/var/log/containers/`

---

## 🔐 Consideraciones de Seguridad (Producción)

⚠️ **Configuración actual es para desarrollo** (sin autenticación)

Para producción, habilitar:
1. ✅ Elasticsearch security (X-Pack)
2. ✅ Kibana authentication
3. ✅ TLS/HTTPS
4. ✅ Network Policies
5. ✅ No exponer Elasticsearch públicamente

---

## 📝 Comparación Final: Monitoring vs Logging

| Aspecto | Monitoring (Grafana/Prometheus) | Logging (ELK Stack) |
|---------|--------------------------------|---------------------|
| **Estado** | 🟢 Desplegado y Activo | 🔴 Configurado pero NO Desplegado |
| **Acceso** | http://137.184.240.48/grafana/ | ❌ No accesible |
| **Pods** | 3/3 Running | 0 pods |
| **Propósito** | Métricas, dashboards, alertas | Logs centralizados, búsqueda |
| **Almacenamiento** | Time-series data | Full-text search |
| **Uso** | "¿Qué tan rápido/lento?" | "¿Qué pasó exactamente?" |

---

## ✅ Recomendación

**Para tener acceso similar a Grafana/Prometheus:**

1. Desplegar ELK Stack:
   ```bash
   cd infrastructure/kubernetes/logging
   ./deploy-elk.sh
   ```

2. Crear Ingress para Kibana:
   ```bash
   # Crear logging-ingress.yaml (ver ejemplo arriba)
   kubectl apply -f logging-ingress.yaml
   ```

3. Acceder igual que Grafana:
   ```
   http://137.184.240.48/kibana/
   ```

**Tiempo total:** ~10 minutos

---

**Documento generado:** 2025-11-13
**Estado verificado:** 2025-11-13
