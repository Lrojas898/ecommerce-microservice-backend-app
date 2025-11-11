# Jaeger Distributed Tracing - Quick Start Guide

## 1. Deploy Jaeger (2 minutos)

```bash
cd infrastructure/kubernetes/tracing
./deploy-jaeger.sh
```

Espera a que el pod esté ready (puedes ver el progreso en la salida del script).

## 2. Verify Installation (30 segundos)

```bash
./verify-tracing.sh
```

Deberías ver todos los checks en verde.

## 3. Access Jaeger UI

### Opción A: Port-Forward (Recomendado)

```bash
kubectl port-forward -n tracing svc/jaeger-query 16686:16686
```

Abre en tu navegador: **http://localhost:16686**

### Opción B: Minikube NodePort

```bash
minikube ip  # Ejemplo: 192.168.49.2
```

Abre en tu navegador: **http://192.168.49.2:30686**

## 4. Redeploy Microservices (5 minutos)

Los microservicios ya están configurados, solo necesitas redesplegarlos:

```bash
# Si usas el pipeline de Jenkins
# Triggerea el deploy-dev o deploy-prod pipeline

# O manualmente:
kubectl rollout restart deployment/user-service -n dev
kubectl rollout restart deployment/product-service -n dev
kubectl rollout restart deployment/order-service -n dev
kubectl rollout restart deployment/payment-service -n dev
kubectl rollout restart deployment/shipping-service -n dev
kubectl rollout restart deployment/favourite-service -n dev
kubectl rollout restart deployment/api-gateway -n dev
```

## 5. Generate Traffic

### Opción A: Run E2E Tests

```bash
cd tests
mvn verify -Pe2e-tests
```

### Opción B: Manual Testing

```bash
# Port-forward API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:80

# Create a user
curl -X POST http://localhost:8080/app/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com"
  }'

# Get products
curl http://localhost:8080/app/api/products

# Create an order
curl -X POST http://localhost:8080/app/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderDate": "2025-11-11T12:00:00",
    "orderDesc": "Test order",
    "orderFee": 100.0
  }'
```

## 6. View Traces in Jaeger

1. Abre Jaeger UI (http://localhost:16686)
2. En el dropdown "Service", selecciona **api-gateway**
3. Click en **Find Traces**
4. Deberías ver los traces generados por tus requests
5. Haz click en cualquier trace para ver el detalle completo

### Ejemplo de lo que verás:

```
api-gateway: POST /app/api/orders    [450ms]
  ├─ user-service: GET /users/123    [50ms]
  ├─ product-service: GET /products  [30ms]
  └─ order-service: CREATE order     [350ms]
      ├─ payment-service: PROCESS    [200ms]
      └─ shipping-service: CREATE    [100ms]
```

## 7. Explore Features

### Search by Service
- Select service: `order-service`
- Click "Find Traces"

### Search by Tags
```
error=true                    # Only traces with errors
http.status_code=500          # Only 500 errors
http.method=POST              # Only POST requests
```

### Search by Duration
```
Min Duration: 1s              # Traces slower than 1 second
Max Duration: 5s              # Traces faster than 5 seconds
```

### Search by Trace ID
```
Copy Trace ID from logs:
[user-service,5c1a7b3f9d2e8a4c,...]
              ^This is the Trace ID

Paste in search bar
```

## Common Issues

### No traces appearing?

```bash
# Check Jaeger is running
kubectl get pods -n tracing

# Check microservices logs for Trace IDs
kubectl logs -n dev deployment/user-service | grep -i "trace"

# Should see: [user-service,TRACE_ID,SPAN_ID]

# Check connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://jaeger-collector.tracing.svc.cluster.local:9411
```

### Jaeger UI not accessible?

```bash
# Check service
kubectl get svc -n tracing jaeger-query

# Check port-forward is running
ps aux | grep "port-forward.*16686"

# Restart port-forward if needed
kubectl port-forward -n tracing svc/jaeger-query 16686:16686
```

## Next Steps

- Read full documentation: `docs/DISTRIBUTED_TRACING.md`
- Integrate with Grafana dashboards
- Configure alerts based on traces
- Adjust sampling for production (10% instead of 100%)

## Stack Overview

Now you have complete observability:

```
┌─────────────────────────────────────┐
│   Metrics: Prometheus + Grafana     │  namespace: monitoring
├─────────────────────────────────────┤
│   Logs: ELK Stack + Filebeat        │  namespace: logging
├─────────────────────────────────────┤
│   Traces: Jaeger                    │  namespace: tracing
└─────────────────────────────────────┘
```

## Commands Cheat Sheet

```bash
# View all tracing resources
kubectl get all -n tracing

# View Jaeger logs
kubectl logs -n tracing deployment/jaeger -f

# Restart Jaeger (clears in-memory traces)
kubectl rollout restart deployment/jaeger -n tracing

# Access Jaeger UI
kubectl port-forward -n tracing svc/jaeger-query 16686:16686

# Check microservice configuration
kubectl get pod <pod-name> -n dev -o yaml | grep -A 3 ZIPKIN

# View traces in logs
kubectl logs -n dev deployment/user-service | grep "user-service,"
```

---

**Time to complete**: ~10 minutes
**Difficulty**: Easy
**Documentation**: See `docs/DISTRIBUTED_TRACING.md` for detailed guide

Universidad ICESI - Ingeniería de Software V
