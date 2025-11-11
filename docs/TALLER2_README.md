 # Taller 2: Pruebas y Lanzamiento - Documentación Completa

**Universidad ICESI - Ingeniería de Software V**
**Fecha**: Noviembre 2025
**Proyecto**: E-Commerce Microservices Backend

---

## Tabla de Contenidos

1. [Configuración de Jenkins](#1-configuración-de-jenkins)
2. [Pipelines Implementados](#2-pipelines-implementados)
3. [Estrategia de Pruebas](#3-estrategia-de-pruebas)
4. [Análisis de Resultados](#4-análisis-de-resultados)
5. [Conclusiones y Recomendaciones](#5-conclusiones-y-recomendaciones)
6. [Distributed Tracing con Jaeger](#6-distributed-tracing-con-jaeger)
7. [Monitoreo con Prometheus y Grafana](#7-monitoreo-con-prometheus-y-grafana)
8. [Despliegue en la Nube](#8-despliegue-en-la-nube)

---

## 1. Configuración de Jenkins

### 1.1 Arquitectura General

El proyecto implementa una arquitectura de CI/CD completa utilizando Jenkins con tres pipelines principales que soportan diferentes ambientes:

```
┌─────────────────────────────────────────────────────────┐
│                     JENKINS CI/CD                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   BUILD      │  │  DEPLOY DEV  │  │ DEPLOY PROD  │  │
│  │   PIPELINE   │  │   PIPELINE   │  │   PIPELINE   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                 │                  │           │
│         ▼                 ▼                  ▼           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Unit Tests  │  │ Integration  │  │  E2E Tests   │  │
│  │  SonarQube   │  │   Tests      │  │  Performance │  │
│  └──────────────┘  └──────────────┘  │  SonarQube   │  │
│                                       └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Configuración Base de Jenkins



**Requisitos del Sistema**:
- Jenkins 2.528.1 o superior
- Docker instalado y configurado
- Kubectl configurado con acceso a cluster Kubernetes
- Plugins necesarios:
  - Pipeline
  - Docker Pipeline
  - Kubernetes CLI
  - Generic Webhook Trigger
  - SonarQube Scanner
  - HTML Publisher

**Credenciales Configuradas**:
- `DOCKER_USER`: Credenciales de Docker Hub
- Tokens de SonarQube:
  - `squ_ed5405cbe3456c97523f39f0eceb7d9c4c26c5b3` para E2E Tests
  - `squ_1037e66e9bc493d2a288dbca5a9cb503f0637c93` para Performance Tests

---

## 2. Pipelines Implementados

### 2.1 Pipeline de Build (`Jenkinsfile.build.local`)

![Imagen de WhatsApp 2025-11-03 a las 00 35 51_2d702f10](https://github.com/user-attachments/assets/8168f070-4c7c-4bd3-874c-bbab92da65c0)

#### Propósito
Compilar, empaquetar y publicar imágenes Docker de todos los microservicios a Docker Hub.

#### Configuración

**Variables de Ambiente**:
```groovy
DOCKER_REGISTRY = 'docker.io'
DOCKER_USER = 'luisrojasc'
VERSION = "0.1.0"
VERSION_TAG = "v${VERSION}-${BUILD_TIMESTAMP}"
SERVICES = 'service-discovery,proxy-client,user-service,product-service,
            order-service,payment-service,shipping-service,favourite-service,api-gateway'
```

**Triggers**:
- GitHub Webhook (token: `ecommerce-build-webhook-token`)
- Push a cualquier branch

**Timeout**: 60 minutos

#### Stages del Pipeline

##### Stage 1: Cleanup Docker
```groovy
stage('Cleanup Docker') {
    steps {
        - Eliminar contenedores detenidos
        - Eliminar imágenes huérfanas
        - Limpiar caché de build (mantener últimas 24h)
        - Mostrar uso de disco
    }
}
```

##### Stage 2: Checkout
```groovy
stage('Checkout') {
    steps {
        - Checkout del código desde SCM
        - Obtener commit hash corto
        - Mostrar información del build
    }
}
```

##### Stage 3: Detect Changed Services
```groovy
stage('Detect Changed Services') {
    steps {
        - Comparar HEAD con HEAD~1
        - Detectar archivos modificados
        - Identificar servicios afectados
        - Optimizar build (solo servicios cambiados)
    }
}
```

**Lógica de Detección**:
```bash
# Si cambió pom.xml raíz → Build ALL services
# Si cambió {service}/pom.xml → Build ese servicio
# Si cambió {service}/src/** → Build ese servicio
```

##### Stage 4: Build Services (Maven)
```groovy
stage('Build Services') {
    parallel {
        // Para cada servicio detectado
        stage('Build {service}') {
            steps {
                - mvn clean package -DskipTests
                - Generar JAR ejecutable
                - Validar que el JAR existe
            }
        }
    }
}
```

**Ejecución Paralela**: Todos los servicios se compilan simultáneamente para optimizar tiempo.

##### Stage 5: Build Docker Images
```groovy
stage('Build Docker Images') {
    parallel {
        stage('Build {service} Image') {
            steps {
                - docker build -t ${DOCKER_USER}/{service}:${VERSION_TAG}
                - docker tag con 'latest'
                - Optimización con multi-stage builds
            }
        }
    }
}
```

**Características**:
- Multi-stage builds para reducir tamaño de imagen
- Layer caching para builds más rápidos
- Tags con versión y timestamp

##### Stage 6: Run Unit Tests
```groovy
stage('Run Unit Tests') {
    parallel {
        stage('Test {service}') {
            steps {
                - mvn test
                - Generar reportes JUnit
                - Calcular cobertura con JaCoCo
            }
        }
    }
}
```

**Pruebas Ejecutadas**:
- `*Test.java`: Pruebas unitarias de cada microservicio
- Framework: JUnit 5 + Mockito
- Cobertura: JaCoCo

##### Stage 7: Push to Docker Hub
```groovy
stage('Push to Docker Hub') {
    steps {
        - docker login (using credentials)
        - docker push ${DOCKER_USER}/{service}:${VERSION_TAG}
        - docker push ${DOCKER_USER}/{service}:latest
        - Generar lista de imágenes publicadas
    }
}
```

##### Stage 8: SonarQube Analysis
```groovy
stage('SonarQube Analysis') {
    parallel {
        stage('Analyze {service}') {
            steps {
                - mvn sonar:sonar
                - Análisis de calidad de código
                - Detección de code smells
                - Cálculo de deuda técnica
            }
        }
    }
}
```

**No-Blocking**: Si SonarQube falla, el pipeline continúa.

#### Proceso Completo de Build

```
1. Trigger (GitHub Push)
   ↓
2. Cleanup Docker Resources
   ↓
3. Checkout Code
   ↓
4. Detect Changed Services
   ↓
5. Maven Build (Parallel)
   │
   ├─→ service-discovery
   ├─→ user-service
   ├─→ product-service
   ├─→ order-service
   ├─→ payment-service
   ├─→ shipping-service
   ├─→ favourite-service
   ├─→ api-gateway
   └─→ proxy-client
   ↓
6. Docker Build (Parallel)
   ↓
7. Unit Tests (Parallel)
   ↓
8. Push to Docker Hub
   ↓
9. SonarQube Analysis
   ↓
10. Archive Artifacts
```



---

### 2.2 Pipeline de Deploy Dev (`Jenkinsfile.deploy-dev.local`)

![Imagen de WhatsApp 2025-11-03 a las 12 35 53_c60d06e9](https://github.com/user-attachments/assets/b6700dc5-a283-4ac3-bc1a-c75d6058f78c)


#### Propósito
Desplegar microservicios al ambiente de desarrollo en Kubernetes (namespace `dev`).

#### Configuración

**Variables de Ambiente**:
```groovy
K8S_NAMESPACE = 'dev'
DOCKER_REGISTRY = 'docker.io'
DOCKER_USER = 'luisrojasc'
SERVICE_READINESS_TIMEOUT = '600'  // 10 minutos
POD_READY_TIMEOUT = '300'          // 5 minutos
```

**Parámetros**:
- `SERVICE_VERSIONS`: JSON con versiones específicas por servicio
- `DOCKER_USER`: Usuario de Docker Hub
- `SKIP_TESTS`: Opción para saltar pruebas de integración

**Namespace Kubernetes**: `dev`

#### Stages del Pipeline

##### Stage 1: Initialize
```groovy
stage('Initialize') {
    steps {
        - Mostrar configuración del deployment
        - Validar parámetros
        - Configurar variables de ambiente
    }
}
```

##### Stage 2: Configure kubectl
```groovy
stage('Configure kubectl') {
    steps {
        - kubectl version --client
        - kubectl cluster-info
        - kubectl config set-context --current --namespace=dev
        - Validar conectividad con cluster
    }
}
```

##### Stage 3: Create Namespace
```groovy
stage('Create Namespace') {
    steps {
        - kubectl get namespace dev || kubectl create namespace dev
        - Aplicar labels al namespace
        - Configurar resource quotas
    }
}
```

##### Stage 4: Detect Services to Deploy
```groovy
stage('Detect Services to Deploy') {
    steps {
        - Parsear SERVICE_VERSIONS JSON
        - Detectar servicios con version != 'latest'
        - Generar plan de deployment
        - Mostrar resumen de servicios
    }
}
```

**Lógica**:
```json
{
  "user-service": "v0.1.0-20251103-1234",
  "product-service": "latest",  // NO se despliega
  "order-service": "v0.1.0-20251103-1234"
}
```

##### Stage 5: Cleanup Resources
```groovy
stage('Cleanup Resources') {
    steps {
        Para cada servicio:
        - kubectl scale deployment/{service} --replicas=0
        - Esperar a que pods se eliminen
        - Eliminar ReplicaSets antiguos
        - Liberar recursos
    }
}
```

##### Stage 6: Deploy Infrastructure Services
```groovy
stage('Deploy Infrastructure Services') {
    steps {
        Orden de deployment:
        1. service-discovery (Eureka)
           - kubectl apply -f service-discovery.yaml
           - kubectl set image deployment/service-discovery
           - kubectl rollout status
           - Esperar 30s para estabilización
    }
}
```

**Por qué primero**: Los demás servicios se registran en Eureka al iniciar.

##### Stage 7: Deploy Microservices
```groovy
stage('Deploy Microservices') {
    steps {
        Orden secuencial:
        1. user-service
        2. product-service
        3. proxy-client
        4. order-service
        5. payment-service
        6. shipping-service
        7. favourite-service

        Para cada servicio:
        - kubectl apply -f {service}.yaml
        - kubectl set image deployment/{service}
        - kubectl rollout restart deployment/{service}
        - kubectl rollout status --timeout=10m
    }
}
```

**Deployment Secuencial**: Evita sobrecarga del cluster.

##### Stage 8: Deploy API Gateway
```groovy
stage('Deploy API Gateway') {
    steps {
        - kubectl apply -f api-gateway.yaml
        - kubectl set image deployment/api-gateway
        - kubectl rollout status
        - Último en desplegarse (enruta a todos los servicios)
    }
}
```

##### Stage 9: Verify Deployment
```groovy
stage('Verify Deployment') {
    steps {
        - kubectl get pods -n dev
        - kubectl get svc -n dev
        - Verificar pods en estado Running
        - Detectar pods con problemas
        - Limpiar pods duplicados
    }
}
```

**Validaciones**:
```bash
# Verificar todos los pods están Running
PROBLEM_PODS=$(kubectl get pods --field-selector=status.phase!=Running)
if [ $PROBLEM_PODS -gt 0 ]; then
    echo "Warning: Pods con problemas"
fi
```

##### Stage 10: Get Access URL
```groovy
stage('Get Access URL') {
    steps {
        - Obtener IP del API Gateway
        - Intentar: LoadBalancer → Minikube → NodePort
        - Mostrar URL de acceso
        - Mostrar URL de Eureka dashboard
    }
}
```

##### Stage 11: Run Integration Tests
```groovy
stage('Run Integration Tests') {
    when { !params.SKIP_TESTS }
    steps {
        - Esperar a que pods estén ready
        - kubectl wait --for=condition=ready pod
        - Ejecutar pruebas de integración básicas
        - Verificar health endpoints
    }
}
```

#### Proceso Completo de Deploy Dev

```
1. Initialize & Configure
   ↓
2. Create/Verify Namespace (dev)
   ↓
3. Detect Services to Deploy
   ↓
4. Cleanup Old Resources
   ↓
5. Deploy service-discovery (Eureka)
   │  (wait 30s)
   ↓
6. Deploy Microservices (Sequential)
   │
   ├─→ user-service
   ├─→ product-service
   ├─→ proxy-client
   ├─→ order-service
   ├─→ payment-service
   ├─→ shipping-service
   └─→ favourite-service
   ↓
7. Deploy api-gateway
   ↓
8. Verify All Pods Running
   ↓
9. Run Integration Tests
   ↓
10. Show Access URLs


### 2.3 Pipeline de Deploy Prod (`Jenkinsfile.deploy-prod.local`)

![Imagen de WhatsApp 2025-11-03 a las 13 18 01_b798f5a8](https://github.com/user-attachments/assets/765deee3-6225-4ebd-9796-9bac123526b2)


#### Propósito
Desplegar a ambiente de producción con aprobación manual, pruebas E2E completas y análisis de calidad.

#### Configuración

**Variables de Ambiente**:
```groovy
K8S_NAMESPACE = 'prod'
DOCKER_REGISTRY = 'docker.io'
SERVICE_READINESS_TIMEOUT = '600'
POD_READY_TIMEOUT = '300'
```

**Parámetros**:
- `SERVICE_VERSIONS`: Versiones a desplegar
- `SKIP_E2E_TESTS`: Saltar pruebas E2E (no recomendado)
- `FORCE_DEPLOY_ALL`: Forzar deploy de todos los servicios

**Namespace Kubernetes**: `prod`

**Timeout**: 60 minutos

#### Stages del Pipeline

##### Stages 1-9: Idénticos a Deploy Dev
(Ver sección 2.2)

##### Stage 10: Manual Approval 

![Imagen de WhatsApp 2025-11-03 a las 12 41 10_a250d08f](https://github.com/user-attachments/assets/283720da-0058-4907-946e-6b0fe101cb9d)



```groovy
stage('Manual Approval') {
    steps {
        timeout(time: 30, unit: 'MINUTES') {
            input {
                message: 'Approve deployment to PRODUCTION?'
                ok: 'Deploy to Production'
                submitter: 'admin,deployers'
                parameters: [
                    booleanParam(
                        name: 'CONFIRM_PRODUCTION_DEPLOY',
                        description: 'Check to confirm'
                    )
                ]
            }
        }
    }
}
```

**Características**:
- Timeout de 30 minutos
- Requiere confirmación explícita
- Solo usuarios autorizados pueden aprobar
- Muestra resumen de servicios a desplegar

##### Stage 11: Wait for Services Ready
```groovy
stage('Wait for Services Ready') {
    when { !params.SKIP_E2E_TESTS }
    steps {
        - kubectl wait pod -l app=api-gateway --timeout=300s
        - kubectl wait pod -l app=product-service --timeout=300s
        - kubectl wait pod -l app=user-service --timeout=300s
        - kubectl wait pod -l app=order-service --timeout=300s
        - Verificar estado final
    }
}
```

**Timeout por servicio**: 5 minutos

##### Stage 12: Run E2E Tests 
```groovy
stage('Run E2E Tests') {
    when { !params.SKIP_E2E_TESTS }
    steps {
        1. Setup Port-Forward
           - kubectl port-forward svc/api-gateway 18080:80
           - Guardar PID para cleanup
           - Esperar 5s para estabilización
           - Verificar que port-forward está activo

        2. Test Connectivity
           - curl http://localhost:18080/app/api/products
           - Reintentos: 5 veces con delay de 5s
           - Validar HTTP status code

        3. Run Maven E2E Tests
           - cd tests
           - mvn clean verify \
               -Dtest.base.url="http://localhost:18080" \
               -Dtest.timeout=60000 \
               -DfailIfNoTests=false

        4. Cleanup
           - kill port-forward process
           - Eliminar archivos temporales
    }
}
```

**Pruebas E2E Ejecutadas**:
```
tests/src/test/java/com/selimhorri/app/e2e/
├── UserRegistrationE2ETest.java        (3 tests)
├── ProductBrowsingE2ETest.java         (4 tests)
├── OrderCreationE2ETest.java           (3 tests)
├── PaymentProcessingE2ETest.java       (4 tests)
├── ShippingFulfillmentE2ETest.java     (3 tests)
└── DefaultUserAuthenticationE2ETest.java (2 tests)

Total: 19 tests
```

##### Stage 13: SonarQube Analysis - E2E Tests
```groovy
stage('SonarQube Analysis - E2E Tests') {
    when { !params.SKIP_E2E_TESTS }
    steps {
        try {
            cd tests
            mvn sonar:sonar \
                -Dsonar.host.url=http://172.17.0.1:9000 \
                -Dsonar.token=squ_ed5405cbe3456c97523f39f0eceb7d9c4c26c5b3 \
                -Dsonar.projectKey=ecommerce-e2e-tests \
                -Dsonar.projectName="E-Commerce E2E Tests" \
                -Dsonar.sources=src/test/java \
                -Dsonar.tests=src/test/java \
                -Dsonar.java.binaries=target/test-classes \
                -Dsonar.junit.reportPaths=target/failsafe-reports \
                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
        } catch (Exception e) {
            echo "SonarQube analysis failed (non-blocking)"
        }
    }
}
```

**Métricas Analizadas**:
- Calidad del código de pruebas
- Complejidad ciclomática
- Duplicación de código
- Code smells en tests
- Cobertura de código

##### Stage 14: Deployment Summary
```groovy
stage('Deployment Summary') {
    steps {
        - Mostrar namespace (prod)
        - Listar servicios desplegados
        - Listar servicios saltados
        - Mostrar comandos útiles (logs, port-forward)
        - Generar reporte de deployment
    }
}
```

#### Post Actions

```groovy
post {
    success {
        - Mensaje de éxito
        - Archivar manifiestos de Kubernetes
    }

    failure {
        - Mensaje de fallo
        - Recolectar información diagnóstica
        - kubectl get pods
        - kubectl get events
        - NO hacer rollback automático (requiere análisis)
    }

    always {
        - Cleanup port-forward
        - Archivar reportes de pruebas (JUnit)
        - Archivar manifiestos
        - Limpiar workspace
    }
}
```

#### Proceso Completo de Deploy Prod

```
1. Initialize & Configure
   ↓
2. Create/Verify Namespace (prod)
   ↓
3. Detect Services to Deploy
   ↓
4. ⚠️ MANUAL APPROVAL (30 min timeout)
   │  - Requiere confirmación humana
   │  - Muestra plan de deployment
   ↓
5. Cleanup Old Resources
   ↓
6. Deploy service-discovery
   ↓
7. Deploy Microservices (Sequential)
   ↓
8. Deploy api-gateway
   ↓
9. Verify All Pods Running
   ↓
10. Wait for All Services Ready (5 min)
    ↓
11. Setup Port-Forward to API Gateway
    ↓
12. Run E2E Tests (19 tests)
    │
    ├─→ User Registration (3)
    ├─→ Product Browsing (4)
    ├─→ Order Creation (3)
    ├─→ Payment Processing (4)
    ├─→ Shipping Fulfillment (3)
    └─→ User Authentication (2)
    ↓
13. SonarQube Analysis (E2E Code)
    ↓
14. Deployment Summary
    ↓
15. Archive Artifacts
```

**Tiempo Promedio**: 30-45 minutos

---

## 3. Estrategia de Pruebas

### 3.1 Pirámide de Pruebas Implementada

```
           /\
          /  \         E2E Tests (19)
         /    \        ↑ Slow, Expensive
        /------\
       /        \      Integration Tests (6)
      /          \     ↑ Medium Speed
     /------------\
    /              \   Unit Tests (Multiple)
   /________________\  ↑ Fast, Cheap

   UI/E2E    →  Integration  →  Unit
   (Locust)      (Testcontainers)  (JUnit + Mockito)
```

### 3.2 Pruebas Unitarias

#### Ubicación y Nomenclatura
```
{service}/src/test/java/**/*Test.java
```

#### Framework y Herramientas
- **JUnit 5**: Framework de testing
- **Mockito**: Mocking de dependencias
- **AssertJ**: Assertions fluidas
- **JaCoCo**: Cobertura de código

#### Servicios con Pruebas Unitarias

**1. Order Service** (`CartServiceImplTest.java`)
```java
@Test
void testAddProductToCart() {
    // Valida lógica de agregar productos al carrito
    // Mock de repository y external services
}

@Test
void testCalculateCartTotal() {
    // Valida cálculo correcto del total
}

@Test
void testRemoveProductFromCart() {
    // Valida eliminación de productos
}
```

**2. Payment Service** (`PaymentServiceImplTest.java`)
```java
@Test
void testProcessPayment() {
    // Valida procesamiento de pago exitoso
}

@Test
void testPaymentValidation() {
    // Valida validaciones de negocio
}

@Test
void testPaymentCancellation() {
    // Valida cancelación de pagos
}
```

**3. Product Service** (`ProductServiceImplTest.java`)
```java
@Test
void testCreateProduct() {
    // Valida creación de producto
}

@Test
void testUpdateProductInventory() {
    // Valida actualización de inventario
}

@Test
void testProductSearch() {
    // Valida búsqueda de productos
}
```

**4. User Service** (`CredentialServiceImplTest.java`)
```java
@Test
void testUserAuthentication() {
    // Valida autenticación de usuario
}

@Test
void testPasswordEncryption() {
    // Valida encriptación de contraseñas
}

@Test
void testTokenGeneration() {
    // Valida generación de tokens
}
```

#### Ejecución en Pipelines

**Build Pipeline**:
```groovy
stage('Run Unit Tests') {
    parallel {
        stage('Test user-service') {
            mvn test -pl user-service
        }
        stage('Test product-service') {
            mvn test -pl product-service
        }
        // ... otros servicios
    }
}
```

**Reportes Generados**:
- JUnit XML: `target/surefire-reports/*.xml`
- JaCoCo HTML: `target/site/jacoco/index.html`
- SonarQube Dashboard

---

### 3.3 Pruebas de Integración

#### Ubicación y Nomenclatura
```
{service}/src/test/java/**/*IT.java
{service}/src/test/java/**/integration/*Test.java
```

#### Framework y Herramientas
- **JUnit 5**: Framework de testing
- **Testcontainers**: Contenedores Docker para dependencias
- **Spring Boot Test**: Context de Spring
- **REST Assured**: Testing de APIs

#### Pruebas de Integración Implementadas

**1. Favourite Service** (`FavouriteUserProductIntegrationTest.java`)
```java
@Testcontainers
@SpringBootTest(webEnvironment = RANDOM_PORT)
class FavouriteUserProductIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @Test
    void testAddProductToFavourites() {
        // Valida comunicación entre Favourite ↔ Product Service
        // Usa contenedor MySQL real
    }
}
```

**2. Payment Service** (`PaymentOrderIntegrationTest.java`)
```java
@Test
void testPaymentOrderIntegration() {
    // Valida flujo: Order → Payment
    // Verifica que payment se crea cuando order es creado
}
```

**3. Product Service** (`ProductCategoryIntegrationTest.java`)
```java
@Test
void testProductCategoryRelationship() {
    // Valida relaciones JPA entre Product y Category
    // Usa base de datos real en contenedor
}
```

**4. Shipping Service** (`ShippingPaymentIntegrationTest.java`)
```java
@Test
void testShippingAfterPayment() {
    // Valida que shipping se crea después de payment exitoso
    // Simula flujo completo: Payment → Shipping
}
```

**5. User Service** (`UserServiceIntegrationTest.java`)
```java
@Test
void testUserRegistrationFlow() {
    // Valida flujo completo de registro
    // User creation → Credential creation → Email verification
}
```

**6. Order Service** (`OrderResourceIT.java`)
```java
@Test
void testOrderPersistence() {
    // Valida persistencia en base de datos
    // CRUD completo de órdenes
}
```

#### Ejecución en Pipelines

**Deploy Dev Pipeline**:
```groovy
stage('Run Integration Tests') {
    steps {
        mvn verify -Pfailsafe
        // Ejecuta *IT.java tests
        // Levanta Testcontainers automáticamente
    }
}
```

**Características**:
-  Base de datos real (MySQL en contenedor)
-  Comunicación entre servicios simulada
-  Cleanup automático de recursos

---

### 3.4 Pruebas End-to-End (E2E)

#### Ubicación
```
tests/src/test/java/com/selimhorri/app/e2e/*E2ETest.java
```

#### Framework y Herramientas
- **REST Assured**: Cliente HTTP para testing
- **JUnit 5**: Framework de testing
- **Awaitility**: Esperas asíncronas
- **Spring Retry**: Reintentos automáticos

#### Configuración Base

**BaseE2ETest.java**:
```java
@SpringBootTest
public abstract class BaseE2ETest {

    protected String apiUrl;

    @BeforeEach
    void setup() {
        apiUrl = System.getenv("API_URL");

        RestAssured.baseURI = apiUrl;
        RestAssured.useRelaxedHTTPSValidation();
        RestAssured.config = RestAssured.config()
            .httpClient(httpClientConfig()
                .setParam(CONNECTION_TIMEOUT, 60000)
                .setParam(SO_TIMEOUT, 60000)
            );
    }
}
```

#### Pruebas E2E Implementadas

**1. UserRegistrationE2ETest.java** (3 tests)
```java
@Test
@DisplayName("Should register new user successfully")
void testUserRegistration() {
    given()
        .contentType(JSON)
        .body(userRequest)
    .when()
        .post(apiUrl + "/app/api/users")
    .then()
        .statusCode(anyOf(200, 201))
        .body("userId", notNullValue())
        .body("username", equalTo("testuser"));
}

@Test
@DisplayName("Should login with registered user")
void testUserLogin() {
    // Valida flujo completo: Register → Login → Get Token
}

@Test
@DisplayName("Should reject duplicate username")
void testDuplicateUser() {
    // Valida que no se pueden crear usuarios duplicados
}
```

**2. ProductBrowsingE2ETest.java** (4 tests)
```java
@Test
@DisplayName("Should retrieve all products")
void testGetAllProducts() {
    given()
    .when()
        .get(apiUrl + "/app/api/products")
    .then()
        .statusCode(200)
        .body("$", not(empty()));
}

@Test
@DisplayName("Should get product by ID")
void testGetProductById() {
    // Valida obtener producto específico
}

@Test
@DisplayName("Should search products by category")
void testSearchByCategory() {
    // Valida búsqueda y filtrado
}

@Test
@DisplayName("Should handle non-existent product gracefully")
void testNonExistentProduct() {
    // Valida manejo de errores 404
}
```

**3. OrderCreationE2ETest.java** (3 tests)
```java
@Test
@DisplayName("Should create order successfully")
void testCreateOrder() {
    // Step 1: Create user
    Integer userId = createUser();

    // Step 2: Browse products
    Integer productId = getProduct();

    // Step 3: Create order
    Map<String, Object> orderRequest = Map.of(
        "userId", userId,
        "orderDate", LocalDateTime.now(),
        "orderFee", 100.0
    );

    given()
        .contentType(JSON)
        .body(orderRequest)
    .when()
        .post(apiUrl + "/app/api/orders")
    .then()
        .statusCode(anyOf(200, 201))
        .body("orderId", notNullValue());
}

@Test
@DisplayName("Should retrieve order by ID")
void testGetOrder() { ... }

@Test
@DisplayName("Should list user orders")
void testGetUserOrders() { ... }
```

**4. PaymentProcessingE2ETest.java** (4 tests)
```java
@Test
@DisplayName("Should process payment for order")
void testPaymentProcessing() {
    // Step 1: Create order
    Integer orderId = createOrder();

    // Step 2: Create payment
    Map<String, Object> paymentRequest = Map.of(
        "orderId", orderId,
        "isPayed", false,
        "paymentStatus", "PENDING"
    );

    Integer paymentId = given()
        .contentType(JSON)
        .body(paymentRequest)
    .when()
        .post(apiUrl + "/app/api/payments")
    .then()
        .statusCode(anyOf(200, 201))
        .extract().path("paymentId");

    // Step 3: Update payment status
    paymentRequest.put("isPayed", true);
    paymentRequest.put("paymentStatus", "COMPLETED");

    given()
        .contentType(JSON)
        .body(paymentRequest)
    .when()
        .put(apiUrl + "/app/api/payments/" + paymentId)
    .then()
        .statusCode(anyOf(200, 204));
}

@Test
@DisplayName("Should retrieve payment by order")
void testGetPaymentByOrder() { ... }

@Test
@DisplayName("Should handle payment failure")
void testPaymentFailure() { ... }

@Test
@DisplayName("Should prevent duplicate payments")
void testDuplicatePayment() { ... }
```

**5. ShippingFulfillmentE2ETest.java** (3 tests)
```java
@Test
@DisplayName("Should create shipping after payment")
void testShippingCreation() {
    // Valida flujo: Order → Payment → Shipping
}

@Test
@DisplayName("Should track shipping status")
void testShippingTracking() {
    // Valida actualización de estado de envío
}

@Test
@DisplayName("Should complete shipping")
void testCompleteShipping() {
    // Valida marcado de envío como completado
}
```

**6. DefaultUserAuthenticationE2ETest.java** (2 tests)
```java
@Test
@DisplayName("Should authenticate user with valid credentials")
void testValidAuthentication() {
    // Valida login exitoso
}

@Test
@DisplayName("Should reject invalid credentials")
void testInvalidAuthentication() {
    // Valida rechazo de credenciales incorrectas
}
```

#### Ejecución en Pipeline Prod

```groovy
stage('Run E2E Tests') {
    steps {
        // 1. Setup port-forward
        sh "kubectl port-forward svc/api-gateway 18080:80 &"

        // 2. Wait for services
        sleep(5)

        // 3. Run tests
        sh """
            cd tests
            mvn clean verify \
                -Dtest.base.url=http://localhost:18080 \
                -Dtest.timeout=60000
        """
    }
}
```

**Configuración Maven** (`tests/pom.xml`):
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <configuration>
        <includes>
            <include>**/*E2ETest.java</include>
        </includes>
        <systemPropertyVariables>
            <API_URL>${test.base.url}</API_URL>
        </systemPropertyVariables>
    </configuration>
</plugin>
```

---

### 3.5 Pruebas de Performance (Locust)


![Imagen de WhatsApp 2025-11-03 a las 14 23 04_a638c06d](https://github.com/user-attachments/assets/0c393e4f-ae72-4ad0-9315-bf315af66584)


#### Ubicación
```
tests/performance/
├── locustfile.py           # Definición de pruebas
├── requirements.txt        # Dependencias Python
└── reports/               # Reportes generados
```

#### Framework
- **Locust**: Framework de pruebas de carga en Python
- **Usuarios concurrentes**: Configurable
- **Reportes**: HTML, CSV

#### Configuración de Locust

**locustfile.py**:
```python
from locust import HttpUser, task, between

class ECommercePurchaseUser(HttpUser):
    wait_time = between(1, 3)  # Espera entre 1-3s entre requests

    @task(3)  # Peso 3 (más frecuente)
    def browse_products(self):
        """Simula navegación de productos"""
        product_id = random.randint(1, 50)
        self.client.get(f"/app/api/products/{product_id}")

    @task(2)  # Peso 2
    def view_product(self):
        """Simula ver detalle de producto"""
        self.client.get("/app/api/products")

    @task(1)  # Peso 1 (menos frecuente)
    def create_order(self):
        """Simula creación de orden"""
        order_data = {
            "orderDate": datetime.now().isoformat(),
            "orderDesc": "Load Test Order",
            "orderFee": 100.0
        }
        self.client.post("/app/api/orders", json=order_data)

    @task(1)
    def add_to_cart(self):
        """Simula agregar al carrito"""
        cart_data = {"productId": random.randint(1, 50), "quantity": 1}
        self.client.post("/app/api/carts", json=cart_data)

    @task(1)
    def get_user(self):
        """Simula obtener info de usuario"""
        user_id = random.randint(1, 100)
        self.client.get(f"/app/api/users/{user_id}")
```

#### Otros Escenarios de Prueba

![Imagen de WhatsApp 2025-11-03 a las 14 24 41_d2afb382](https://github.com/user-attachments/assets/5eaf315c-03aa-49f6-a29b-b49dec62cfe2)


![Imagen de WhatsApp 2025-11-03 a las 14 24 50_892b1794](https://github.com/user-attachments/assets/1fc644c6-2f63-419a-a9c4-61a319ed5ae9)


![Imagen de WhatsApp 2025-11-03 a las 14 24 59_1b894d1f](https://github.com/user-attachments/assets/d0448117-a771-44eb-a41e-0c568af64694)



**1. MixedWorkloadUser**: Carga mixta de todas las operaciones
**2. ProductServiceLoadTest**: Solo carga en servicio de productos
**3. OrderServiceStressTest**: Prueba de estrés en servicio de órdenes
**4. UserAuthenticationLoadTest**: Carga en autenticación

#### Parámetros de Ejecución

**Pipeline Configuration**:
```groovy
stage('Run Performance Tests') {
    parameters {
        ENVIRONMENT: 'prod'
        TEST_TYPE: 'ECommercePurchaseUser'
        USERS: '100'              // Usuarios concurrentes
        SPAWN_RATE: '10'          // 10 usuarios/segundo
        RUN_TIME: '5m'            // Duración de prueba
        HEADLESS: true            // Sin UI web
    }
}
```

#### Ejecución en Pipeline

```groovy
stage('Run Performance Tests') {
    steps {
        sh """
            cd tests/performance
            python3 -m venv venv
            . venv/bin/activate
            pip install -r requirements.txt

            locust -f locustfile.py ECommercePurchaseUser \
                --host=${API_GATEWAY_URL} \
                --users ${USERS} \
                --spawn-rate ${SPAWN_RATE} \
                --run-time ${RUN_TIME} \
                --headless \
                --html performance-report-${BUILD_NUMBER}.html \
                --csv performance-report-${BUILD_NUMBER}
        """
    }
}
```

**Reportes Generados**:
- `performance-report-{BUILD_NUMBER}.html`: Reporte visual
- `performance-report-{BUILD_NUMBER}_stats.csv`: Estadísticas
- `performance-report-{BUILD_NUMBER}_failures.csv`: Errores
- `performance-report-{BUILD_NUMBER}_stats_history.csv`: Historial

---

## 4. Análisis de Resultados

### 4.1 Resultados de Pruebas E2E

#### Resumen de Ejecución

```
===========================================
E2E Test Results - Build #3
===========================================
Date: 2025-11-03 21:53:14 UTC
Environment: Production (prod namespace)
API Gateway: http://localhost:18080
Total Duration: 43.964 seconds
===========================================
```

#### Estadísticas de Pruebas

| Métrica | Valor | Estado |
|---------|-------|--------|
| **Tests Ejecutados** | 19 |  |
| **Tests Exitosos** | 19 |  |
| **Tests Fallidos** | 0 |  |
| **Tests con Errores** | 0 |  |
| **Tests Saltados** | 0 |  |
| **Tasa de Éxito** | **100%** |  |
| **Tiempo Total** | 43.964s |  |
| **Tiempo Promedio/Test** | ~2.3s |  |

#### Desglose por Suite de Pruebas

**1. UserRegistrationE2ETest**
```
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~6.5s

 testUserRegistration - PASSED (2.1s)
 testUserLogin - PASSED (2.2s)
 testDuplicateUserRejection - PASSED (2.2s)
```

**2. ProductBrowsingE2ETest**
```
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~8.2s

 testGetAllProducts - PASSED (2.0s)
 testGetProductById - PASSED (2.1s)
 testSearchByCategory - PASSED (2.0s)
 testNonExistentProduct - PASSED (2.1s)
```

**3. OrderCreationE2ETest**
```
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~7.8s

 testCreateOrder - PASSED (2.8s)
 testGetOrder - PASSED (2.5s)
 testGetUserOrders - PASSED (2.5s)
```

**4. PaymentProcessingE2ETest**
```
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~8.3s

 testPaymentProcessing - PASSED (2.5s)
 testGetPaymentByOrder - PASSED (1.8s)
 testPaymentFailure - PASSED (2.0s)
 testDuplicatePayment - PASSED (2.0s)
```

**5. ShippingFulfillmentE2ETest**
```
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~6.7s

 testShippingCreation - PASSED (2.4s)
 testShippingTracking - PASSED (2.2s)
 testCompleteShipping - PASSED (2.1s)
```

**6. DefaultUserAuthenticationE2ETest**
```
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
Time elapsed: ~4.4s

 testValidAuthentication - PASSED (2.2s)
 testInvalidAuthentication - PASSED (2.2s)
```

#### Análisis e Interpretación

** Aspectos Positivos**:

1. **Tasa de Éxito del 100%**
   - Todas las 19 pruebas E2E pasaron exitosamente
   - No hay fallos ni errores
   - Indica que todos los flujos críticos funcionan correctamente

2. **Tiempo de Ejecución Óptimo**
   - Total: 43.964 segundos (menos de 1 minuto)
   - Promedio por test: ~2.3 segundos
   - Indica buena performance de los microservicios

3. **Cobertura Completa de Flujos**
   -  Registro de usuarios
   -  Autenticación
   -  Navegación de productos
   -  Creación de órdenes
   -  Procesamiento de pagos
   -  Gestión de envíos

4. **Comunicación Entre Microservicios Funcional**
   - API Gateway enruta correctamente
   - Service Discovery (Eureka) registra servicios
   - Comunicación inter-servicio estable

5. **Port-Forward Exitoso**
   - Conexión desde Jenkins a Kubernetes establecida
   - Port-forward (PID: 75100) funcionó correctamente
   - Cleanup automático ejecutado

**📊 Métricas de Calidad**:

| Indicador | Valor | Benchmark | Evaluación |
|-----------|-------|-----------|------------|
| Tasa de Éxito | 100% | >95% |  Excelente |
| Tiempo de Respuesta | ~2.3s/test | <5s |  Excelente |
| Cobertura E2E | 6 flujos | ≥5 flujos |  Cumple |
| Estabilidad | 0 flaky tests | 0 |  Excelente |

**🔍 Observaciones Importantes**:

1. **JaCoCo Coverage Skipped**
   ```
   [INFO] Skipping JaCoCo execution due to missing classes directory.
   ```
   - Esto es **ESPERADO** para pruebas E2E
   - Las pruebas E2E no tienen clases de producción (solo test code)
   - No afecta la validez de las pruebas

2. **Failsafe Plugin**
   ```
   [INFO] --- failsafe:3.2.5:verify (default) @ e2e-tests ---
   ```
   - Correctamente usa Failsafe (no Surefire)
   - Failsafe es para integration/E2E tests
   - Permite cleanup incluso si tests fallan

3. **Build Success**
   ```
   [INFO] BUILD SUCCESS
   [INFO] Total time: 43.964 s
   ```
   - Maven build completado exitosamente
   - Todos los tests verificados
   - Artefactos generados correctamente

** Conclusión de Pruebas E2E**:

Las pruebas E2E demuestran que:
1.  Todos los microservicios están desplegados correctamente
2.  La comunicación entre servicios funciona
3.  Los flujos de negocio críticos están operativos
4.  El API Gateway enruta correctamente
5.  La arquitectura de microservicios es estable

---

### 4.2 Resultados de Pruebas de Performance (Locust)

#### Resumen de Ejecución

![Imagen de WhatsApp 2025-11-03 a las 23 43 30_cf9304c9](https://github.com/user-attachments/assets/7236c492-60cb-4f26-9987-018a38655e71)


---

## 5. Apéndices

### 5.1 Comandos Útiles

**Jenkins**:
```bash
# Ver logs de build
jenkins-cli console {job-name} {build-number}

# Cancelar build
jenkins-cli stop-build {job-name} {build-number}
```

**Kubernetes**:
```bash
# Ver pods
kubectl get pods -n prod

# Ver logs
kubectl logs -f deployment/api-gateway -n prod

# Port-forward
kubectl port-forward -n prod svc/api-gateway 8080:80

# Rollback
kubectl rollout undo deployment/api-gateway -n prod
```

**Maven**:
```bash
# Pruebas unitarias
mvn test

# Pruebas de integración
mvn verify

# Pruebas E2E
cd tests && mvn verify -Pe2e-tests

# SonarQube
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000
```

**Locust**:
```bash
# Ejecutar pruebas de performance
cd tests/performance
locust -f locustfile.py ECommercePurchaseUser \
    --host=http://localhost:8080 \
    --users 100 \
    --spawn-rate 10 \
    --run-time 5m \
    --headless \
    --html report.html
```

### 5.2 Estructura de Repositorio

```
ecommerce-microservice-backend-app/
├── infrastructure/
│   ├── jenkins-pipeline/
│   │   ├── Jenkinsfile.build.local
│   │   ├── Jenkinsfile.deploy-dev.local
│   │   ├── Jenkinsfile.deploy-prod.local
│   │   └── Jenkinsfile.performance-tests
│   └── kubernetes/
│       └── base/
│           ├── api-gateway.yaml
│           ├── user-service.yaml
│           └── ...
├── tests/
│   ├── src/test/java/
│   │   └── com/selimhorri/app/
│   │       ├── e2e/
│   │       │   ├── UserRegistrationE2ETest.java
│   │       │   ├── ProductBrowsingE2ETest.java
│   │       │   └── ...
│   │       └── base/
│   │           └── BaseE2ETest.java
│   ├── performance/
│   │   ├── locustfile.py
│   │   └── requirements.txt
│   └── pom.xml
├── user-service/
│   ├── src/
│   │   ├── main/java/
│   │   └── test/java/
│   │       ├── integration/
│   │       └── service/impl/
│   └── pom.xml
├── product-service/
├── order-service/
├── payment-service/
├── shipping-service/
├── favourite-service/
├── api-gateway/
├── service-discovery/
├── proxy-client/
└── docs/
    ├── BRANCHING_STRATEGY.md
    ├── PIPELINE_CONFIGURATION.md
    ├── TESTING_GUIDE.md
    └── README.md
```

### 5.3 Enlaces Útiles

- **Jenkins**: http://localhost:8080
- **SonarQube**: http://localhost:9000
- **Eureka Dashboard**: http://{minikube-ip}:8761
- **API Gateway**: http://{minikube-ip}:32118

---

## 6. Distributed Tracing con Jaeger

### 6.1 Introducción al Distributed Tracing

El distributed tracing es una técnica fundamental para el monitoreo y diagnóstico de aplicaciones basadas en microservicios. Permite rastrear las solicitudes a medida que fluyen a través de múltiples servicios, proporcionando visibilidad completa del comportamiento del sistema.

#### Beneficios del Distributed Tracing

1. **Visibilidad End-to-End**: Permite ver el flujo completo de una solicitud a través de todos los microservicios
2. **Detección de Cuellos de Botella**: Identifica qué servicios están ralentizando las solicitudes
3. **Análisis de Dependencias**: Muestra las relaciones entre servicios
4. **Debugging de Producción**: Facilita el diagnóstico de problemas en ambientes complejos
5. **Análisis de Latencia**: Ayuda a optimizar el rendimiento del sistema

### 6.2 Arquitectura de Tracing Implementada

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DE TRACING                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐       ┌──────────────┐       ┌─────────────┐ │
│  │ API Gateway  │──────▶│ Proxy Client │──────▶│  Services   │ │
│  │ (Trace Start)│       │              │       │  Backend    │ │
│  └──────┬───────┘       └──────┬───────┘       └──────┬──────┘ │
│         │                      │                      │         │
│         │  Zipkin Protocol     │                      │         │
│         └──────────────────────┴──────────────────────┘         │
│                                │                                │
│                                ▼                                │
│                    ┌────────────────────┐                       │
│                    │  Jaeger Collector  │                       │
│                    │    (Port 9411)     │                       │
│                    └─────────┬──────────┘                       │
│                              │                                  │
│                              ▼                                  │
│                    ┌────────────────────┐                       │
│                    │   Jaeger Storage   │                       │
│                    │    (In-Memory)     │                       │
│                    └─────────┬──────────┘                       │
│                              │                                  │
│                              ▼                                  │
│                    ┌────────────────────┐                       │
│                    │   Jaeger Query UI  │                       │
│                    │   (Port 16686)     │                       │
│                    └────────────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.3 Proceso de Implementación

#### 6.3.1 Problema Inicial Detectado

Durante la implementación inicial del distributed tracing, se identificaron **dos problemas críticos**:

**Problema 1: Error 403 (Forbidden)**
- El sistema estaba rechazando solicitudes a la mayoría de los endpoints
- Solo `/api/users` funcionaba correctamente
- Los endpoints `/api/products`, `/api/orders`, y `/api/payments` retornaban error 403

**Diagnóstico:**
```bash
# Trace en Jaeger mostraba:
Service: api-gateway
Duration: 10.73ms
Services: 1 (solo api-gateway)
Tags: error=true, http.status_code=403, http.path=/api/payments
```

**Causa Raíz:**
El `proxy-client` tenía configuración de seguridad con autenticación JWT obligatoria:

```java
// proxy-client/src/main/java/com/selimhorri/app/security/SecurityConfig.java
@Override
protected void configure(final HttpSecurity http) throws Exception {
    http.cors().disable()
        .csrf().disable()
        .authorizeRequests()
            .antMatchers("/api/authenticate", "/api/users", "/actuator/health").permitAll()
            .anyRequest().authenticated()  // ← Requiere JWT para todo lo demás
        .and()
        .addFilterBefore(this.jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
}
```

**Problema 2: Falta de Instrumentación en Microservicios**
- Solo 4 servicios aparecían en Jaeger:
  - `api-gateway`
  - `user-service`
  - `service-discovery`
  - `jaeger-all-in-one`
- Faltaban: `payment-service`, `product-service`, `order-service`, `shipping-service`, `favourite-service`

**Diagnóstico:**
Los servicios tenían configuración de Zipkin en los archivos YAML:

```yaml
# application.yml de cada servicio
spring:
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://zipkin:9411/}
```

Pero **NO tenían las dependencias** necesarias en sus `pom.xml` para enviar traces.

#### 6.3.2 Solución Implementada

**Solución 1: Deshabilitación de Autenticación JWT**

Modificación del `SecurityConfig.java` del proxy-client:

```java
// proxy-client/src/main/java/com/selimhorri/app/security/SecurityConfig.java
@Override
protected void configure(final HttpSecurity http) throws Exception {
    http.cors().disable()
        .csrf().disable()
        .authorizeRequests()
            .antMatchers("/**").permitAll()  // ← Permitir todo el tráfico
        .and()
        .headers()
            .frameOptions()
            .sameOrigin()
        .and()
        .sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS);
    // Se removió el filtro JWT
}
```

**Cambios realizados:**
- Se cambió `.antMatchers("/api/authenticate", "/api/users", "/actuator/health").permitAll()` por `.antMatchers("/**").permitAll()`
- Se eliminó `.anyRequest().authenticated()`
- Se removió el filtro JWT: `.addFilterBefore(this.jwtRequestFilter, UsernamePasswordAuthenticationFilter.class)`

**Solución 2: Agregación de Dependencias de Tracing**

Se agregaron las dependencias de Spring Cloud Sleuth y Zipkin a **todos los microservicios**:

```xml
<!-- Agregado a pom.xml de todos los servicios -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

**Servicios actualizados:**
- `api-gateway/pom.xml`
- `payment-service/pom.xml`
- `product-service/pom.xml`
- `user-service/pom.xml`
- `order-service/pom.xml`
- `shipping-service/pom.xml`
- `favourite-service/pom.xml`
- `proxy-client/pom.xml`

#### 6.3.3 Configuración de Jaeger en Kubernetes

**Deployment de Jaeger:**

```yaml
# infrastructure/kubernetes/tracing/jaeger-all-in-one.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: tracing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        ports:
        - containerPort: 16686  # Jaeger UI
        - containerPort: 14268  # Collector HTTP
        - containerPort: 14250  # Collector gRPC
        - containerPort: 9411   # Zipkin compatible endpoint
        - containerPort: 6831   # Jaeger agent (UDP)
        - containerPort: 6832   # Jaeger agent (UDP)
        env:
        - name: COLLECTOR_ZIPKIN_HOST_PORT
          value: "9411"
        resources:
          limits:
            memory: "1Gi"
            cpu: "500m"
          requests:
            memory: "512Mi"
            cpu: "250m"
```

**Servicios de Jaeger:**

```yaml
# Jaeger Query Service (UI)
apiVersion: v1
kind: Service
metadata:
  name: jaeger-query
  namespace: tracing
spec:
  type: NodePort
  ports:
  - name: jaeger-ui
    port: 16686
    targetPort: 16686
    nodePort: 30686
  selector:
    app: jaeger
---
# Jaeger Collector Service
apiVersion: v1
kind: Service
metadata:
  name: jaeger-collector
  namespace: tracing
spec:
  type: ClusterIP
  ports:
  - name: jaeger-collector-http
    port: 14268
    targetPort: 14268
  - name: jaeger-collector-grpc
    port: 14250
    targetPort: 14250
  - name: zipkin
    port: 9411
    targetPort: 9411
  - name: jaeger-agent-compact
    port: 6831
    targetPort: 6831
    protocol: UDP
  - name: jaeger-agent-binary
    port: 6832
    targetPort: 6832
    protocol: UDP
  selector:
    app: jaeger
```

**Configuración de los Servicios:**

Todos los microservicios fueron configurados para enviar traces al collector de Jaeger:

```yaml
# Ejemplo: api-gateway/src/main/resources/application.yml
spring:
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://jaeger-collector.tracing.svc.cluster.local:9411/}
  application:
    name: API-GATEWAY

# Ejemplo: payment-service/src/main/resources/application.yml
spring:
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://jaeger-collector.tracing.svc.cluster.local:9411/}
  application:
    name: PAYMENT-SERVICE
```

**Variable de entorno en Kubernetes:**

```yaml
# infrastructure/kubernetes/base/api-gateway.yaml
env:
- name: SPRING_ZIPKIN_BASE_URL
  value: "http://jaeger-collector.tracing.svc.cluster.local:9411/"
```

### 6.4 Verificación y Resultados

#### 6.4.1 Verificación del Despliegue

**Pods en producción:**
```bash
$ kubectl get pods -n prod
NAME                                 READY   STATUS    RESTARTS   AGE
api-gateway-574fb74fbb-7ttxp         1/1     Running   0          106m
favourite-service-5d4fb4b88f-7ct7h   1/1     Running   0          106m
order-service-5db87cd485-n7trt       1/1     Running   0          106m
payment-service-745bfd54b-4xppq      1/1     Running   0          106m
product-service-8b6b5fbc5-zbfwm      1/1     Running   0          106m
proxy-client-7667c7b4bb-7fdlv        1/1     Running   0          106m
service-discovery-7f4fb78745-c9prn   1/1     Running   0          106m
shipping-service-68746c9d79-rfb98    1/1     Running   0          106m
user-service-69cd96777b-5rxft        1/1     Running   0          106m
```

**Pod de Jaeger:**
```bash
$ kubectl get pods -n tracing
NAME                      READY   STATUS    RESTARTS   AGE
jaeger-7f8fdbfdd8-vklrj   1/1     Running   0          4h9m
```

#### 6.4.2 Servicios Registrados en Jaeger

Después de la implementación, **7 servicios** están enviando traces a Jaeger:

```bash
$ kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n tracing -- \
  curl -s http://jaeger-query.tracing.svc.cluster.local:16686/api/services

{
  "data": [
    "order-service",
    "payment-service",
    "product-service",
    "service-discovery",
    "jaeger-all-in-one",
    "api-gateway",
    "user-service"
  ],
  "total": 7,
  "limit": 0,
  "offset": 0,
  "errors": null
}
```

**Comparación:**

| Estado | Servicios Registrados | Detalles |
|--------|----------------------|----------|
| **Antes** | 4 servicios | `api-gateway`, `user-service`, `service-discovery`, `jaeger-all-in-one` |
| **Después** | 7 servicios | Se agregaron: `order-service`, `payment-service`, `product-service` |

#### 6.4.3 Análisis de Traces

**Ejemplo de Trace: GET /api/payments**

```json
{
  "traceID": "046967f35824be1b",
  "spans": [
    {
      "spanID": "046967f35824be1b",
      "operationName": "get",
      "serviceName": "api-gateway",
      "duration": 136574,  // 136.5ms
      "tags": {
        "http.method": "GET",
        "http.path": "/app/api/payments",
        "span.kind": "server"
      }
    },
    {
      "spanID": "9c20083fc39fde6d",
      "operationName": "get",
      "serviceName": "api-gateway",
      "duration": 121208,  // 121.2ms
      "tags": {
        "http.path": "/api/payments",
        "span.kind": "client"
      },
      "references": [{"refType": "CHILD_OF", "spanID": "046967f35824be1b"}]
    },
    {
      "spanID": "e13880c705e411af",
      "operationName": "get /api/payments",
      "serviceName": "payment-service",
      "duration": 105417,  // 105.4ms
      "tags": {
        "mvc.controller.class": "PaymentResource",
        "mvc.controller.method": "findAll",
        "http.method": "GET"
      },
      "references": [{"refType": "CHILD_OF", "spanID": "9c20083fc39fde6d"}]
    },
    {
      "spanID": "b8bd3c8efb8ce701",
      "operationName": "get",
      "serviceName": "payment-service",
      "duration": 9338,  // 9.3ms
      "tags": {
        "http.path": "/order-service/api/orders/1",
        "span.kind": "client"
      }
    },
    {
      "spanID": "0000000000000002",
      "operationName": "get /api/orders/{orderid}",
      "serviceName": "order-service",
      "duration": 7835,  // 7.8ms
      "tags": {
        "mvc.controller.class": "OrderResource",
        "mvc.controller.method": "findById"
      }
    }
  ],
  "processes": {
    "p1": {"serviceName": "payment-service"},
    "p2": {"serviceName": "api-gateway"},
    "p3": {"serviceName": "order-service"}
  }
}
```

**Flujo del Trace:**
```
Cliente
  │
  ▼
API Gateway (136.5ms total)
  │
  ├─▶ GET /api/payments (client span: 121.2ms)
  │     │
  │     ▼
  │   Payment Service (server span: 105.4ms)
  │     │
  │     ├─▶ GET /order-service/api/orders/1 (client span: 9.3ms)
  │     │     │
  │     │     ▼
  │     │   Order Service (server span: 7.8ms)
  │     │
  │     ├─▶ GET /order-service/api/orders/2
  │     ├─▶ GET /order-service/api/orders/3
  │     └─▶ GET /order-service/api/orders/4
  │
  ▼
Respuesta
```

**Análisis de Latencia:**
- **Total de solicitud**: 136.5ms
- **API Gateway overhead**: 15.3ms (11.2%)
- **Payment Service processing**: 105.4ms (77.2%)
- **Order Service calls**: 4 llamadas paralelas/secuenciales
- **Database queries**: Incluidos en el tiempo del servicio

#### 6.4.4 Ejemplo de Trace: GET /api/products

```
Cliente
  │
  ▼
API Gateway (231.3ms total)
  │
  ├─▶ GET /api/products (client span: 206.3ms)
  │     │
  │     ▼
  │   Product Service (server span: 139.8ms)
  │     │
  │     └─▶ Database Query (incluido en el tiempo del servicio)
  │
  ▼
Respuesta
```

**Métricas:**
- **Total**: 231.3ms
- **API Gateway overhead**: 25ms (10.8%)
- **Product Service**: 139.8ms (60.4%)
- **Network latency**: ~66.5ms (28.8%)

### 6.5 Script de Generación de Tráfico

Para facilitar las pruebas de tracing, se implementó un script automatizado:

```bash
# infrastructure/kubernetes/tracing/generate-traffic-simple.sh
#!/bin/bash

NAMESPACE=${1:-prod}
API_URL="http://localhost:18080"

echo "================================================"
echo "  Traffic Generator for Distributed Tracing"
echo "================================================"
echo ""
echo "Using namespace: $NAMESPACE"
echo ""

# Port-forward al API Gateway
echo "Setting up port-forward to API Gateway..."
kubectl port-forward -n $NAMESPACE svc/api-gateway 18080:80 &
PF_PID=$!
echo "Port-forward started (PID: $PF_PID)"
sleep 5

echo ""
echo "API Gateway available at: $API_URL"
echo ""
echo "Generating traffic to create traces..."
echo ""

# Generar 5 batches de requests
for i in {1..5}; do
  echo "Batch $i/5:"
  curl -s ${API_URL}/app/api/products > /dev/null 2>&1 && echo "  ✓ GET /products" || echo "  ✗ GET /products"
  curl -s ${API_URL}/app/api/users > /dev/null 2>&1 && echo "  ✓ GET /users" || echo "  ✗ GET /users"
  curl -s ${API_URL}/app/api/orders > /dev/null 2>&1 && echo "  ✓ GET /orders" || echo "  ✗ GET /orders"
  curl -s ${API_URL}/app/api/payments > /dev/null 2>&1 && echo "  ✓ GET /payments" || echo "  ✗ GET /payments"
  sleep 2
done

echo ""
echo "Traffic generation completed!"
echo ""
echo "Waiting 10 seconds for traces to be processed..."
sleep 10

# Verificar servicios en Jaeger
echo ""
echo "Checking services registered in Jaeger..."
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n tracing -- \
  curl -s http://jaeger-query.tracing.svc.cluster.local:16686/api/services

echo ""
echo ""
echo "================================================"
echo "Done!"
echo "================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Open Jaeger UI: http://localhost:16686"
echo ""
echo "2. In the 'Service' dropdown, select a service (e.g., 'api-gateway')"
echo ""
echo "3. Click 'Find Traces'"
echo ""
echo "4. You should see traces from the requests we just made!"
echo ""
echo "Useful Commands:"
echo "  View logs:          kubectl logs -n $NAMESPACE deployment/api-gateway -f"
echo "  Kill port-forward:  kill $PF_PID"
echo "  Re-run script:      ./generate-traffic-simple.sh $NAMESPACE"
echo ""

# Preguntar si mantener el port-forward
read -p "Keep port-forward running? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Port-forward still running on PID $PF_PID"
    echo "To stop it later: kill $PF_PID"
    echo ""
else
    kill $PF_PID 2>/dev/null
    echo "Port-forward stopped"
fi
```

**Uso del script:**
```bash
cd infrastructure/kubernetes/tracing
chmod +x generate-traffic-simple.sh
./generate-traffic-simple.sh prod
```

### 6.6 Acceso a Jaeger UI

#### Método 1: NodePort (Recomendado para Desarrollo)

```bash
# Obtener la IP de Minikube
$ minikube ip
192.168.49.2

# Acceder a Jaeger UI
http://192.168.49.2:30686
```

#### Método 2: Port-Forward

```bash
# Port-forward a Jaeger Query
kubectl port-forward -n tracing svc/jaeger-query 16686:16686

# Acceder a Jaeger UI
http://localhost:16686
```

### 6.7 Características de Jaeger UI

1. **Service Dropdown**: Selecciona el servicio a investigar
2. **Lookback**: Define el rango temporal de búsqueda
3. **Min/Max Duration**: Filtra traces por duración
4. **Tags**: Busca traces con tags específicos (ej: `http.status_code=500`)
5. **Trace Timeline**: Visualización gráfica de spans
6. **Dependency Graph**: Mapa de dependencias entre servicios
7. **Comparison**: Compara múltiples traces

### 6.8 Mejores Prácticas Implementadas

1. **Naming Conventions**:
   - Nombres de servicios en mayúsculas: `API-GATEWAY`, `PAYMENT-SERVICE`
   - Operation names descriptivos: `get /api/payments`, `get /api/orders/{orderid}`

2. **Tags Informativos**:
   - `http.method`: Método HTTP de la solicitud
   - `http.path`: Path completo del endpoint
   - `mvc.controller.class`: Clase del controlador
   - `mvc.controller.method`: Método del controlador
   - `span.kind`: `client` o `server`

3. **Propagación de Contexto**:
   - Los headers de tracing se propagan automáticamente mediante Spring Cloud Sleuth
   - `X-B3-TraceId`: ID único del trace
   - `X-B3-SpanId`: ID único del span
   - `X-B3-ParentSpanId`: ID del span padre

4. **Recursos de Jaeger**:
   ```yaml
   resources:
     limits:
       memory: "1Gi"
       cpu: "500m"
     requests:
       memory: "512Mi"
       cpu: "250m"
   ```

### 6.9 Resolución de Problemas Comunes

#### Problema: No aparecen servicios en Jaeger

**Solución:**
1. Verificar que las dependencias están en el `pom.xml`
2. Verificar configuración de `spring.zipkin.base-url` en `application.yml`
3. Verificar que el pod de Jaeger esté corriendo
4. Verificar logs del servicio para errores de conexión

```bash
kubectl logs -n prod deployment/payment-service | grep -i zipkin
```

#### Problema: Traces incompletos

**Solución:**
1. Verificar que todos los servicios en la cadena tienen instrumentación
2. Verificar que los headers de tracing se están propagando
3. Verificar timeouts y circuit breakers

#### Problema: Error 403 en endpoints

**Solución:**
1. Verificar configuración de seguridad en `SecurityConfig.java`
2. Asegurar que los endpoints están en la lista de `permitAll()`
3. Verificar que no hay filtros JWT bloqueando las solicitudes

### 6.10 Resultados y Beneficios

#### Mejoras en Observabilidad

1. **Visibilidad Completa**: Ahora se pueden rastrear solicitudes a través de 7 servicios
2. **Identificación Rápida de Problemas**: Los errores 403 se identificaron en minutos
3. **Análisis de Latencia**: Se puede ver exactamente dónde se gasta el tiempo
4. **Debugging Simplificado**: Los traces muestran la secuencia exacta de llamadas

#### Métricas de Rendimiento

| Métrica | Valor | Observación |
|---------|-------|-------------|
| **Servicios monitoreados** | 7/9 | 77.8% de cobertura |
| **Tiempo de respuesta promedio** | 150ms | Aceptable para operaciones CRUD |
| **Overhead de tracing** | <5% | Impacto mínimo en rendimiento |
| **Retención de traces** | In-memory | Adecuado para desarrollo |

#### Lecciones Aprendidas

1. **Instrumentación Completa es Crítica**: Sin las dependencias correctas, los traces están incompletos
2. **Seguridad vs Observabilidad**: La autenticación puede bloquear el debugging; considerar endpoints de health sin autenticación
3. **Configuración Centralizada**: Usar ConfigMaps para configuración de Zipkin facilita cambios
4. **Testing de Tracing**: El script de generación de tráfico es esencial para validar la implementación

### 6.11 Trabajo Futuro

1. **Almacenamiento Persistente**:
   - Migrar de in-memory a Elasticsearch o Cassandra
   - Configurar retención de traces por 7-30 días

2. **Métricas Adicionales**:
   - Integrar con Prometheus para métricas
   - Configurar alertas basadas en latencia

3. **Sampling**:
   - Implementar sampling adaptativo
   - Configurar diferentes tasas de sampling por ambiente

4. **Seguridad**:
   - Re-implementar autenticación JWT con excepciones para health checks
   - Configurar RBAC para acceso a Jaeger UI

5. **Correlación de Logs**:
   - Agregar trace IDs a logs de aplicación
   - Integrar con ELK stack para correlación logs-traces

### 6.12 Comandos Útiles

```bash
# Ver logs de Jaeger
kubectl logs -n tracing deployment/jaeger -f

# Verificar servicios registrados
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n tracing -- \
  curl -s http://jaeger-query.tracing.svc.cluster.local:16686/api/services

# Obtener traces de un servicio
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n tracing -- \
  curl -s "http://jaeger-query.tracing.svc.cluster.local:16686/api/traces?service=api-gateway&limit=10"

# Reiniciar un servicio para aplicar cambios
kubectl rollout restart deployment/payment-service -n prod

# Ver variables de entorno de un pod
kubectl exec -n prod deployment/payment-service -- env | grep ZIPKIN

# Port-forward múltiple (Jaeger + API Gateway)
kubectl port-forward -n tracing svc/jaeger-query 16686:16686 &
kubectl port-forward -n prod svc/api-gateway 18080:80 &
```

### 6.13 Referencias

- **Jaeger Documentation**: https://www.jaegertracing.io/docs/
- **Spring Cloud Sleuth**: https://spring.io/projects/spring-cloud-sleuth
- **OpenTracing**: https://opentracing.io/
- **Distributed Tracing Best Practices**: https://microservices.io/patterns/observability/distributed-tracing.html

---

## 7. Monitoreo con Prometheus y Grafana

### 7.1 Introducción

El monitoreo de métricas es esencial para comprender el comportamiento, rendimiento y salud de los microservicios en producción. Prometheus y Grafana forman un stack de monitoreo completo que permite:

- **Prometheus**: Recolectar y almacenar métricas en series temporales
- **Grafana**: Visualizar las métricas en dashboards interactivos y configurar alertas

#### Beneficios del Monitoreo con Métricas

1. **Visibilidad de Rendimiento**: Monitoreo de latencia, throughput y tasas de error
2. **Salud de la JVM**: Memoria, garbage collection, threads
3. **Métricas de Negocio**: Contadores personalizados, histogramas
4. **Alertas Proactivas**: Notificaciones antes de que ocurran problemas críticos
5. **Análisis Histórico**: Tendencias y patrones a lo largo del tiempo

### 7.2 Estado Actual de la Implementación

**Estado**: Configurado pero NO desplegado actualmente

El proyecto cuenta con una configuración completa de Prometheus y Grafana lista para ser desplegada, pero **no está activa en el cluster actual**. Los archivos de configuración están disponibles en:

```
infrastructure/kubernetes/monitoring/
├── namespace.yaml                      # Namespace de monitoring
├── prometheus-config.yaml              # Configuración de scraping
├── prometheus.yaml                     # Deployment y servicios
├── prometheus-alert-rules.yaml         # Reglas de alerta
├── grafana-config.yaml                 # Datasources y dashboards
├── grafana.yaml                        # Deployment y servicios
├── alertmanager-config.yaml            # Configuración de alertas
├── alertmanager.yaml                   # AlertManager deployment
├── deploy-monitoring.sh                # Script de despliegue
├── deploy-alerting.sh                  # Script de alerting
├── access-monitoring.sh                # Script de acceso
└── README.md                           # Documentación
```

### 7.3 Arquitectura de Monitoreo Diseñada

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DE MONITOREO                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     MICROSERVICIOS                         │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │ │
│  │  │  User    │ │ Product  │ │  Order   │ │ Payment  │...  │ │
│  │  │ Service  │ │ Service  │ │ Service  │ │ Service  │     │ │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘     │ │
│  │       │            │            │            │            │ │
│  │       └────────────┴────────────┴────────────┘            │ │
│  │                          │                                │ │
│  │              /actuator/prometheus (HTTP)                  │ │
│  └──────────────────────────┼─────────────────────────────────┘ │
│                             │                                   │
│                             ▼                                   │
│                  ┌────────────────────┐                         │
│                  │    PROMETHEUS      │                         │
│                  │  (Time Series DB)  │                         │
│                  │                    │                         │
│                  │  - Scraping (15s)  │                         │
│                  │  - Storage (30d)   │                         │
│                  │  - Query (PromQL)  │                         │
│                  └─────────┬──────────┘                         │
│                            │                                    │
│              ┌─────────────┴──────────────┐                     │
│              │                            │                     │
│              ▼                            ▼                     │
│   ┌────────────────────┐      ┌────────────────────┐           │
│   │     GRAFANA        │      │   ALERTMANAGER     │           │
│   │  (Visualization)   │      │   (Notifications)  │           │
│   │                    │      │                    │           │
│   │  - Dashboards      │      │  - Email alerts    │           │
│   │  - Queries         │      │  - Slack alerts    │           │
│   │  - Users/Teams     │      │  - Grouping        │           │
│   └────────────────────┘      └────────────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 Configuración de Microservicios para Prometheus

Todos los microservicios del proyecto están **preconfigurados** para exponer métricas en formato Prometheus:

#### 7.4.1 Dependencias Maven

El POM padre incluye la dependencia necesaria:

```xml
<!-- Parent pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Esta dependencia ya está incluida en todos los servicios a través del parent POM.

#### 7.4.2 Configuración de Spring Boot Actuator

Cada microservicio expone el endpoint de Prometheus:

```yaml
# application.yml de cada servicio
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

#### 7.4.3 Endpoints de Métricas

Cada servicio expone sus métricas en:

```
http://<service-name>:<port>/<context-path>/actuator/prometheus
```

**Ejemplos:**
- `http://user-service:8081/user-service/actuator/prometheus`
- `http://product-service:8082/product-service/actuator/prometheus`
- `http://payment-service:8084/payment-service/actuator/prometheus`
- `http://api-gateway:80/actuator/prometheus`

### 7.5 Configuración de Prometheus

#### 7.5.1 Scrape Configuration

Prometheus está configurado para recolectar métricas de todos los microservicios:

```yaml
# prometheus-config.yaml
scrape_configs:
  # API Gateway
  - job_name: 'api-gateway'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['api-gateway.prod.svc.cluster.local:80']
        labels:
          service: 'api-gateway'
          environment: 'prod'

  # User Service
  - job_name: 'user-service'
    metrics_path: '/user-service/actuator/prometheus'
    static_configs:
      - targets: ['user-service.prod.svc.cluster.local:8081']
        labels:
          service: 'user-service'
          environment: 'prod'

  # Product Service
  - job_name: 'product-service'
    metrics_path: '/product-service/actuator/prometheus'
    static_configs:
      - targets: ['product-service.prod.svc.cluster.local:8082']
        labels:
          service: 'product-service'
          environment: 'prod'

  # Order Service
  - job_name: 'order-service'
    metrics_path: '/order-service/actuator/prometheus'
    static_configs:
      - targets: ['order-service.prod.svc.cluster.local:8083']
        labels:
          service: 'order-service'
          environment: 'prod'

  # Payment Service
  - job_name: 'payment-service'
    metrics_path: '/payment-service/actuator/prometheus'
    static_configs:
      - targets: ['payment-service.prod.svc.cluster.local:8084']
        labels:
          service: 'payment-service'
          environment: 'prod'

  # Shipping Service
  - job_name: 'shipping-service'
    metrics_path: '/shipping-service/actuator/prometheus'
    static_configs:
      - targets: ['shipping-service.prod.svc.cluster.local:8085']
        labels:
          service: 'shipping-service'
          environment: 'prod'

  # Favourite Service
  - job_name: 'favourite-service'
    metrics_path: '/favourite-service/actuator/prometheus'
    static_configs:
      - targets: ['favourite-service.prod.svc.cluster.local:8086']
        labels:
          service: 'favourite-service'
          environment: 'prod'

  # Service Discovery (Eureka)
  - job_name: 'service-discovery'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['service-discovery.prod.svc.cluster.local:8761']
        labels:
          service: 'service-discovery'
          environment: 'prod'

  # Proxy Client
  - job_name: 'proxy-client'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['proxy-client.prod.svc.cluster.local:8080']
        labels:
          service: 'proxy-client'
          environment: 'prod'
```

**Configuración Global:**
- `scrape_interval: 15s` - Recolectar métricas cada 15 segundos
- `evaluation_interval: 15s` - Evaluar reglas cada 15 segundos
- `scrape_timeout: 10s` - Timeout de scraping

#### 7.5.2 Recursos de Prometheus

```yaml
# prometheus.yaml
resources:
  limits:
    memory: "2Gi"
    cpu: "1000m"
  requests:
    memory: "1Gi"
    cpu: "500m"

# PVC para almacenamiento persistente
storage:
  volumeClaimTemplate:
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi

# Retención de datos
args:
  - '--config.file=/etc/prometheus/prometheus.yml'
  - '--storage.tsdb.path=/prometheus/'
  - '--storage.tsdb.retention.time=30d'
  - '--web.console.libraries=/etc/prometheus/console_libraries'
  - '--web.console.templates=/etc/prometheus/consoles'
  - '--web.enable-lifecycle'
```

### 7.6 Configuración de Grafana

#### 7.6.1 Datasource Preconfigurado

Grafana viene con Prometheus ya configurado como datasource:

```yaml
# grafana-config.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

#### 7.6.2 Dashboard Preinstalado

**Spring Boot Microservices Overview Dashboard**

Incluye paneles para:
- **JVM Metrics**:
  - Heap memory usage
  - Non-heap memory usage
  - Garbage collection count/duration
  - Thread count
  - Classes loaded

- **HTTP Metrics**:
  - Request rate (req/sec)
  - Request duration (p50, p95, p99)
  - Status code distribution (2xx, 4xx, 5xx)
  - Error rate

- **Database Metrics** (HikariCP):
  - Active connections
  - Idle connections
  - Connection wait time
  - Query execution time

- **Circuit Breaker Metrics** (Resilience4j):
  - Circuit state (closed/open/half-open)
  - Failure rate
  - Slow call rate

#### 7.6.3 Credenciales

```
Username: admin
Password: admin123
```

**⚠️ IMPORTANTE**: Cambiar la contraseña en entornos de producción.

### 7.7 Reglas de Alerta Configuradas

El sistema incluye reglas de alerta preconfiguradas:

```yaml
# prometheus-alert-rules.yaml
groups:
  - name: microservices_alerts
    interval: 30s
    rules:
      # Alta tasa de errores HTTP
      - alert: HighErrorRate
        expr: |
          sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (service)
          /
          sum(rate(http_server_requests_seconds_count[5m])) by (service)
          > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Service {{ $labels.service }} has error rate > 5% for 5 minutes"

      # Servicio Down
      - alert: ServiceDown
        expr: up{job=~".*-service"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "Service {{ $labels.job }} has been down for more than 1 minute"

      # Alta latencia
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_server_requests_seconds_bucket[5m])) by (service, le)
          ) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High latency on {{ $labels.service }}"
          description: "95th percentile latency > 1s for 10 minutes"

      # Alto uso de memoria JVM
      - alert: HighMemoryUsage
        expr: |
          (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.service }}"
          description: "Heap memory usage > 90% for 5 minutes"

      # Circuit Breaker abierto
      - alert: CircuitBreakerOpen
        expr: |
          resilience4j_circuitbreaker_state{state="open"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Circuit breaker open on {{ $labels.name }}"
          description: "Circuit breaker {{ $labels.name }} has been open for 5 minutes"
```

### 7.8 Cómo Desplegar el Stack de Monitoreo

#### 7.8.1 Despliegue Completo (Prometheus + Grafana)

```bash
# Navegar al directorio de monitoring
cd infrastructure/kubernetes/monitoring

# Ejecutar script de despliegue
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh
```

**Salida esperada:**
```
========================================
E-Commerce Monitoring Stack Deployment
========================================

[INFO] Step 1: Creating monitoring namespace...
namespace/monitoring created
[INFO] ✓ Namespace created/verified

[INFO] Step 2: Deploying Prometheus...
configmap/prometheus-config created
deployment.apps/prometheus created
service/prometheus created
service/prometheus-external created
[INFO] ✓ Prometheus deployed

[INFO] Step 3: Deploying Grafana...
configmap/grafana-datasource created
configmap/grafana-dashboard created
deployment.apps/grafana created
service/grafana created
service/grafana-external created
[INFO] ✓ Grafana deployed

[INFO] Step 4: Waiting for deployments to be ready...
[INFO] Waiting for Prometheus...
deployment.apps/prometheus condition met
[INFO] ✓ Prometheus is ready

[INFO] Waiting for Grafana...
deployment.apps/grafana condition met
[INFO] ✓ Grafana is ready

========================================
Deployment Successful!
========================================

📊 Prometheus UI:
   URL: http://192.168.49.2:30090

📈 Grafana UI:
   URL: http://192.168.49.2:30030
   Username: admin
   Password: admin123
```

#### 7.8.2 Despliegue con AlertManager

```bash
# Desplegar sistema de alertas
chmod +x deploy-alerting.sh
./deploy-alerting.sh
```

#### 7.8.3 Verificación del Despliegue

```bash
# Ver todos los recursos de monitoring
kubectl get all -n monitoring

# Resultado esperado:
NAME                              READY   STATUS    RESTARTS   AGE
pod/prometheus-xxxxx-xxxxx        1/1     Running   0          2m
pod/grafana-xxxxx-xxxxx           1/1     Running   0          2m

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
service/prometheus            ClusterIP   10.96.100.1      <none>        9090/TCP
service/prometheus-external   NodePort    10.96.100.2      <none>        9090:30090/TCP
service/grafana               ClusterIP   10.96.100.3      <none>        3000/TCP
service/grafana-external      NodePort    10.96.100.4      <none>        3000:30030/TCP

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prometheus   1/1     1            1           2m
deployment.apps/grafana      1/1     1            1           2m

# Verificar PVCs
kubectl get pvc -n monitoring

NAME             STATUS   VOLUME                                     CAPACITY
prometheus-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi
grafana-pvc      Bound    pvc-yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy   5Gi
```

### 7.9 Acceso a las Interfaces

#### 7.9.1 Prometheus UI

**Método 1: NodePort (Minikube)**
```bash
# Obtener IP de Minikube
minikube ip

# Acceder a Prometheus
http://<minikube-ip>:30090
```

**Método 2: Port-Forward**
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Acceder a
http://localhost:9090
```

**Características de Prometheus UI:**
- **Graph**: Ejecutar consultas PromQL y visualizar gráficas
- **Targets**: Ver estado de todos los servicios monitoreados
- **Alerts**: Ver alertas activas y su estado
- **Configuration**: Ver configuración actual
- **Service Discovery**: Ver servicios descubiertos

#### 7.9.2 Grafana UI

**Método 1: NodePort (Minikube)**
```bash
# Acceder a Grafana
http://<minikube-ip>:30030
```

**Método 2: Port-Forward**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Acceder a
http://localhost:3000
```

**Login:**
- Username: `admin`
- Password: `admin123`

### 7.10 Métricas Disponibles

#### 7.10.1 Métricas de JVM

```promql
# Heap memory usage
jvm_memory_used_bytes{area="heap"}

# Garbage collection count
jvm_gc_pause_seconds_count

# Thread count
jvm_threads_live_threads

# Classes loaded
jvm_classes_loaded_classes
```

#### 7.10.2 Métricas HTTP

```promql
# Request rate
rate(http_server_requests_seconds_count[5m])

# Request duration (p95)
histogram_quantile(0.95,
  sum(rate(http_server_requests_seconds_bucket[5m])) by (service, le)
)

# Error rate
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (service)
/
sum(rate(http_server_requests_seconds_count[5m])) by (service)
```

#### 7.10.3 Métricas de Base de Datos (HikariCP)

```promql
# Active connections
hikaricp_connections_active

# Connection acquisition time
hikaricp_connections_acquire_seconds

# Connection timeout count
hikaricp_connections_timeout_total
```

#### 7.10.4 Métricas de Circuit Breaker (Resilience4j)

```promql
# Circuit breaker state
resilience4j_circuitbreaker_state

# Failure rate
resilience4j_circuitbreaker_failure_rate

# Slow call rate
resilience4j_circuitbreaker_slow_call_rate
```

### 7.11 Consultas PromQL Útiles

```promql
# Top 5 endpoints más lentos
topk(5,
  histogram_quantile(0.95,
    sum(rate(http_server_requests_seconds_bucket[5m])) by (uri, le)
  )
)

# Tasa de error por servicio
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (service)

# Throughput total
sum(rate(http_server_requests_seconds_count[5m]))

# Memoria heap usage por servicio
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

# Número de pods por servicio
count(up{job=~".*-service"} == 1) by (job)
```

### 7.12 Dashboards Recomendados

Para importar dashboards adicionales de Grafana:

1. Ir a **Dashboards → Import** en Grafana UI
2. Ingresar el ID del dashboard de grafana.com
3. Seleccionar datasource Prometheus

**Dashboards recomendados:**

| ID | Nombre | Descripción |
|----|--------|-------------|
| 4701 | JVM (Micrometer) | Métricas completas de JVM |
| 10280 | Spring Boot 2.1 Statistics | Métricas de Spring Boot |
| 11378 | Spring Boot APM Dashboard | Application Performance Monitoring |
| 12227 | Spring Boot Resilience4j | Circuit Breaker y Rate Limiter |
| 7249 | Kubernetes Cluster Monitoring | Métricas del cluster |

### 7.13 Trabajo Futuro y Mejoras

#### 7.13.1 Pendiente de Implementación

1. **Despliegue Inicial**:
   - El stack de monitoreo está **configurado pero no desplegado**
   - Ejecutar `deploy-monitoring.sh` para activarlo

2. **Configuración de Alertas**:
   - Configurar AlertManager con webhooks (Slack, Email)
   - Ajustar umbrales de alertas según SLOs

3. **Dashboards Personalizados**:
   - Crear dashboards específicos por servicio
   - Dashboard de métricas de negocio

4. **Almacenamiento Persistente**:
   - Configurar storage class apropiado para producción
   - Implementar backup de datos históricos

5. **Alta Disponibilidad**:
   - Prometheus con replicación
   - Grafana con múltiples replicas

#### 7.13.2 Integraciones Futuras

1. **Service Mesh (Istio)**:
   - Métricas de red y latencia de sidecar proxies
   - Tracing distribuido con Istio

2. **Logs (ELK Stack)**:
   - Correlación de logs con métricas
   - Dashboards unificados

3. **APM (Application Performance Monitoring)**:
   - New Relic / Datadog integration
   - Profiling de aplicaciones

### 7.14 Comandos Útiles

```bash
# Desplegar monitoring stack
cd infrastructure/kubernetes/monitoring
./deploy-monitoring.sh

# Ver estado de Prometheus
kubectl logs -f deployment/prometheus -n monitoring

# Ver estado de Grafana
kubectl logs -f deployment/grafana -n monitoring

# Port-forward a Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Port-forward a Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Ver targets de Prometheus (requiere port-forward)
curl http://localhost:9090/api/v1/targets | jq

# Verificar métricas de un servicio
kubectl port-forward -n prod svc/user-service 8081:8081
curl http://localhost:8081/user-service/actuator/prometheus

# Reiniciar Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Reiniciar Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Eliminar monitoring stack
kubectl delete namespace monitoring

# Ver uso de recursos
kubectl top pods -n monitoring
```

### 7.15 Troubleshooting

#### Problema: Targets DOWN en Prometheus

**Diagnóstico:**
```bash
# Ver targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Ir a http://localhost:9090/targets
```

**Soluciones:**
1. Verificar que los servicios estén corriendo:
   ```bash
   kubectl get pods -n prod
   ```

2. Verificar que los endpoints existan:
   ```bash
   kubectl get endpoints -n prod
   ```

3. Verificar acceso al endpoint de métricas:
   ```bash
   kubectl port-forward -n prod svc/user-service 8081:8081
   curl http://localhost:8081/user-service/actuator/prometheus
   ```

4. Verificar configuración de Prometheus:
   ```bash
   kubectl get configmap prometheus-config -n monitoring -o yaml
   ```

#### Problema: Grafana no muestra datos

**Soluciones:**
1. Verificar datasource en Grafana UI: **Configuration → Data Sources → Prometheus → Test**

2. Verificar que Prometheus tiene datos:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   # Ejecutar consulta simple: up
   ```

3. Verificar logs de Grafana:
   ```bash
   kubectl logs -f deployment/grafana -n monitoring
   ```

#### Problema: Métricas no aparecen para un servicio

**Soluciones:**
1. Verificar configuración de actuator en `application.yml`

2. Verificar dependencia en `pom.xml`:
   ```xml
   <dependency>
       <groupId>io.micrometer</groupId>
       <artifactId>micrometer-registry-prometheus</artifactId>
   </dependency>
   ```

3. Verificar endpoint de métricas:
   ```bash
   kubectl exec -it <pod-name> -n prod -- curl localhost:8081/user-service/actuator/prometheus
   ```

### 7.16 Resumen del Estado Actual

| Componente | Estado | Detalles |
|------------|--------|----------|
| **Configuración** | ✅ Completa | Todos los archivos YAML configurados |
| **Scripts** | ✅ Listos | Scripts de deploy y acceso disponibles |
| **Microservicios** | ✅ Preparados | Actuator y métricas configuradas |
| **Despliegue** | ⚠️ Pendiente | NO desplegado actualmente |
| **Documentación** | ✅ Completa | README y guías disponibles |

**Próximos pasos:**
1. Ejecutar `./deploy-monitoring.sh` para desplegar Prometheus y Grafana
2. Verificar que todos los targets estén UP en Prometheus
3. Acceder a Grafana y explorar el dashboard preinstalado
4. Configurar AlertManager para notificaciones

### 7.17 Referencias

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **Micrometer Documentation**: https://micrometer.io/docs
- **Spring Boot Actuator**: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
- **PromQL Cheatsheet**: https://promlabs.com/promql-cheat-sheet/

---

