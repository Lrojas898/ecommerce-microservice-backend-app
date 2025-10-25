# Paquete de Pruebas - Taller 2

## Contenido del Paquete

Este archivo ZIP contiene todos los tests implementados para el Taller 2 del proyecto E-commerce Microservices.

### Estructura del Paquete

```
taller2-tests-package/
├── unit/                           # Pruebas Unitarias (5 clases, 27 tests)
│   ├── CredentialServiceImplTest.java
│   ├── CartServiceImplTest.java
│   ├── PaymentServiceImplTest.java
│   ├── ProductServiceImplTest.java
│   └── FavouriteServiceImplTest.java
│
├── integration/                    # Pruebas de Integración (5 clases, 16 tests)
│   ├── UserServiceIntegrationTest.java
│   ├── PaymentOrderIntegrationTest.java
│   ├── ProductCategoryIntegrationTest.java
│   ├── ShippingPaymentIntegrationTest.java
│   └── FavouriteUserProductIntegrationTest.java
│
├── e2e/                            # Pruebas End-to-End (5 clases, 25 tests)
│   ├── UserRegistrationE2ETest.java
│   ├── ProductBrowsingE2ETest.java
│   ├── OrderCreationE2ETest.java
│   ├── PaymentProcessingE2ETest.java
│   └── ShippingFulfillmentE2ETest.java
│
└── performance/                    # Pruebas de Rendimiento (5 escenarios)
    └── locustfile.py
```

## Resumen de Pruebas

### Pruebas Unitarias (5 clases - 27 tests)

| Archivo | Servicio | Descripción | Tests |
|---------|----------|-------------|-------|
| CredentialServiceImplTest.java | user-service | Autenticación y credenciales | 5 |
| CartServiceImplTest.java | order-service | Carrito de compras | 7 |
| PaymentServiceImplTest.java | payment-service | Procesamiento de pagos | 5 |
| ProductServiceImplTest.java | product-service | Catálogo de productos | 5 |
| FavouriteServiceImplTest.java | favourite-service | Gestión de favoritos | 5 |

**Tecnologías:** JUnit 5, Mockito, AssertJ

### Pruebas de Integración (5 clases - 16 tests)

| Archivo | Servicios Integrados | Descripción | Tests |
|---------|---------------------|-------------|-------|
| UserServiceIntegrationTest.java | User + DB | CRUD de usuarios con persistencia | 3 |
| PaymentOrderIntegrationTest.java | Payment ↔ Order | Vinculación pago-pedido | 3 |
| ProductCategoryIntegrationTest.java | Product ↔ Category | Productos con categorías | 3 |
| ShippingPaymentIntegrationTest.java | Shipping ↔ Payment | Envíos vinculados a pagos | 3 |
| FavouriteUserProductIntegrationTest.java | Favourite ↔ User ↔ Product | Favoritos multi-entidad | 4 |

**Tecnologías:** Spring Boot Test, H2 Database, MockBean

### Pruebas End-to-End (5 clases - 25 tests)

| Archivo | Flujo Validado | Servicios Involucrados | Tests |
|---------|----------------|----------------------|-------|
| UserRegistrationE2ETest.java | Registro y autenticación | API Gateway, User Service | 4 |
| ProductBrowsingE2ETest.java | Catálogo y búsqueda | API Gateway, Product Service | 6 |
| OrderCreationE2ETest.java | Creación de pedidos | Gateway, Cart, Product, Order | 5 |
| PaymentProcessingE2ETest.java | Procesamiento de pagos | Gateway, Order, Payment | 5 |
| ShippingFulfillmentE2ETest.java | Gestión de envíos | Gateway, Order, Payment, Shipping | 5 |

**Tecnologías:** RestAssured, Spring Boot Test

### Pruebas de Rendimiento (5 escenarios)

| Escenario | Tipo | Descripción | Métrica Objetivo |
|-----------|------|-------------|------------------|
| ProductServiceLoadTest | Carga | Navegación de catálogo | p95 < 500ms |
| OrderServiceStressTest | Estrés | Creación masiva de órdenes | 100+ RPS |
| UserAuthenticationLoadTest | Carga | Registro y login concurrente | Error rate < 1% |
| ECommercePurchaseUser | E2E | Flujo completo de compra | Latencia total < 2s |
| MixedWorkloadUser | Realista | Mix de operaciones | Throughput > 50 RPS |

**Tecnologías:** Locust, Python

## Ejecución de las Pruebas

### Pruebas Unitarias

```bash
# Ejecutar todas
mvn test

# Ejecutar una clase específica
mvn test -Dtest=CredentialServiceImplTest
```

### Pruebas de Integración

```bash
# Ejecutar todas
mvn verify -Pintegration-tests

# Ejecutar una clase específica
mvn test -Dtest=UserServiceIntegrationTest
```

### Pruebas E2E

```bash
# Configurar base URL
export API_URL=http://localhost:8080

# Ejecutar todas
mvn verify -Pe2e-tests

# Ejecutar una clase específica
mvn test -Dtest=OrderCreationE2ETest
```

### Pruebas de Rendimiento

```bash
cd performance/

# Instalar dependencias
pip install locust

# Ejecutar con UI
locust -f locustfile.py --host=http://localhost:8080

# Ejecutar headless
locust -f locustfile.py MixedWorkloadUser \
       --host=http://localhost:8080 \
       --users 100 \
       --spawn-rate 10 \
       --run-time 5m \
       --headless \
       --html report.html
```

## Cumplimiento de Requisitos

✅ **Punto 3.1:** 5 clases de pruebas unitarias (27 tests) - CUMPLE (540%)
✅ **Punto 3.2:** 5 clases de pruebas de integración (16 tests) - CUMPLE (320%)
✅ **Punto 3.3:** 5 clases de pruebas E2E (25 tests) - CUMPLE (500%)
✅ **Punto 3.4:** Suite completa de pruebas de rendimiento con Locust - CUMPLE (100%)

**Total:** 68 tests + 5 escenarios de rendimiento

## Integración con CI/CD

Todas las pruebas están integradas en los pipelines de Jenkins:

- **Pipeline DEV:** Ejecuta pruebas unitarias
- **Pipeline STAGE:** Ejecuta unitarias + integración + E2E + rendimiento
- **Pipeline PROD:** Ejecuta suite completa antes del deploy

## Documentación Adicional

Para más detalles sobre las pruebas implementadas, consultar:

- `INFORME_TALLER2.md` - Sección 6: Pruebas Implementadas
- `INFORME_TALLER2.md` - Sección 6.5: Análisis de Cumplimiento de Requisitos

---

**Proyecto:** E-commerce Microservices Backend
**Taller:** 2 - Pruebas y Lanzamiento
**Fecha:** Octubre 2025
