# Monitoreo con Prometheus y Grafana

**Universidad ICESI - Ingeniería de Software V**
**Proyecto**: E-Commerce Microservices Backend

---

## Tabla de Contenidos

1. [Arquitectura de Monitoreo](#1-arquitectura-de-monitoreo)
2. [Componentes](#2-componentes)
3. [Instalación y Configuración](#3-instalación-y-configuración)
4. [Verificación](#4-verificación)
5. [Dashboards de Grafana](#5-dashboards-de-grafana)
6. [Métricas Disponibles](#6-métricas-disponibles)
7. [Troubleshooting](#7-troubleshooting)
8. [Referencias](#8-referencias)

---

## 1. Arquitectura de Monitoreo

### 1.1 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │         Namespace: monitoring                          │     │
│  │                                                         │     │
│  │  ┌──────────────┐         ┌──────────────┐            │     │
│  │  │  Prometheus  │────────▶│   Grafana    │            │     │
│  │  │   (Scraper)  │         │ (Dashboards) │            │     │
│  │  └──────┬───────┘         └──────────────┘            │     │
│  │         │                                              │     │
│  └─────────┼──────────────────────────────────────────────┘     │
│            │ (scrapes metrics every 15s)                        │
│            │                                                     │
│  ┌─────────▼─────────────────────────────────────────────┐     │
│  │         Namespace: dev / prod                         │     │
│  │                                                        │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │     │
│  │  │ user-service │  │product-service│ │order-service│ │     │
│  │  │              │  │              │  │            │  │     │
│  │  │/actuator/    │  │/actuator/    │  │/actuator/  │  │     │
│  │  │prometheus    │  │prometheus    │  │prometheus  │  │     │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │     │
│  │                                                        │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │     │
│  │  │payment-service│ │shipping-service│ │favourite-  │  │     │
│  │  │              │  │              │  │service     │  │     │
│  │  │/actuator/    │  │/actuator/    │  │/actuator/  │  │     │
│  │  │prometheus    │  │prometheus    │  │prometheus  │  │     │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │     │
│  │                                                        │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │     │
│  │  │ api-gateway  │  │service-      │  │proxy-client│  │     │
│  │  │              │  │discovery     │  │            │  │     │
│  │  │/actuator/    │  │/actuator/    │  │/actuator/  │  │     │
│  │  │prometheus    │  │prometheus    │  │prometheus  │  │     │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Flujo de Datos

1. **Generación de Métricas**: Cada microservicio expone métricas en formato Prometheus en `/actuator/prometheus`
2. **Scraping**: Prometheus scrapes (consulta) estas métricas cada 15 segundos
3. **Almacenamiento**: Prometheus almacena las métricas en su base de datos Time Series (TSDB)
4. **Visualización**: Grafana consulta Prometheus y muestra dashboards interactivos
5. **Alertas** (opcional): Prometheus puede enviar alertas basadas en reglas definidas

---

## 2. Componentes

### 2.1 Prometheus

**Versión**: v2.48.0

**Descripción**: Sistema de monitoreo y base de datos de series temporales (TSDB).

**Características**:
- ✅ Service Discovery automático de pods en Kubernetes
- ✅ Scraping de métricas cada 15 segundos
- ✅ Retención de datos por 30 días
- ✅ Almacenamiento persistente (10Gi PVC)
- ✅ API HTTP para consultas (PromQL)

**Recursos Kubernetes**:
- **ConfigMap**: `prometheus-config` (configuración de scraping)
- **Deployment**: `prometheus` (1 replica)
- **Service**: `prometheus` (ClusterIP, puerto 9090)
- **Service**: `prometheus-external` (NodePort 30090)
- **PVC**: `prometheus-pvc` (10Gi)
- **ServiceAccount**: `prometheus` (permisos para Kubernetes API)

**Endpoints**:
- UI: `http://<minikube-ip>:30090` o `kubectl port-forward -n monitoring svc/prometheus 9090:9090`
- Targets: `http://localhost:9090/targets`
- Graph: `http://localhost:9090/graph`

### 2.2 Grafana

**Versión**: v10.2.2

**Descripción**: Plataforma de visualización y análisis de métricas.

**Características**:
- ✅ Datasource de Prometheus preconfigurado
- ✅ Dashboard de Spring Boot preinstalado
- ✅ Almacenamiento persistente (5Gi PVC)
- ✅ Autenticación básica (admin/admin123)
- ✅ Provisioning automático de datasources y dashboards

**Recursos Kubernetes**:
- **ConfigMap**: `grafana-datasources` (configuración de datasource)
- **ConfigMap**: `grafana-dashboards-config` (provisioning de dashboards)
- **ConfigMap**: `grafana-dashboard-spring-boot` (dashboard predefinido)
- **Deployment**: `grafana` (1 replica)
- **Service**: `grafana` (ClusterIP, puerto 3000)
- **Service**: `grafana-external` (NodePort 30030)
- **PVC**: `grafana-pvc` (5Gi)

**Credenciales por defecto**:
- **Usuario**: `admin`
- **Contraseña**: `admin123` ⚠️ **CAMBIAR EN PRODUCCIÓN**

**Endpoints**:
- UI: `http://<minikube-ip>:30030` o `kubectl port-forward -n monitoring svc/grafana 3000:3000`

### 2.3 Microservicios

**Dependencias**:
- `spring-boot-starter-actuator` (ya incluida)
- `micrometer-registry-prometheus` (ya incluida en parent pom.xml)

**Configuración** (application.yml):
```yaml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info,metrics
      base-path: /actuator
  endpoint:
    prometheus:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true
    tags:
      application: ${spring.application.name}
```

**Endpoint de métricas**:
- `http://<service>:<port>/<context-path>/actuator/prometheus`
- Ejemplo: `http://user-service:8081/user-service/actuator/prometheus`

---

## 3. Instalación y Configuración

### 3.1 Prerrequisitos

✅ Kubernetes cluster en ejecución (Minikube, Docker Desktop, etc.)
✅ `kubectl` instalado y configurado
✅ Microservicios desplegados en namespaces `dev` o `prod`
✅ Microservicios actualizados con configuración de actuator (ya hecho)

### 3.2 Deployment Automático (Recomendado)

Usa el script de deployment automatizado:

```bash
# Navegar al directorio de monitoring
cd infrastructure/kubernetes/monitoring

# Dar permisos de ejecución al script
chmod +x deploy-monitoring.sh

# Ejecutar el script
./deploy-monitoring.sh
```

El script hará:
1. ✅ Crear namespace `monitoring`
2. ✅ Desplegar Prometheus
3. ✅ Desplegar Grafana
4. ✅ Esperar a que estén ready
5. ✅ Mostrar información de acceso

### 3.3 Deployment Manual

Si prefieres hacerlo manualmente:

```bash
# 1. Crear namespace
kubectl apply -f infrastructure/kubernetes/monitoring/namespace.yaml

# 2. Desplegar Prometheus
kubectl apply -f infrastructure/kubernetes/monitoring/prometheus-config.yaml
kubectl apply -f infrastructure/kubernetes/monitoring/prometheus.yaml

# 3. Desplegar Grafana
kubectl apply -f infrastructure/kubernetes/monitoring/grafana-config.yaml
kubectl apply -f infrastructure/kubernetes/monitoring/grafana.yaml

# 4. Verificar deployment
kubectl get all -n monitoring

# 5. Esperar a que estén ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
```

### 3.4 Acceso a las UIs

#### Opción 1: NodePort (Minikube)

```bash
# Obtener IP de Minikube
minikube ip

# Prometheus: http://<minikube-ip>:30090
# Grafana: http://<minikube-ip>:30030
```

#### Opción 2: Port-Forward (Cualquier Kubernetes)

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir: http://localhost:9090

# Grafana (en otra terminal)
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Abrir: http://localhost:3000
# Login: admin / admin123
```

---

## 4. Verificación

### 4.1 Verificar Pods en Ejecución

```bash
kubectl get pods -n monitoring

# Salida esperada:
# NAME                          READY   STATUS    RESTARTS   AGE
# grafana-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
# prometheus-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### 4.2 Verificar Servicios

```bash
kubectl get svc -n monitoring

# Salida esperada:
# NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
# grafana               ClusterIP   10.96.xxx.xxx    <none>        3000/TCP         2m
# grafana-external      NodePort    10.96.xxx.xxx    <none>        3000:30030/TCP   2m
# prometheus            ClusterIP   10.96.xxx.xxx    <none>        9090/TCP         2m
# prometheus-external   NodePort    10.96.xxx.xxx    <none>        9090:30090/TCP   2m
```

### 4.3 Verificar Targets en Prometheus

1. Acceder a Prometheus UI
2. Ir a: **Status** → **Targets**
3. Verificar que los servicios aparezcan y estén en estado **UP**

Deberías ver targets como:
- `ecommerce-microservices/user-service.dev`
- `ecommerce-microservices/product-service.dev`
- `ecommerce-microservices/order-service.dev`
- etc.

### 4.4 Verificar Endpoint de Métricas de un Microservicio

```bash
# Port-forward a un servicio
kubectl port-forward -n dev svc/user-service 8081:8081

# Consultar endpoint de métricas
curl http://localhost:8081/user-service/actuator/prometheus

# Deberías ver métricas en formato Prometheus:
# # HELP jvm_memory_used_bytes The amount of used memory
# # TYPE jvm_memory_used_bytes gauge
# jvm_memory_used_bytes{application="USER-SERVICE",area="heap",id="PS Eden Space",} 1.234567E7
# ...
```

### 4.5 Verificar Datasource en Grafana

1. Acceder a Grafana UI
2. Ir a: **Configuration** (⚙️) → **Data Sources**
3. Verificar que **Prometheus** aparezca como datasource
4. Click en **Prometheus** → **Test** → Debe mostrar "Data source is working"

---

## 5. Dashboards de Grafana

### 5.1 Dashboard Preinstalado: Spring Boot Microservices Overview

Este dashboard viene preconfigurado y muestra:

**Paneles incluidos**:
1. **HTTP Request Rate**: Tasa de requests por segundo por servicio
2. **Average Response Time**: Tiempo promedio de respuesta
3. **JVM Memory Usage**: Uso de memoria heap
4. **CPU Usage**: Uso de CPU por servicio

**Variables**:
- `$application`: Selector de microservicio (permite filtrar por servicio específico o ver todos)

**Acceso**:
1. Login a Grafana
2. Ir a **Dashboards** → **Browse**
3. Seleccionar: **Spring Boot Microservices Overview**

### 5.2 Importar Dashboards Adicionales

Grafana tiene dashboards públicos que puedes importar:

**Dashboard recomendado**: JVM (Micrometer)
- **ID**: 4701
- **URL**: https://grafana.com/grafana/dashboards/4701

**Pasos para importar**:
1. En Grafana, ir a **Dashboards** → **Import**
2. Ingresar ID: `4701`
3. Click **Load**
4. Seleccionar Datasource: **Prometheus**
5. Click **Import**

**Otros dashboards útiles**:
- **Spring Boot 2.1 Statistics**: ID `10280`
- **Spring Boot Observability**: ID `17175`
- **Kubernetes Cluster Monitoring**: ID `7249`

### 5.3 Crear Dashboard Personalizado

**Ejemplo: Panel de órdenes por minuto**

1. En Grafana, crear nuevo Dashboard
2. Agregar panel
3. En **Query**, usar PromQL:
   ```promql
   rate(http_server_requests_seconds_count{
     application="ORDER-SERVICE",
     uri="/order-service/api/orders",
     method="POST"
   }[1m]) * 60
   ```
4. Configurar visualización (Graph, Stat, Gauge, etc.)
5. Guardar dashboard

---

## 6. Métricas Disponibles

### 6.1 Métricas de JVM

| Métrica | Descripción | Ejemplo de Query |
|---------|-------------|------------------|
| `jvm_memory_used_bytes` | Memoria usada (heap/non-heap) | `jvm_memory_used_bytes{area="heap"}` |
| `jvm_memory_max_bytes` | Memoria máxima disponible | `jvm_memory_max_bytes{area="heap"}` |
| `jvm_gc_pause_seconds_count` | Cantidad de pausas de GC | `rate(jvm_gc_pause_seconds_count[1m])` |
| `jvm_threads_live_threads` | Threads activos | `jvm_threads_live_threads` |
| `process_cpu_usage` | Uso de CPU del proceso | `process_cpu_usage * 100` |

### 6.2 Métricas HTTP

| Métrica | Descripción | Ejemplo de Query |
|---------|-------------|------------------|
| `http_server_requests_seconds_count` | Total de requests | `rate(http_server_requests_seconds_count[1m])` |
| `http_server_requests_seconds_sum` | Tiempo total de requests | `http_server_requests_seconds_sum` |
| `http_server_requests_seconds_max` | Tiempo máximo de request | `http_server_requests_seconds_max` |

**Calcular tiempo promedio de respuesta**:
```promql
http_server_requests_seconds_sum / http_server_requests_seconds_count
```

**Requests por segundo**:
```promql
rate(http_server_requests_seconds_count[1m])
```

**Requests por status code**:
```promql
rate(http_server_requests_seconds_count{status="200"}[1m])
rate(http_server_requests_seconds_count{status="500"}[1m])
```

### 6.3 Métricas de Circuit Breaker (Resilience4j)

| Métrica | Descripción | Ejemplo de Query |
|---------|-------------|------------------|
| `resilience4j_circuitbreaker_state` | Estado del circuit breaker | `resilience4j_circuitbreaker_state` |
| `resilience4j_circuitbreaker_calls_seconds_count` | Total de llamadas | `resilience4j_circuitbreaker_calls_seconds_count` |
| `resilience4j_circuitbreaker_failure_rate` | Tasa de fallos | `resilience4j_circuitbreaker_failure_rate` |

### 6.4 Métricas de Base de Datos (HikariCP)

| Métrica | Descripción | Ejemplo de Query |
|---------|-------------|------------------|
| `hikaricp_connections_active` | Conexiones activas | `hikaricp_connections_active` |
| `hikaricp_connections_idle` | Conexiones idle | `hikaricp_connections_idle` |
| `hikaricp_connections_pending` | Conexiones pendientes | `hikaricp_connections_pending` |

---

## 7. Troubleshooting

### 7.1 Prometheus no puede scrapear servicios

**Síntoma**: Targets en estado `DOWN` en Prometheus

**Soluciones**:

1. **Verificar que el endpoint existe**:
   ```bash
   kubectl port-forward -n dev svc/user-service 8081:8081
   curl http://localhost:8081/user-service/actuator/prometheus
   ```

2. **Verificar configuración de actuator** en `application.yml`:
   ```yaml
   management:
     endpoints:
       web:
         exposure:
           include: prometheus,health,info,metrics
   ```

3. **Verificar networking**:
   ```bash
   # Desde pod de Prometheus, intentar curl al servicio
   kubectl exec -it -n monitoring deployment/prometheus -- sh
   wget -O- http://user-service.dev:8081/user-service/actuator/prometheus
   ```

4. **Verificar logs de Prometheus**:
   ```bash
   kubectl logs -f deployment/prometheus -n monitoring
   ```

### 7.2 Grafana no muestra datos

**Síntoma**: Panels vacíos en Grafana

**Soluciones**:

1. **Verificar datasource**:
   - Ir a Configuration → Data Sources → Prometheus
   - Click en **Test** → Debe decir "Data source is working"

2. **Verificar query en Prometheus primero**:
   - Ir a Prometheus UI: http://localhost:9090
   - Ejecutar query manualmente: `up`
   - Si funciona ahí, el problema está en Grafana

3. **Verificar time range**:
   - En el panel de Grafana, revisar el selector de tiempo (arriba a la derecha)
   - Cambiar a "Last 5 minutes" para ver datos recientes

4. **Verificar logs de Grafana**:
   ```bash
   kubectl logs -f deployment/grafana -n monitoring
   ```

### 7.3 Pods de monitoring en estado CrashLoopBackOff

**Soluciones**:

1. **Verificar logs**:
   ```bash
   kubectl logs deployment/prometheus -n monitoring
   kubectl logs deployment/grafana -n monitoring
   ```

2. **Verificar storage**:
   ```bash
   kubectl get pvc -n monitoring
   # PVCs deben estar en estado Bound
   ```

3. **Verificar recursos**:
   ```bash
   kubectl describe pod <pod-name> -n monitoring
   # Revisar sección Events
   ```

### 7.4 Métricas no aparecen después de redespliegue

**Solución**:

Después de redesplegar servicios, esperar ~30 segundos para que Prometheus los redescubra:

```bash
# Forzar reload de configuración de Prometheus
kubectl rollout restart deployment/prometheus -n monitoring
```

---

## 8. Referencias

### 8.1 Documentación Oficial

- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **Micrometer**: https://micrometer.io/docs
- **Spring Boot Actuator**: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html

### 8.2 Queries PromQL Útiles

**Top 5 endpoints más lentos**:
```promql
topk(5,
  http_server_requests_seconds_sum / http_server_requests_seconds_count
)
```

**Tasa de errores 5xx**:
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[1m]))
/
sum(rate(http_server_requests_seconds_count[1m]))
```

**Uso de memoria por servicio**:
```promql
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100
```

**CPU usage por servicio**:
```promql
process_cpu_usage{application=~".*"} * 100
```

### 8.3 Dashboards Públicos Recomendados

| Dashboard | ID | Descripción |
|-----------|-----|-------------|
| JVM (Micrometer) | 4701 | Métricas detalladas de JVM |
| Spring Boot 2.1 Statistics | 10280 | Métricas de Spring Boot |
| Spring Boot Observability | 17175 | Observabilidad completa |
| Kubernetes Cluster Monitoring | 7249 | Métricas del cluster K8s |

---

## Comandos Rápidos

```bash
# Desplegar monitoring stack
cd infrastructure/kubernetes/monitoring && ./deploy-monitoring.sh

# Ver recursos de monitoring
kubectl get all -n monitoring

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Ver logs de Prometheus
kubectl logs -f deployment/prometheus -n monitoring

# Ver logs de Grafana
kubectl logs -f deployment/grafana -n monitoring

# Eliminar monitoring stack
kubectl delete namespace monitoring

# Verificar métricas de un servicio
kubectl port-forward -n dev svc/user-service 8081:8081
curl http://localhost:8081/user-service/actuator/prometheus
```

---

**Notas Importantes**:
- ⚠️ Cambiar la contraseña de Grafana en producción
- ⚠️ Configurar retention policy de Prometheus según necesidades
- ⚠️ Configurar alertas para producción
- ⚠️ Considerar usar Persistent Volumes adecuados en producción

---

**Última actualización**: Noviembre 2025
