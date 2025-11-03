# Documentación del Proyecto

## Índice de Documentación

### 📋 Estrategia y Configuración
- **[BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md)** - Estrategia de branching GitFlow para dev, staging y producción
- **[PIPELINE_CONFIGURATION.md](PIPELINE_CONFIGURATION.md)** - Configuración detallada de pipelines de Jenkins

### 🧪 Testing
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Guía completa de estrategia de pruebas (unit, integration, E2E, performance)

### 🚀 Despliegue
Los pipelines de Jenkins están ubicados en: `infrastructure/jenkins-pipeline/`

## Estructura del Proyecto

```
ecommerce-microservice-backend-app/
├── docs/                          # Documentación
├── infrastructure/
│   ├── jenkins-pipeline/          # Jenkinsfiles
│   └── kubernetes/                # Manifiestos K8s
├── tests/                         # Pruebas E2E
│   ├── src/test/java/            # Tests Java
│   └── performance/               # Pruebas Locust
├── user-service/                  # Microservicio de usuarios
├── product-service/               # Microservicio de productos
├── order-service/                 # Microservicio de órdenes
├── payment-service/               # Microservicio de pagos
├── shipping-service/              # Microservicio de envíos
├── favourite-service/             # Microservicio de favoritos
├── api-gateway/                   # API Gateway
└── service-discovery/             # Eureka Server
```

## Guías Rápidas

### Iniciar el Proyecto Localmente
```bash
# Build todos los servicios
mvn clean package -DskipTests

# Desplegar en Kubernetes local (Minikube)
kubectl apply -f infrastructure/kubernetes/base/

# Verificar deployments
kubectl get pods
```

### Ejecutar Pruebas
```bash
# Pruebas unitarias
mvn test

# Pruebas E2E
cd tests && mvn verify -Pe2e-tests

# Pruebas de performance
cd tests/performance
locust -f locustfile.py --host=http://localhost:8080
```

### Triggers de Pipelines
- **feature/* → Build Pipeline** (automático)
- **develop → Deploy Dev** (automático)
- **master → Deploy Prod** (requiere aprobación manual)

## Ambientes

| Ambiente | Namespace | Branch | Pipeline |
|----------|-----------|--------|----------|
| Development | `dev` | `develop` | Jenkinsfile.deploy-dev.local |
| Staging | `staging` | `release/*` | Jenkinsfile.deploy-prod.local |
| Production | `prod` | `master` | Jenkinsfile.deploy-prod.local |

## Versionado

Seguimos **Semantic Versioning**: `MAJOR.MINOR.PATCH`

- `v1.0.0` - Primera versión estable
- `v1.1.0` - Nueva funcionalidad
- `v1.1.1` - Bug fix

## Contacto y Soporte

- **Repositorio**: https://github.com/Lrojas898/ecommerce-microservice-backend-app
- **Jenkins**: http://localhost:8080 (local)
- **SonarQube**: http://localhost:9000 (local)

---

**Taller 2: Pruebas y Lanzamiento**
Universidad ICESI - Ingeniería de Software V
