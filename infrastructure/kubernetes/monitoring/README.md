# Monitoring Stack - Prometheus & Grafana

Monitoreo completo para E-Commerce Microservices usando Prometheus y Grafana.

## Quick Start

```bash
# Deploy monitoring stack
./deploy-monitoring.sh

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open: http://localhost:9090

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open: http://localhost:3000
# Login: admin / admin123
```

## Archivos

- `namespace.yaml` - Namespace de monitoring
- `prometheus-config.yaml` - Configuración de Prometheus (scraping)
- `prometheus.yaml` - Deployment y services de Prometheus
- `grafana-config.yaml` - Datasources y dashboards de Grafana
- `grafana.yaml` - Deployment y services de Grafana
- `deploy-monitoring.sh` - Script de deployment automático
- `application-monitoring-config.yaml` - Configuración de referencia para microservicios

## Arquitectura

```
Prometheus (scrapes every 15s)
    ↓
Microservices (/actuator/prometheus)
    - user-service
    - product-service
    - order-service
    - payment-service
    - shipping-service
    - favourite-service
    - api-gateway
    - service-discovery
    ↓
Grafana (visualización)
```

## Recursos Desplegados

**Prometheus**:
- Deployment: 1 replica
- PVC: 10Gi (retención 30 días)
- Services: ClusterIP (9090) + NodePort (30090)

**Grafana**:
- Deployment: 1 replica
- PVC: 5Gi
- Services: ClusterIP (3000) + NodePort (30030)
- Datasource Prometheus: preconfigurado
- Dashboard Spring Boot: preinstalado

## Verificación

```bash
# Ver todos los recursos
kubectl get all -n monitoring

# Ver PVCs
kubectl get pvc -n monitoring

# Ver targets en Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir: http://localhost:9090/targets

# Verificar métricas de un servicio
kubectl port-forward -n dev svc/user-service 8081:8081
curl http://localhost:8081/user-service/actuator/prometheus
```

## Documentación Completa

Ver: [docs/MONITORING_SETUP.md](../../../docs/MONITORING_SETUP.md)

## Troubleshooting

**Targets DOWN en Prometheus**:
```bash
# Verificar que servicios estén expuestos
kubectl get svc -n dev
kubectl get svc -n prod

# Verificar logs de Prometheus
kubectl logs -f deployment/prometheus -n monitoring
```

**Grafana no muestra datos**:
```bash
# Verificar datasource
# En Grafana UI: Configuration → Data Sources → Prometheus → Test

# Verificar logs
kubectl logs -f deployment/grafana -n monitoring
```

## Comandos Útiles

```bash
# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Delete monitoring stack
kubectl delete namespace monitoring

# Scale up/down
kubectl scale deployment/prometheus --replicas=0 -n monitoring
kubectl scale deployment/prometheus --replicas=1 -n monitoring
```

## Métricas Disponibles

- JVM: memoria, GC, threads
- HTTP: requests, latency, status codes
- Circuit Breaker: estado, tasa de fallos
- Database: conexiones HikariCP
- Custom: métricas de negocio

## Grafana Dashboards

**Preinstalado**:
- Spring Boot Microservices Overview

**Recomendados para importar** (Dashboard → Import):
- JVM (Micrometer): ID `4701`
- Spring Boot 2.1 Statistics: ID `10280`
- Kubernetes Cluster Monitoring: ID `7249`

---

**Credenciales Grafana**:
- User: `admin`
- Password: `admin123` (⚠️ cambiar en producción)
