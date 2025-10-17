# Checklist Completo - Taller 2: Pruebas y Lanzamiento

## Estado General: 80% Completado (Kubernetes ✅)

---

## Punto 1 (10%): Configurar Jenkins, Docker y Kubernetes

### Jenkins (95% completado - Instalándose)
- [x] EC2 instance creada (t3.micro con 20GB disco)
- [x] Security group configurado (puerto 8080 abierto)
- [x] **Jenkins instalándose automáticamente via Docker** ⏳
- [x] Instance ID: i-0508373735bd24d6c
- [x] Public IP: 54.237.228.186
- [x] **Jenkins URL: http://54.237.228.186:8080** (esperar 3-5 minutos)

**Problema resuelto:** Primera instancia falló por falta de espacio en disco (8GB insuficiente). Nueva instancia con 20GB funcionando correctamente.

**Pendiente (cuando Jenkins esté listo):**
- [ ] **Acceder a Jenkins UI** (http://54.237.228.186:8080)
- [ ] **Obtener password inicial** (ver instrucciones abajo)
- [ ] **Instalar plugins requeridos:**
  - [ ] Docker Pipeline
  - [ ] Kubernetes
  - [ ] AWS Steps
  - [ ] Git
  - [ ] Pipeline
  - [ ] Blue Ocean (opcional)
- [ ] **Configurar credenciales:**
  - [ ] AWS credentials (Access Key + Secret)
  - [ ] GitHub credentials
  - [ ] Docker Hub / ECR credentials
- [ ] **Capturar screenshots:**
  - [ ] Dashboard de Jenkins
  - [ ] Plugins instalados
  - [ ] Credenciales configuradas

### Docker (80% completado)
- [x] 6 Dockerfiles creados (multi-stage)
- [x] ECR repositories creados
- [x] Scripts de build preparados
- [ ] **Verificar Docker en Jenkins:**
  ```bash
  ssh ec2-user@98.91.95.121
  docker --version
  docker ps
  ```
- [ ] **Hacer build de prueba:**
  ```bash
  cd order-service
  docker build -t test-order .
  ```

### Kubernetes (100% completado) ✅
- [x] Terraform configurado para EKS
- [x] Manifests de Kubernetes creados
- [x] **EKS cluster ACTIVO** ✅
- [x] **Node Group creado** (2 nodos t3.small) ✅
- [x] **kubectl instalado y configurado** ✅
- [x] **Namespaces creados:** dev, staging, production ✅
- [x] **Script de verificación creado** (verify-cluster.sh) ✅

**Estado actual:**
- Cluster: ecommerce-microservices-cluster (ACTIVE)
- Nodes: 2/2 Ready (ip-172-31-28-98, ip-172-31-71-126)
- Version: v1.28.15-eks-113cf36
- Namespaces: dev, staging, production

**Screenshots necesarios:**
- [ ] EKS cluster en AWS Console
- [ ] Nodes corriendo (kubectl get nodes) - ✅ Listo para capturar
- [ ] Namespaces creados - ✅ Listo para capturar

---

## Punto 2 (15%): Pipeline DEV - 90% completado

### Código (100% completado)
- [x] Jenkinsfile.dev creado
- [x] Dockerfiles optimizados
- [x] Scripts de build (build-and-push.sh)
- [x] ECR repositories configurados

### Ejecución (0% completado)
- [ ] **Crear job en Jenkins:**
  - [ ] Nombre: `ecommerce-dev-pipeline`
  - [ ] Tipo: Pipeline
  - [ ] SCM: Git (URL del repo)
  - [ ] Script Path: infrastructure/jenkins/Jenkinsfile.dev
- [ ] **Ejecutar pipeline primera vez**
- [ ] **Verificar en ECR:**
  ```bash
  aws ecr list-images --repository-name ecommerce/order-service
  ```
- [ ] **Capturar screenshots:**
  - [ ] Configuración del job
  - [ ] Ejecución exitosa (verde)
  - [ ] Console output
  - [ ] Imágenes en ECR

---

## Punto 3 (30%): Pruebas - 100% implementado, 0% ejecutado

### Implementación (100% completado) ✅
- [x] 6 pruebas unitarias (requería 5)
- [x] 6 pruebas de integración (requería 5)
- [x] 5 pruebas E2E
- [x] 5 escenarios Locust
- [x] Documentación completa

### Ejecución local (0% completado)
- [ ] **Ejecutar pruebas unitarias:**
  ```bash
  ./mvnw clean test
  ```
- [ ] **Ejecutar pruebas de integración:**
  ```bash
  ./mvnw verify
  ```
- [ ] **Capturar screenshots:**
  - [ ] Resultado de pruebas unitarias
  - [ ] Resultado de pruebas de integración
  - [ ] Cobertura de código (si aplica)

### Ejecución E2E (0% completado)
- [ ] **Iniciar servicios:**
  ```bash
  docker-compose up -d
  # O desplegar en Kubernetes
  kubectl apply -f infrastructure/kubernetes/base/ -n dev
  ```
- [ ] **Ejecutar pruebas E2E:**
  ```bash
  cd tests/e2e
  mvn test -Dapi.url=http://[API_GATEWAY_URL]
  ```
- [ ] **Capturar screenshots:**
  - [ ] Pruebas E2E exitosas
  - [ ] Detalles de cada flujo

### Pruebas de Rendimiento (0% completado)
- [ ] **Instalar Locust:**
  ```bash
  cd tests/performance
  pip install -r requirements.txt
  ```
- [ ] **Ejecutar prueba de carga:**
  ```bash
  locust -f locustfile.py MixedWorkloadUser \
         --host=http://[API_URL] \
         --users 100 --spawn-rate 10 --run-time 5m \
         --headless --html report.html
  ```
- [ ] **Capturar screenshots:**
  - [ ] Dashboard de Locust
  - [ ] Gráficas de RPS
  - [ ] Gráficas de tiempos de respuesta
  - [ ] Tabla de estadísticas
- [ ] **Analizar métricas:**
  - [ ] p50, p95, p99 response times
  - [ ] Throughput (RPS)
  - [ ] Error rate
  - [ ] Identificar cuellos de botella

---

## Punto 4 (15%): Pipeline STAGE - 80% completado

### Código (100% completado)
- [x] Jenkinsfile.stage creado
- [x] Integración de todas las pruebas
- [x] Deployment a Kubernetes staging

### Ejecución (0% completado)
- [ ] **Crear job en Jenkins:**
  - [ ] Nombre: `ecommerce-stage-pipeline`
  - [ ] Configurar trigger desde dev
- [ ] **Ejecutar pipeline completo**
- [ ] **Verificar en Kubernetes:**
  ```bash
  kubectl get all -n staging
  kubectl logs -n staging -l app=order-service
  ```
- [ ] **Capturar screenshots:**
  - [ ] Pipeline ejecutándose
  - [ ] Todas las etapas pasando
  - [ ] Pruebas ejecutándose
  - [ ] Deploy en staging exitoso
  - [ ] Pods corriendo en K8s

---

## Punto 5 (15%): Pipeline PROD - 80% completado

### Código (100% completado)
- [x] Jenkinsfile.prod creado
- [x] Aprobación manual configurada
- [x] Generación de Release Notes
- [x] Deployment a production

### Ejecución (0% completado)
- [ ] **Crear job en Jenkins:**
  - [ ] Nombre: `ecommerce-prod-pipeline`
  - [ ] Configurar trigger desde stage
- [ ] **Ejecutar pipeline completo**
- [ ] **Aprobar manualmente cuando solicite**
- [ ] **Verificar Release Notes generados**
- [ ] **Verificar deployment:**
  ```bash
  kubectl get all -n production
  kubectl describe deployment order-service -n production
  ```
- [ ] **Capturar screenshots:**
  - [ ] Input de aprobación manual
  - [ ] Release Notes generados
  - [ ] Deploy en production
  - [ ] Verificación de servicios

---

## Punto 6 (15%): Documentación - 40% completado

### Documentación existente (40%)
- [x] infrastructure/terraform/README.md
- [x] RESUMEN_PRUEBAS.md
- [x] COMANDOS_RAPIDOS.md
- [x] tests/performance/README.md

### Documentación faltante (60%)
- [ ] **Documento principal del reporte** (Word/PDF)
  - [ ] Portada
  - [ ] Índice
  - [ ] Introducción
  - [ ] Arquitectura del sistema
  - [ ] Configuración (Punto 1)
  - [ ] Pipelines (Puntos 2, 4, 5)
  - [ ] Pruebas (Punto 3)
  - [ ] Análisis de resultados
  - [ ] Conclusiones

### Screenshots por Pipeline

#### Pipeline DEV:
- [ ] Configuración del job
- [ ] Ejecución exitosa
- [ ] Console output
- [ ] Build artifacts
- [ ] Imágenes en ECR

#### Pipeline STAGE:
- [ ] Configuración del job
- [ ] Ejecución con todas las etapas
- [ ] Pruebas unitarias ejecutándose
- [ ] Pruebas de integración ejecutándose
- [ ] Deploy a staging
- [ ] Pods en Kubernetes staging

#### Pipeline PROD:
- [ ] Configuración del job
- [ ] Input de aprobación manual
- [ ] Release Notes generados
- [ ] Deploy a production
- [ ] Verificación de servicios
- [ ] Pods en Kubernetes production

### Análisis de Resultados
- [ ] **Pruebas Unitarias:**
  - [ ] Número de pruebas
  - [ ] Tiempo de ejecución
  - [ ] Cobertura de código
  - [ ] Interpretación

- [ ] **Pruebas de Integración:**
  - [ ] Servicios probados
  - [ ] Flujos validados
  - [ ] Tiempo de ejecución
  - [ ] Problemas encontrados

- [ ] **Pruebas E2E:**
  - [ ] Flujos completos validados
  - [ ] Tiempo total
  - [ ] Casos de éxito/fallo

- [ ] **Pruebas de Rendimiento (CRÍTICO):**
  - [ ] Response time promedio
  - [ ] p50, p95, p99
  - [ ] Throughput (RPS)
  - [ ] Error rate
  - [ ] Identificación de cuellos de botella
  - [ ] Recomendaciones de optimización

### Release Notes
- [ ] **Release Notes DEV:**
  - [ ] Versión
  - [ ] Fecha
  - [ ] Features
  - [ ] Bugs fixed
  - [ ] Known issues

- [ ] **Release Notes STAGING:**
  - [ ] Versión
  - [ ] Validaciones realizadas
  - [ ] Issues resueltos

- [ ] **Release Notes PRODUCTION:**
  - [ ] Versión final
  - [ ] Aprobaciones
  - [ ] Deployment plan
  - [ ] Rollback plan

### ZIP con Pruebas
- [ ] **Crear estructura:**
  ```
  pruebas-taller2/
  ├── unit/
  │   ├── CredentialServiceImplTest.java
  │   ├── CartServiceImplTest.java
  │   ├── PaymentServiceImplTest.java
  │   └── ...
  ├── integration/
  │   ├── UserServiceIntegrationTest.java
  │   ├── PaymentOrderIntegrationTest.java
  │   └── ...
  ├── e2e/
  │   ├── UserRegistrationE2ETest.java
  │   ├── OrderCreationE2ETest.java
  │   └── ...
  ├── performance/
  │   ├── locustfile.py
  │   ├── requirements.txt
  │   └── README.md
  └── README.md (instrucciones de ejecución)
  ```
- [ ] Comprimir en ZIP
- [ ] Verificar que descomprime correctamente

---

## Priorización de Tareas Restantes

### 🔴 URGENTE (Hacer HOY)
1. ✅ ~~Esperar que EKS termine de crearse~~ **COMPLETADO**
2. ✅ ~~Instalar kubectl~~ **COMPLETADO**
3. ✅ ~~Crear Node Group~~ **COMPLETADO (2 nodos t3.small)**
4. ✅ ~~Crear namespaces en Kubernetes~~ **COMPLETADO**
5. Instalar Jenkins completamente (PRÓXIMO PASO)
6. Configurar kubectl en Jenkins
7. Crear primer job (dev pipeline)
8. Ejecutar y capturar screenshot

### 🟡 IMPORTANTE (Hacer MAÑANA)
7. Ejecutar pruebas localmente y capturar resultados
8. Ejecutar pipelines stage y prod
9. Ejecutar Locust y analizar métricas
10. Capturar todos los screenshots faltantes

### 🟢 FINAL (Antes de entregar)
11. Crear documento principal del reporte
12. Escribir análisis de resultados
13. Generar Release Notes
14. Crear ZIP con pruebas
15. Revisión final

---

## Estimación de Tiempo Restante

| Tarea | Tiempo Estimado |
|-------|----------------|
| Configurar Jenkins | 1 hora |
| Ejecutar pipelines y screenshots | 2 horas |
| Ejecutar y analizar pruebas | 2 horas |
| Crear documento del reporte | 3 horas |
| Release Notes y empaquetado | 1 hora |
| **TOTAL** | **9 horas** |

---

## Notas Importantes

- ⚠️ EKS con t2.micro será LENTO - considera esto en tus pruebas
- ⚠️ Jenkins en t2.micro también será limitado
- ✅ El 75% del trabajo ya está hecho (código)
- ✅ Solo falta EJECUTAR y DOCUMENTAR
- 💡 Prioriza screenshots DURANTE la ejecución, no después
- 💡 Toma notas de problemas encontrados para el análisis

---

**Última actualización:** 2025-10-16
**Siguiente paso:** Esperar creación de EKS y configurar Jenkins
