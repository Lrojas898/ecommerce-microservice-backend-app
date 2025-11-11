# Jaeger Distributed Tracing

Sistema de tracing distribuido para monitorear y debuggear transacciones a través de múltiples microservicios.

## Quick Start

### 1. Desplegar Jaeger

```bash
./deploy-jaeger.sh
```

### 2. Verificar Deployment

```bash
kubectl get all -n tracing
```

### 3. Acceder a Jaeger UI

**Port-Forward**:
```bash
kubectl port-forward -n tracing svc/jaeger-query 16686:16686
```

Luego abre: http://localhost:16686

**Minikube**:
```bash
minikube ip  # Ejemplo: 192.168.49.2
# Abre: http://192.168.49.2:30686
```

## Archivos

- `namespace.yaml` - Namespace de Kubernetes para tracing
- `jaeger-all-in-one.yaml` - Deployment de Jaeger (Collector + Query + UI)
- `deploy-jaeger.sh` - Script de deployment automatizado
- `update-services-with-jaeger.sh` - Script para configurar microservicios
- `verify-tracing.sh` - Script de verificación

## Componentes Desplegados

| Componente | Puerto | Descripción |
|------------|--------|-------------|
| Collector (Zipkin) | 9411 | Recibe traces (compatible con Zipkin) |
| Collector (HTTP) | 14268 | Recibe traces vía HTTP |
| Collector (gRPC) | 14250 | Recibe traces vía gRPC |
| Query UI | 16686 | Interfaz web |
| Health Check | 14269 | Endpoint de salud |

## Configuración de Microservicios

Los microservicios ya están configurados con:

```yaml
env:
  - name: SPRING_ZIPKIN_BASE_URL
    value: "http://jaeger-collector.tracing.svc.cluster.local:9411"
  - name: SPRING_SLEUTH_SAMPLER_PROBABILITY
    value: "1.0"  # 100% sampling
  - name: SPRING_APPLICATION_NAME
    value: "service-name"
```

## Uso

### Buscar Traces

1. Abre Jaeger UI
2. Selecciona un servicio (ej: `user-service`)
3. Click en "Find Traces"
4. Explora los traces

### Buscar por Tags

```
error=true                    # Traces con errores
http.status_code=500          # Errores 500
http.method=POST              # Solo POST requests
```

### Buscar por Trace ID

Copia el Trace ID de los logs y búscalo en Jaeger:

```
[user-service,5c1a7b3f9d2e8a4c,...]
              ^Trace ID
```

## Troubleshooting

### No aparecen traces

```bash
# Verificar que Jaeger está corriendo
kubectl get pods -n tracing

# Ver logs
kubectl logs -n tracing deployment/jaeger

# Verificar conectividad
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://jaeger-collector.tracing.svc.cluster.local:9411
```

### Verificar configuración de microservicios

```bash
kubectl get pod <pod-name> -o yaml | grep -A 3 ZIPKIN
```

## Documentación Completa

Ver `docs/DISTRIBUTED_TRACING.md` para:
- Guía completa de uso
- Casos de uso
- Troubleshooting detallado
- Integración con Prometheus/Grafana
- Mejores prácticas

## Comandos Útiles

```bash
# Ver recursos
kubectl get all -n tracing

# Ver logs
kubectl logs -n tracing deployment/jaeger -f

# Reiniciar (limpia traces en memoria)
kubectl rollout restart deployment/jaeger -n tracing

# Eliminar
kubectl delete namespace tracing
```

## Performance

- **Desarrollo**: Sampling 100% (configurado actualmente)
- **Producción**: Cambiar a 10% editando `SPRING_SLEUTH_SAMPLER_PROBABILITY=0.1`

## Stack Completo de Observabilidad

- **Metrics**: Prometheus + Grafana (namespace: `monitoring`)
- **Logs**: ELK Stack + Filebeat (namespace: `logging`)
- **Traces**: Jaeger (namespace: `tracing`)

---

Universidad ICESI - Ingeniería de Software V
