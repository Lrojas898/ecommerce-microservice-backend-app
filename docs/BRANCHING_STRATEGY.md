# Branching Strategy - E-Commerce Microservices

## Estrategia de Branching: GitFlow Adaptado

Esta estrategia de branching está diseñada para soportar los tres ambientes requeridos en el taller:
- **Development (DEV)**: Ambiente de desarrollo para pruebas tempranas
- **Staging (STAGE)**: Ambiente de pruebas de integración y validación
- **Production (PROD)**: Ambiente de producción

---

## Estructura de Branches

### 1. Branch Principal: `master`
- **Propósito**: Representa el código en **PRODUCCIÓN**
- **Estabilidad**: Debe estar siempre en estado deployable
- **Pipeline**: `Jenkinsfile.deploy-prod` o `Jenkinsfile.deploy-prod.local`
- **Protecciones**:
  - Requiere Pull Request para merge
  - Requiere revisión de código (code review)
  - Requiere aprobación manual en Jenkins
  - Todas las pruebas deben pasar (unit, integration, E2E, performance)
  - Genera Release Notes automáticamente

**Triggers del Pipeline**:
- Merge de `release/*` branches
- Tag de versión (e.g., `v1.0.0`)

---

### 2. Branch de Desarrollo: `develop`
- **Propósito**: Representa el ambiente de **DESARROLLO (DEV)**
- **Estabilidad**: Integración continua de features
- **Pipeline**: `Jenkinsfile.deploy-dev` o `Jenkinsfile.deploy-dev.local`
- **Características**:
  - Ejecuta pruebas unitarias
  - Ejecuta pruebas de integración básicas
  - Deploy automático a DEV environment
  - Namespace Kubernetes: `dev`

**Triggers del Pipeline**:
- Push directo a `develop`
- Merge de `feature/*` branches

---

### 3. Feature Branches: `feature/*`
- **Propósito**: Desarrollo de nuevas funcionalidades
- **Nomenclatura**: `feature/descripcion-corta`
- **Ejemplos**:
  - `feature/add-product-reviews`
  - `feature/add-integration-tests`
  - `feature/payment-gateway-integration`
- **Pipeline**: `Jenkinsfile.build` o `Jenkinsfile.build.local`
- **Ciclo de vida**:
  1. Crear desde `develop`
  2. Desarrollo de la feature
  3. Ejecutar pruebas unitarias localmente
  4. Push a remote
  5. Jenkins ejecuta build y pruebas
  6. Pull Request hacia `develop`
  7. Code review
  8. Merge y eliminación del branch

---

### 4. Release Branches: `release/*`
- **Propósito**: Preparación de release para **STAGING y PRODUCCIÓN**
- **Nomenclatura**: `release/vX.Y.Z`
- **Ejemplos**:
  - `release/v1.0.0`
  - `release/v1.1.0`
- **Pipeline**: Ejecuta pruebas completas (E2E, performance, stress tests)
- **Ciclo de vida**:
  1. Crear desde `develop` cuando está listo para release
  2. Ejecutar todas las pruebas (unit, integration, E2E, performance)
  3. Deploy a STAGING environment
  4. QA y validación
  5. Fixes solo de bugs críticos
  6. Merge a `master` (producción)
  7. Tag de versión
  8. Merge de vuelta a `develop`

**Ambiente de Staging**:
- Namespace Kubernetes: `staging`
- Configuración idéntica a producción
- Datos de prueba

---

### 5. Hotfix Branches: `hotfix/*`
- **Propósito**: Corrección urgente en producción
- **Nomenclatura**: `hotfix/descripcion-bug`
- **Ejemplos**:
  - `hotfix/payment-processing-error`
  - `hotfix/critical-security-patch`
- **Pipeline**: Fast-track con pruebas esenciales
- **Ciclo de vida**:
  1. Crear desde `master`
  2. Aplicar fix
  3. Pruebas críticas
  4. Merge a `master` (producción)
  5. Tag de versión patch (e.g., v1.0.1)
  6. Merge a `develop` también

---

## Flujo de Trabajo por Ambiente

### Development Environment (DEV)

```
feature/new-functionality → develop → Deploy to DEV (Kubernetes namespace: dev)
```

**Pipeline**: `Jenkinsfile.deploy-dev.local`
- ✓ Build de servicios
- ✓ Pruebas unitarias
- ✓ Pruebas de integración básicas
- ✓ Deploy a Kubernetes (namespace: dev)
- ✓ Health checks

### Staging Environment (STAGE)

```
develop → release/vX.Y.Z → Deploy to STAGING (Kubernetes namespace: staging)
```

**Pipeline**: Incluido en `Jenkinsfile.deploy-prod` con aprobación manual
- ✓ Build de servicios
- ✓ Pruebas unitarias
- ✓ Pruebas de integración completas
- ✓ **Pruebas E2E completas**
- ✓ **Pruebas de performance (Locust)**
- ✓ Deploy a Kubernetes (namespace: staging)
- ✓ Validación manual

### Production Environment (PROD)

```
release/vX.Y.Z → master → Deploy to PRODUCTION (Kubernetes namespace: prod)
```

**Pipeline**: `Jenkinsfile.deploy-prod.local`
- ✓ Aprobación manual requerida
- ✓ Build de servicios
- ✓ Pruebas unitarias
- ✓ Pruebas de integración
- ✓ Pruebas E2E
- ✓ Smoke tests en staging
- ✓ Deploy a Kubernetes (namespace: prod)
- ✓ **Generación automática de Release Notes**
- ✓ Rollback automático en caso de fallo
- ✓ Tag de versión Git

---

## Mapeo de Pipelines

| Branch Pattern | Pipeline | Ambiente | Namespace K8s |
|---------------|----------|----------|---------------|
| `feature/*` | `Jenkinsfile.build.local` | Build only | N/A |
| `develop` | `Jenkinsfile.deploy-dev.local` | Development | `dev` |
| `release/*` | `Jenkinsfile.deploy-prod.local` (staging) | Staging | `staging` |
| `master` | `Jenkinsfile.deploy-prod.local` (prod) | Production | `prod` |

---

## Pruebas por Ambiente

### DEV (develop)
- ✓ Pruebas unitarias (todos los microservicios)
- ✓ Pruebas de integración básicas
- ✓ Build verification

### STAGING (release/*)
- ✓ Todas las pruebas de DEV +
- ✓ **5+ Pruebas E2E** (flujos completos de usuario)
- ✓ **Pruebas de performance con Locust**
- ✓ Pruebas de estrés
- ✓ Pruebas de carga
- ✓ Análisis de SonarQube

### PRODUCTION (master)
- ✓ Todas las pruebas de STAGING +
- ✓ Smoke tests post-deployment
- ✓ Health checks
- ✓ Monitoring alerts

---

## Microservicios del Proyecto

Los siguientes microservicios están incluidos en los pipelines:

1. **user-service**: Gestión de usuarios y autenticación
2. **product-service**: Catálogo de productos
3. **order-service**: Procesamiento de órdenes
4. **payment-service**: Procesamiento de pagos
5. **shipping-service**: Gestión de envíos
6. **favourite-service**: Lista de favoritos
7. **api-gateway**: Gateway de entrada
8. **service-discovery**: Eureka server
9. **proxy-client**: Cliente proxy para comunicación

---

## Versionado Semántico

Seguimos **Semantic Versioning** (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR** (X.0.0): Cambios incompatibles en API
- **MINOR** (0.X.0): Nuevas funcionalidades compatibles
- **PATCH** (0.0.X): Bug fixes

**Ejemplos**:
- `v1.0.0`: Primera versión estable en producción
- `v1.1.0`: Nueva funcionalidad (agregado de reviews)
- `v1.1.1`: Hotfix de bug en payment processing

---

## Release Notes Automáticos

Cada deploy a producción genera automáticamente Release Notes que incluyen:

- Fecha y hora del release
- Build number de Jenkins
- Lista de servicios actualizados con versiones
- Docker images deployadas
- Cambios por servicio (últimos commits)
- Resultados de pruebas
- Comandos de rollback

**Ubicación**: Archivados como artifacts en Jenkins

---

## Comandos Útiles

### Crear feature branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/nombre-feature
```

### Crear release branch
```bash
git checkout develop
git pull origin develop
git checkout -b release/v1.2.0
```

### Merge feature a develop (después de PR aprobado)
```bash
git checkout develop
git merge feature/nombre-feature
git push origin develop
git branch -d feature/nombre-feature
```

### Crear release (después de merge a master)
```bash
git checkout master
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

### Rollback en caso de problemas
```bash
kubectl rollout undo deployment/service-name -n prod
```

---

## Protecciones de Branches Recomendadas

### Para `master`:
- Require pull request reviews (mínimo 1 revisor)
- Require status checks to pass before merging
- Require branches to be up to date before merging
- No permitir force pushes
- No permitir deletes

### Para `develop`:
- Require pull request reviews (opcional: 1 revisor)
- Require status checks to pass before merging
- Permitir force push solo a administradores

---

## Change Management

### Proceso de Deploy a Producción

1. **Pre-deployment**:
   - Code review completado
   - Todas las pruebas pasan en staging
   - Release notes generados
   - Stakeholders notificados

2. **Deployment**:
   - Aprobación manual en Jenkins
   - Deploy incremental (servicio por servicio)
   - Health checks después de cada servicio
   - Monitoring activo

3. **Post-deployment**:
   - Smoke tests ejecutados
   - Monitoreo de errores (primeros 30 minutos críticos)
   - Release notes archivados
   - Tag de versión creado
   - Comunicación a stakeholders

4. **En caso de problemas**:
   - Rollback automático si falla health check
   - Rollback manual disponible vía Jenkins o kubectl
   - Post-mortem para identificar causa raíz

---

## Ejemplo de Flujo Completo

```
1. Developer: git checkout -b feature/add-payment-retry develop
2. Developer: [desarrollo + commits + pruebas locales]
3. Developer: git push origin feature/add-payment-retry
4. Jenkins: Ejecuta Jenkinsfile.build.local (build + unit tests)
5. Developer: Crea PR de feature → develop
6. Reviewer: Code review + aprobación
7. Developer: Merge PR a develop
8. Jenkins: Ejecuta Jenkinsfile.deploy-dev.local → Deploy to DEV
9. QA: Validación en ambiente DEV
10. Release Manager: git checkout -b release/v1.3.0 develop
11. Jenkins: Deploy to STAGING (E2E + Performance tests)
12. QA: Validación completa en STAGING
13. Release Manager: Merge release/v1.3.0 → master (vía PR)
14. Jenkins: Aprobación manual requerida
15. Release Manager: Aprueba deploy en Jenkins
16. Jenkins: Deploy to PRODUCTION + Release Notes
17. Jenkins: Crea tag v1.3.0
18. Release Manager: Merge release/v1.3.0 → develop
```

---

## Herramientas Requeridas

- **Git**: Control de versiones
- **Jenkins**: CI/CD automation
- **Docker**: Containerización
- **Kubernetes**: Orquestación (Minikube/K3s local)
- **Maven**: Build tool para microservicios Java
- **Locust**: Performance testing
- **SonarQube**: Análisis de calidad de código
- **GitHub**: Repositorio + Pull Requests

---

## Referencias

- [GitFlow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Semantic Versioning](https://semver.org/)
- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

---

**Última actualización**: 2025-11-03
**Versión**: 1.0
**Autor**: DevOps Team - Taller 2
