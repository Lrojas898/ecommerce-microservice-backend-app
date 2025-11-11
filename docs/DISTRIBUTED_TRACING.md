# Distributed Tracing con Jaeger - Guía Completa

**Universidad ICESI - Ingeniería de Software V**
**Proyecto**: E-Commerce Microservices Backend

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Arquitectura](#2-arquitectura)
3. [Instalación y Configuración](#3-instalación-y-configuración)
4. [Uso de Jaeger UI](#4-uso-de-jaeger-ui)
5. [Casos de Uso](#5-casos-de-uso)
6. [Troubleshooting](#6-troubleshooting)
7. [Integración con Stack de Observabilidad](#7-integración-con-stack-de-observabilidad)

---

## 1. Introducción

### ¿Qué es Distributed Tracing?

El **Distributed Tracing** permite rastrear una solicitud a través de múltiples microservicios, ayudando a:
- Identificar cuellos de botella de rendimiento
- Detectar errores en la comunicación entre servicios
- Visualizar el flujo completo de una transacción
- Medir latencia entre servicios
- Debug de problemas en producción

### ¿Por qué Jaeger?

**Jaeger** es un sistema de tracing distribuido de código abierto desarrollado por Uber y ahora parte de CNCF (Cloud Native Computing Foundation).

**Ventajas**:
- ✓ Fácil integración con Spring Boot/Spring Cloud Sleuth
- ✓ Compatible con protocolo Zipkin
- ✓ UI intuitiva y completa
- ✓ Bajo overhead de rendimiento
- ✓ Soporte para OpenTelemetry
- ✓ Almacenamiento flexible (memoria, Elasticsearch, Cassandra)
- ✓ Muy buena documentación

### Conceptos Clave

**Trace**: Una transacción completa a través de múltiples servicios
```
Trace ID: 5c1a7b3f9d2e8a4c
│
├─ Span: API Gateway (200ms)
│  ├─ Span: User Service (50ms)
│  └─ Span: Order Service (150ms)
│     ├─ Span: Product Service (30ms)
│     └─ Span: Payment Service (120ms)
│        └─ Span: Shipping Service (80ms)
```

**Span**: Una operación individual dentro de un trace
- Tiene un ID único
- Contiene metadata (timestamps, tags, logs)
- Representa una unidad de trabajo

**Tags**: Metadata key-value sobre un span
- `http.method=GET`
- `http.status_code=200`
- `error=true`

**Logs**: Eventos timestamped dentro de un span
- Errores
- Mensajes de debug
- Eventos importantes

---

## 2. Arquitectura

### 2.1 Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                   E-Commerce Application                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   User   │  │ Product  │  │  Order   │  │ Payment  │   │
│  │ Service  │  │ Service  │  │ Service  │  │ Service  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│       └─────────────┴──────────────┴─────────────┘          │
│                         │                                    │
│                         ▼                                    │
│              Spring Cloud Sleuth                             │
│                   (Instrumentation)                          │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │      Jaeger (Tracing Backend)        │
        ├─────────────────────────────────────┤
        │                                      │
        │  ┌──────────┐  ┌──────────┐        │
        │  │Collector │  │  Query   │         │
        │  │ (Port    │  │   UI     │         │
        │  │  9411)   │  │(Port     │         │
        │  └────┬─────┘  │ 16686)   │         │
        │       │        └────┬─────┘         │
        │       ▼             │                │
        │  ┌──────────┐      │                │
        │  │ Storage  │◄─────┘                │
        │  │ (Memory) │                        │
        │  └──────────┘                        │
        └─────────────────────────────────────┘
                          │
                          ▼
                   ┌──────────────┐
                   │   Grafana    │
                   │ (Dashboard)  │
                   └──────────────┘
```

### 2.2 Componentes Desplegados

**Jaeger All-in-One**: Incluye todos los componentes en un solo pod

| Componente | Puerto | Descripción |
|------------|--------|-------------|
| **Collector (HTTP)** | 14268 | Recibe traces vía HTTP |
| **Collector (Zipkin)** | 9411 | Compatible con protocolo Zipkin |
| **Collector (gRPC)** | 14250 | Recibe traces vía gRPC |
| **Agent (UDP)** | 6831/6832 | Recibe traces vía UDP |
| **Query UI** | 16686 | Interfaz web para visualizar traces |
| **Health Check** | 14269 | Endpoint de salud |
| **Metrics** | 14271 | Métricas de Prometheus |

### 2.3 Flujo de Datos

```
1. Request llega al API Gateway
   ↓
2. Sleuth crea Trace ID y Span ID
   ↓
3. Request se propaga a User Service
   ↓
4. Sleuth crea nuevo Span (hijo del anterior)
   ↓
5. Request continúa a Order Service
   ↓
6. Sleuth crea otro Span
   ↓
7. Cada servicio envía su span a Jaeger Collector (puerto 9411)
   ↓
8. Jaeger almacena los spans
   ↓
9. Jaeger UI permite visualizar el trace completo
```

---

## 3. Instalación y Configuración

### 3.1 Desplegar Jaeger en Kubernetes

**Opción 1: Usando el script de deployment**

```bash
cd infrastructure/kubernetes/tracing
./deploy-jaeger.sh
```

**Opción 2: Manual**

```bash
# Crear namespace
kubectl apply -f infrastructure/kubernetes/tracing/namespace.yaml

# Desplegar Jaeger
kubectl apply -f infrastructure/kubernetes/tracing/jaeger-all-in-one.yaml

# Verificar deployment
kubectl get all -n tracing

# Esperar a que esté listo
kubectl wait --namespace=tracing \
  --for=condition=ready pod \
  --selector=app=jaeger \
  --timeout=300s
```

### 3.2 Verificar Instalación

```bash
# Ver pods
kubectl get pods -n tracing

# Output esperado:
# NAME                      READY   STATUS    RESTARTS   AGE
# jaeger-5f7c8d4b9c-xyz12   1/1     Running   0          2m

# Ver servicios
kubectl get svc -n tracing

# Output esperado:
# NAME               TYPE        CLUSTER-IP       PORT(S)
# jaeger-collector   ClusterIP   10.96.45.123     14268/TCP,9411/TCP...
# jaeger-query       NodePort    10.96.78.234     16686:30686/TCP
# jaeger-agent       ClusterIP   None             6831/UDP,6832/UDP

# Ver logs
kubectl logs -n tracing deployment/jaeger

# Verificar health
kubectl port-forward -n tracing svc/jaeger-query 14269:14269
curl http://localhost:14269/
```

### 3.3 Acceder a Jaeger UI

**Opción 1: Port-Forward (Recomendado para desarrollo)**

```bash
kubectl port-forward -n tracing svc/jaeger-query 16686:16686
```

Luego abre en tu navegador: `http://localhost:16686`

**Opción 2: NodePort (Minikube)**

```bash
# Obtener IP de Minikube
minikube ip

# Ejemplo output: 192.168.49.2
```

Abre en tu navegador: `http://192.168.49.2:30686`

**Opción 3: LoadBalancer (Cloud providers)**

```bash
# Cambiar tipo de servicio a LoadBalancer
kubectl patch svc jaeger-query -n tracing -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener IP externa
kubectl get svc jaeger-query -n tracing
```

### 3.4 Configuración de los Microservicios

Ya están configurados con las siguientes variables de ambiente:

```yaml
env:
  # Jaeger Distributed Tracing Configuration
  - name: SPRING_ZIPKIN_BASE_URL
    value: "http://jaeger-collector.tracing.svc.cluster.local:9411"
  - name: SPRING_SLEUTH_SAMPLER_PROBABILITY
    value: "1.0"  # 100% sampling (cambiar a 0.1 en producción)
  - name: SPRING_APPLICATION_NAME
    value: "user-service"  # Nombre del servicio
```

**Explicación de las variables**:

- `SPRING_ZIPKIN_BASE_URL`: URL del Jaeger Collector (compatible con Zipkin)
- `SPRING_SLEUTH_SAMPLER_PROBABILITY`: Porcentaje de traces a capturar
  - `1.0` = 100% (todas las requests)
  - `0.1` = 10% (1 de cada 10 requests)
  - Para producción: usar 0.1 o menos para reducir overhead
- `SPRING_APPLICATION_NAME`: Nombre que aparecerá en Jaeger UI

### 3.5 Sampling Strategy

El sampling está configurado vía ConfigMap:

```yaml
# Ver configuración
kubectl get configmap jaeger-sampling-config -n tracing -o yaml

# Estrategia actual: probabilistic con param 1.0 (100%)
```

**Modificar sampling para producción**:

```bash
# Editar ConfigMap
kubectl edit configmap jaeger-sampling-config -n tracing

# Cambiar "param": 1.0 a "param": 0.1 (10%)
# Guardar y reiniciar Jaeger
kubectl rollout restart deployment/jaeger -n tracing
```

---

## 4. Uso de Jaeger UI

### 4.1 Interfaz Principal

Al abrir Jaeger UI (`http://localhost:16686`), verás:

```
┌────────────────────────────────────────────────────────────┐
│  Jaeger UI                                          [Dark] │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Service: [user-service ▼]                                 │
│  Operation: [All ▼]                                        │
│  Tags:                                                     │
│  Lookback: [Last Hour ▼]                                   │
│  Min Duration:    Max Duration:                            │
│  Limit Results: [20 ▼]                                     │
│                                                            │
│  [Find Traces]                                             │
│                                                            │
├────────────────────────────────────────────────────────────┤
│  Results (23 traces)                                       │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ api-gateway: GET /api/products              250ms    │ │
│  │ [████████████░░░░] 8 spans                           │ │
│  └──────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ api-gateway: POST /api/orders               450ms    │ │
│  │ [████████████████████░░] 12 spans                    │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

### 4.2 Buscar Traces

**Por Servicio**:
1. Selecciona servicio en dropdown (ej: `user-service`)
2. Click en "Find Traces"
3. Verás todos los traces de ese servicio

**Por Operación**:
1. Selecciona servicio
2. Selecciona operación (ej: `GET /api/users/{id}`)
3. Click en "Find Traces"

**Por Tags**:
```
http.status_code=500        # Todos los errores 500
error=true                   # Todos los traces con errores
http.method=POST             # Solo requests POST
```

**Por Duración**:
```
Min Duration: 1s             # Traces más lentos que 1 segundo
Max Duration: 5s             # Traces más rápidos que 5 segundos
```

**Por Trace ID**:
```
Copiar Trace ID del log y pegarlo en la búsqueda
```

### 4.3 Vista de Trace Detallado

Al hacer click en un trace, verás:

```
┌────────────────────────────────────────────────────────────┐
│  Trace: 5c1a7b3f9d2e8a4c                                   │
│  Duration: 450ms   Spans: 12   Services: 5                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  api-gateway                [████████████████████] 450ms   │
│    user-service             [████░░] 50ms                  │
│      Database Query         [██░] 20ms                     │
│    order-service            [████████████] 350ms           │
│      product-service        [██░] 30ms                     │
│      payment-service        [████████] 280ms               │
│        Database Query       [███] 80ms                     │
│        External API         [█████] 200ms                  │
│        shipping-service     [██░] 100ms                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Información de cada Span**:
- Servicio que lo generó
- Duración
- Tags (metadata)
- Logs (eventos)
- Referencias (parent/child)

### 4.4 Analizar Performance

**Identificar Cuellos de Botella**:
1. Ver qué span toma más tiempo (barra más larga)
2. Hacer click en el span
3. Ver detalles (tags, logs)
4. Identificar causa (query lenta, API externa, etc.)

**Ejemplo**:
```
payment-service: 280ms
  ├─ Database Query: 80ms (OK)
  ├─ External Payment API: 200ms ← CUELLO DE BOTELLA
  └─ Update Order: 10ms (OK)
```

**Acción**: Optimizar llamada a External Payment API (cache, timeout, async)

---

## 5. Casos de Uso

### 5.1 Caso 1: Rastrear Flujo de Creación de Orden

**Escenario**: Un usuario crea una orden pero falla. Queremos ver qué pasó.

**Pasos**:
1. Abrir Jaeger UI
2. Seleccionar servicio: `order-service`
3. Seleccionar operación: `POST /api/orders`
4. Agregar tag: `error=true`
5. Click "Find Traces"
6. Seleccionar el trace fallido
7. Ver el span que tiene error
8. Ver logs del span para entender el error

**Trace Ejemplo**:
```
api-gateway: POST /api/orders [ERROR] 500ms
  ├─ user-service: GET /api/users/123 [OK] 50ms
  ├─ order-service: CREATE order [ERROR] 300ms
  │   ├─ product-service: GET /api/products/456 [OK] 30ms
  │   └─ payment-service: PROCESS payment [ERROR] 250ms
  │       └─ Log: "Payment gateway timeout after 5s"
```

**Conclusión**: El payment service falló por timeout del gateway externo.

### 5.2 Caso 2: Optimizar Performance de Búsqueda de Productos

**Escenario**: La búsqueda de productos es lenta (>1s).

**Pasos**:
1. Seleccionar servicio: `product-service`
2. Operación: `GET /api/products`
3. Min Duration: `1s`
4. Analizar traces lentos
5. Identificar operación lenta

**Trace Ejemplo**:
```
api-gateway: GET /api/products 1.5s
  └─ product-service: GET /api/products 1.4s
      └─ Database Query: SELECT * FROM products 1.3s
          └─ Log: "Full table scan on 100k records"
```

**Conclusión**: Falta índice en la base de datos.

**Acción**: Crear índice en columna `category_id`.

### 5.3 Caso 3: Debug de Comunicación Entre Servicios

**Escenario**: El order-service no puede comunicarse con payment-service.

**Pasos**:
1. Buscar traces con `http.status_code=503`
2. Ver el trace
3. Identificar en qué span falla la comunicación

**Trace Ejemplo**:
```
order-service: POST /api/orders [ERROR] 100ms
  └─ payment-service: POST /api/payments [ERROR] 50ms
      └─ Log: "Connection refused: payment-service:8084"
```

**Conclusión**: Payment service está caído o puerto incorrecto.

**Acción**: Verificar deployment de payment-service.

### 5.4 Caso 4: Analizar Transacción Completa E2E

**Escenario**: Queremos ver el flujo completo desde que un usuario se registra hasta que completa una compra.

**Pasos**:
1. Ejecutar prueba E2E
2. Copiar Trace ID del log
3. Buscar en Jaeger por Trace ID
4. Ver flujo completo

**Trace Completo**:
```
api-gateway: POST /api/users 2.5s
  ├─ user-service: CREATE user 500ms
  │   └─ Database: INSERT user 100ms
  └─ order-service: CREATE order 1.8s
      ├─ product-service: GET product 200ms
      ├─ payment-service: PROCESS payment 1.2s
      │   └─ External API: Stripe 1.0s
      └─ shipping-service: CREATE shipment 400ms
          └─ Database: INSERT shipment 100ms
```

**Insights**:
- Total: 2.5s
- Parte más lenta: Stripe API (1.0s) - 40% del tiempo total
- Oportunidad: Cache de validación de tarjetas
- Todos los servicios responden correctamente

---

## 6. Troubleshooting

### 6.1 No Aparecen Traces en Jaeger

**Problema**: Jaeger UI no muestra traces.

**Verificaciones**:

1. **Verificar que Jaeger está corriendo**:
```bash
kubectl get pods -n tracing
# Debe mostrar: jaeger-xxx   1/1     Running
```

2. **Verificar conectividad desde un pod**:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://jaeger-collector.tracing.svc.cluster.local:9411/api/v2/spans

# Debe responder con HTTP 202
```

3. **Verificar variables de ambiente en pods**:
```bash
kubectl get pod <pod-name> -o yaml | grep -A 3 ZIPKIN

# Debe mostrar:
# - name: SPRING_ZIPKIN_BASE_URL
#   value: http://jaeger-collector.tracing.svc.cluster.local:9411
```

4. **Verificar logs del microservicio**:
```bash
kubectl logs <pod-name> | grep -i sleuth

# Debe mostrar:
# INFO [user-service,5c1a7b3f9d2e8a4c,f8b2c9d1e3a5b6c7] ...
#                     ^Trace ID        ^Span ID
```

5. **Verificar sampling**:
```bash
kubectl logs <pod-name> | grep -i sampler

# Debe mostrar: sampler.probability=1.0
```

### 6.2 Traces Incompletos

**Problema**: Los traces aparecen pero faltan spans.

**Causas y Soluciones**:

1. **Servicio no tiene Sleuth configurado**:
```bash
# Verificar que todas las imágenes son recientes
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}'

# Rebuilds si es necesario
```

2. **Timeout en recolección**:
```bash
# Aumentar timeout en Jaeger
kubectl edit deployment jaeger -n tracing
# Agregar env:
#   - name: COLLECTOR_ZIPKIN_HTTP_SERVER_TIMEOUT
#     value: "30s"
```

3. **Problemas de red**:
```bash
# Test de conectividad entre namespaces
kubectl run -it --rm debug --image=nicolaka/netshoot -- \
  nc -zv jaeger-collector.tracing.svc.cluster.local 9411
```

### 6.3 Alta Latencia en Producción

**Problema**: Los servicios son lentos en producción.

**Solución**: Reducir sampling

```bash
# Cambiar de 1.0 (100%) a 0.1 (10%)
kubectl set env deployment/user-service \
  SPRING_SLEUTH_SAMPLER_PROBABILITY=0.1

# O editar ConfigMap para aplicar a todos
kubectl edit configmap jaeger-sampling-config -n tracing
```

### 6.4 Jaeger Out of Memory

**Problema**: Jaeger pod se reinicia por OOM.

**Soluciones**:

1. **Aumentar memoria**:
```bash
kubectl edit deployment jaeger -n tracing
# Cambiar:
#   resources:
#     limits:
#       memory: "1Gi"  # Era 512Mi
```

2. **Reducir retención**:
```bash
kubectl set env deployment/jaeger -n tracing \
  MEMORY_MAX_TRACES=5000  # Era 10000
```

3. **Migrar a almacenamiento persistente**:
```bash
# Cambiar de memory a Elasticsearch (fuera del scope de esta guía)
```

### 6.5 Logs de Debug

```bash
# Ver logs de Jaeger
kubectl logs -n tracing deployment/jaeger -f

# Ver eventos
kubectl get events -n tracing --sort-by='.lastTimestamp'

# Describir pod
kubectl describe pod -n tracing <jaeger-pod-name>

# Ejecutar shell en pod de Jaeger
kubectl exec -it -n tracing <jaeger-pod-name> -- sh
```

---

## 7. Integración con Stack de Observabilidad

### 7.1 Stack Completo

Tu proyecto ahora tiene un stack completo de observabilidad:

```
┌─────────────────────────────────────────────────────────┐
│              OBSERVABILITY STACK                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐ │
│  │   METRICS     │  │    LOGS       │  │   TRACES    │ │
│  │               │  │               │  │             │ │
│  │  Prometheus   │  │  ELK Stack    │  │   Jaeger    │ │
│  │  + Grafana    │  │  + Filebeat   │  │             │ │
│  │               │  │               │  │             │ │
│  └───────┬───────┘  └───────┬───────┘  └──────┬──────┘ │
│          │                  │                  │         │
│          └──────────────────┴──────────────────┘         │
│                             │                            │
│                             ▼                            │
│                  E-Commerce Microservices                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 7.2 Acceso a Herramientas

| Herramienta | Puerto | URL (Port-Forward) | URL (Minikube) |
|-------------|--------|-------------------|----------------|
| **Jaeger UI** | 16686 | http://localhost:16686 | http://MINIKUBE_IP:30686 |
| **Prometheus** | 9090 | http://localhost:9090 | http://MINIKUBE_IP:30090 |
| **Grafana** | 3000 | http://localhost:3000 | http://MINIKUBE_IP:30300 |
| **Kibana** | 5601 | http://localhost:5601 | http://MINIKUBE_IP:30561 |
| **Eureka** | 8761 | http://localhost:8761 | http://MINIKUBE_IP:32761 |

### 7.3 Correlación de Datos

**Trace ID en Logs**:

Los logs ahora incluyen Trace ID y Span ID gracias a Sleuth:

```
2025-11-11 12:34:56 INFO [user-service,5c1a7b3f9d2e8a4c,f8b2c9d1e3a5b6c7] UserController: Creating user
                                      ^Trace ID        ^Span ID
```

**Workflow de Debug**:
1. Ver alerta en Grafana (métrica alta)
2. Buscar logs en Kibana para ese periodo
3. Copiar Trace ID del log
4. Buscar en Jaeger por ese Trace ID
5. Ver flujo completo de la transacción

**Ejemplo**:
```
Grafana Alert → HTTP 500 errors spike at 12:35
  ↓
Kibana → Search: timestamp:[12:35 TO 12:36] AND level:ERROR
  ↓
Log: "ERROR [order-service,5c1a7b3f9d2e8a4c,...] PaymentException"
  ↓
Jaeger → Search Trace ID: 5c1a7b3f9d2e8a4c
  ↓
Ver span de payment-service con error detallado
```

### 7.4 Dashboard de Grafana para Jaeger

Puedes agregar métricas de Jaeger a Grafana:

```bash
# Jaeger expone métricas en puerto 14271
# Agregar a prometheus.yml:

scrape_configs:
  - job_name: 'jaeger'
    static_configs:
      - targets: ['jaeger.tracing.svc.cluster.local:14271']
```

**Métricas útiles**:
- `jaeger_collector_traces_received_total`: Traces recibidos
- `jaeger_collector_spans_received_total`: Spans recibidos
- `jaeger_collector_batch_size`: Tamaño de batches
- `jaeger_query_requests_total`: Queries a Jaeger UI

### 7.5 Integración con Alertas

Crear alertas basadas en traces:

**Ejemplo en AlertManager**:
```yaml
groups:
  - name: jaeger_alerts
    rules:
      - alert: HighTraceErrorRate
        expr: |
          rate(jaeger_collector_spans_received_total{
            sampler_type="error"
          }[5m]) > 10
        annotations:
          summary: "High error rate in traces"
          description: "More than 10 error spans per second"
```

---

## 8. Mejores Prácticas

### 8.1 Sampling

- **Desarrollo**: 100% (`probability=1.0`)
- **Staging**: 50% (`probability=0.5`)
- **Producción**: 1-10% (`probability=0.01-0.1`)

### 8.2 Tags Personalizados

Agregar tags custom en tu código:

```java
import brave.Span;
import brave.Tracer;

@Service
public class OrderService {
    @Autowired
    private Tracer tracer;

    public Order createOrder(Order order) {
        Span span = tracer.currentSpan();
        if (span != null) {
            span.tag("order.id", order.getId());
            span.tag("order.total", String.valueOf(order.getTotal()));
            span.tag("user.id", order.getUserId());
        }
        // ... lógica de negocio
    }
}
```

### 8.3 Logs en Spans

```java
span.annotate("Validating payment");
// ... validación
span.annotate("Payment validated successfully");
```

### 8.4 Propagación de Context

Sleuth automáticamente propaga el trace context en:
- RestTemplate
- WebClient
- Feign clients
- Kafka messages
- AMQP messages

### 8.5 Performance

- No crear spans manualmente a menos que sea necesario
- Usar sampling adecuado en producción
- Configurar timeouts apropiados
- Monitorear overhead de Sleuth (normalmente <1%)

---

## 9. Referencias

### Documentación Oficial

- **Jaeger**: https://www.jaegertracing.io/docs/
- **Spring Cloud Sleuth**: https://spring.io/projects/spring-cloud-sleuth
- **OpenTelemetry**: https://opentelemetry.io/docs/

### Tutoriales

- **Jaeger Quickstart**: https://www.jaegertracing.io/docs/getting-started/
- **Spring Boot + Jaeger**: https://www.baeldung.com/spring-boot-jaeger

### Troubleshooting

- **Jaeger FAQ**: https://www.jaegertracing.io/docs/faq/
- **Sleuth Issues**: https://github.com/spring-cloud/spring-cloud-sleuth/issues

---

## 10. Anexos

### A. Scripts Útiles

**Port-forward all services**:
```bash
#!/bin/bash
kubectl port-forward -n tracing svc/jaeger-query 16686:16686 &
kubectl port-forward -n monitoring svc/grafana 3000:3000 &
kubectl port-forward -n logging svc/kibana 5601:5601 &
kubectl port-forward -n dev svc/api-gateway 8080:80 &
echo "All services exposed on localhost"
```

**Clean old traces** (only for memory storage):
```bash
kubectl rollout restart deployment/jaeger -n tracing
```

### B. Configuración Avanzada

**Custom Sampling por Endpoint**:
```yaml
spring:
  sleuth:
    sampler:
      probability: 0.1  # Default 10%
    web:
      client:
        # Samplear 100% para endpoints críticos
        skipPattern: ^(/actuator/health|/actuator/metrics)
```

**Baggage Propagation** (pasar datos custom entre servicios):
```yaml
spring:
  sleuth:
    baggage:
      remote-fields:
        - user-id
        - correlation-id
      local-fields:
        - request-id
```

### C. Ejemplos de Queries

**Top 10 servicios más lentos**:
```
En Jaeger UI: Buscar "All Services", ordenar por Duration (desc)
```

**Traces con errores en las últimas 24h**:
```
Service: All
Tags: error=true
Lookback: Last 24 hours
```

**Operaciones que llaman a base de datos**:
```
Tags: span.kind=client AND db.type=sql
```

---

## Conclusión

Con Jaeger implementado, ahora tienes:
- ✓ Visibilidad completa de transacciones distribuidas
- ✓ Identificación rápida de cuellos de botella
- ✓ Debug fácil de errores en producción
- ✓ Métricas de latencia por servicio
- ✓ Stack completo de observabilidad (Metrics + Logs + Traces)

**Next Steps**:
1. Desplegar Jaeger: `./infrastructure/kubernetes/tracing/deploy-jaeger.sh`
2. Redesplegar microservicios para aplicar cambios
3. Generar tráfico (ejecutar pruebas E2E)
4. Explorar Jaeger UI
5. Crear dashboards en Grafana
6. Configurar alertas basadas en traces

**Contacto**: Para preguntas o issues, revisar logs de Jaeger y documentación oficial.

---

**Universidad ICESI - Ingeniería de Software V**
