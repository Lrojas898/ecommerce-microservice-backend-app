# Pipeline Configuration Guide

## Overview

Este documento describe la configuración de los pipelines de Jenkins utilizados en el proyecto.

## Pipelines Disponibles

### 1. Build Pipeline (`Jenkinsfile.build.local`)
**Propósito**: Compilar y probar servicios individualmente

**Triggers**:
- Push a `feature/*` branches
- Pull requests

**Stages**:
1. Initialize
2. Checkout
3. Build Services
4. Run Unit Tests
5. SonarQube Analysis

**Variables de Ambiente**:
- `DOCKER_USER`: Usuario de Docker Hub
- `SERVICES_TO_BUILD`: Lista de servicios a compilar

---

### 2. Deploy Dev Pipeline (`Jenkinsfile.deploy-dev.local`)
**Propósito**: Desplegar a ambiente de desarrollo

**Triggers**:
- Merge a `develop`
- Manual trigger

**Stages**:
1. Initialize
2. Configure kubectl
3. Detect Services to Deploy
4. Deploy Infrastructure Services
5. Deploy Microservices
6. Deploy API Gateway
7. Verify Deployment
8. Run Basic Health Checks

**Namespace Kubernetes**: `dev`

---

### 3. Deploy Prod Pipeline (`Jenkinsfile.deploy-prod.local`)
**Propósito**: Desplegar a ambiente de producción

**Triggers**:
- Merge a `master` (con aprobación manual)
- Tags de release (`v*.*.*`)

**Stages**:
1. Initialize
2. Configure kubectl
3. Create Namespace
4. Detect Services to Deploy
5. **Manual Approval** (30 min timeout)
6. Cleanup Resources
7. Deploy Infrastructure Services
8. Deploy Microservices
9. Deploy API Gateway
10. Verify Deployment
11. Wait for Services Ready
12. **Run E2E Tests**
13. **SonarQube Analysis**
14. Deployment Summary

**Namespace Kubernetes**: `prod`

**Características especiales**:
- Requiere aprobación manual
- Ejecuta suite completa de pruebas E2E
- Genera Release Notes automáticamente
- Rollback automático en caso de fallo

---

### 4. Performance Tests Pipeline (`Jenkinsfile.performance-tests`)
**Propósito**: Ejecutar pruebas de rendimiento con Locust

**Triggers**:
- Manual trigger con parámetros

**Parámetros**:
- `ENVIRONMENT`: dev o prod
- `TEST_TYPE`: Tipo de prueba de carga
- `USERS`: Número de usuarios concurrentes
- `SPAWN_RATE`: Usuarios por segundo
- `RUN_TIME`: Duración de la prueba

**Stages**:
1. Initialize
2. Get API Gateway URL
3. Verify Services Health
4. Install Locust Dependencies
5. Run Performance Tests
6. Analyze Results
7. Publish HTML Reports
8. **SonarQube Analysis - Performance Tests**

---

## Variables de Ambiente Comunes

### Docker Configuration
```groovy
DOCKER_REGISTRY = 'docker.io'
DOCKER_USER = 'your-dockerhub-username'
```

### Kubernetes Configuration
```groovy
K8S_NAMESPACE = 'dev' | 'staging' | 'prod'
```

### Service Lists
```groovy
ALL_SERVICES = 'service-discovery,user-service,product-service,order-service,payment-service,shipping-service,favourite-service,proxy-client,api-gateway'
```

### Timeouts
```groovy
MAX_RETRY_COUNT = '5'
SERVICE_READINESS_TIMEOUT = '600'  // 10 minutes
POD_READY_TIMEOUT = '300'          // 5 minutes
```

---

## SonarQube Integration

### E2E Tests Analysis
```groovy
mvn sonar:sonar \
  -Dsonar.host.url=http://172.17.0.1:9000 \
  -Dsonar.token=squ_ed5405cbe3456c97523f39f0eceb7d9c4c26c5b3 \
  -Dsonar.projectKey=ecommerce-e2e-tests \
  -Dsonar.projectName="E-Commerce E2E Tests"
```

### Performance Tests Analysis
```groovy
./sonar-scanner/bin/sonar-scanner \
  -Dsonar.host.url=http://172.17.0.1:9000 \
  -Dsonar.token=squ_1037e66e9bc493d2a288dbca5a9cb503f0637c93 \
  -Dsonar.projectKey=ecommerce-performance-tests \
  -Dsonar.sources=. \
  -Dsonar.language=py
```

---

## Mejores Prácticas

### 1. Manejo de Errores
- Todos los pipelines tienen `try-catch` en stages críticos
- SonarQube analysis es non-blocking
- Rollback automático en producción si falla deployment

### 2. Timeouts
- Build Pipeline: 30 minutos
- Deploy Dev: 45 minutos
- Deploy Prod: 60 minutos
- Performance Tests: 2 horas

### 3. Artefactos
Todos los pipelines archivan:
- Manifiestos de Kubernetes (`*.yaml`)
- Release Notes (solo prod)
- Reportes de pruebas (HTML, XML)
- Reportes de performance (CSV, HTML)

### 4. Notificaciones
- Success: Log en consola
- Failure: Log + diagnostic info (pods, events)
- Unstable: Warning con detalles

---

## Ejecución de Pipelines

### Desde Jenkins UI
1. Navegar al pipeline deseado
2. Click en "Build with Parameters"
3. Configurar parámetros
4. Click en "Build"

### Desde Git (Automático)
Los pipelines se ejecutan automáticamente en los siguientes casos:

- **Build**: Push a `feature/*` branches
- **Deploy Dev**: Merge/push a `develop`
- **Deploy Prod**: Merge a `master` (requiere aprobación)

---

## Troubleshooting

### Pipeline falla en "Deploy Services"
```bash
# Verificar pods
kubectl get pods -n <namespace>

# Ver logs
kubectl logs -f <pod-name> -n <namespace>

# Verificar eventos
kubectl get events -n <namespace> --sort-by=.firstTimestamp
```

### E2E Tests fallan
```bash
# Verificar conectividad
curl http://api-gateway-url/actuator/health

# Verificar port-forward
kubectl port-forward -n prod svc/api-gateway 18080:80
```

### Performance Tests timeout
- Aumentar `RUN_TIME` parameter
- Reducir `USERS` o `SPAWN_RATE`
- Verificar recursos de cluster (CPU, memoria)

---

## Configuración de Webhooks (Futuro)

Para automatizar triggers desde GitHub:

1. Jenkins > Configurar
2. GitHub project: URL del repositorio
3. Build Triggers > GitHub hook trigger for GITScm polling
4. GitHub > Settings > Webhooks > Add webhook
5. Payload URL: `http://jenkins-url/github-webhook/`

---

## Próximas Mejoras

- [ ] Implementar pipeline para staging environment
- [ ] Agregar notificaciones por Slack/Email
- [ ] Implementar blue-green deployment
- [ ] Agregar smoke tests automáticos post-deploy
- [ ] Integrar con herramienta de APM (Application Performance Monitoring)

---

**Última actualización**: 2025-11-03
**Versión**: 1.0
**Autor**: DevOps Team
