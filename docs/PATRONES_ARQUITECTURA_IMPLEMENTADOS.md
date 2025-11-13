# Patrones de Arquitectura Implementados
## E-Commerce Microservices Backend Application

---

## 1. PATRONES DE MICROSERVICIOS

### 1.1 Service Registry & Discovery Pattern

#### Descripción Técnica
Implementación de registro y descubrimiento de servicios utilizando Netflix Eureka Server. Los servicios se registran automáticamente al iniciar y publican su ubicación (host, puerto, metadata) al servidor de registro. Los clientes consultan el registro para obtener ubicaciones de servicios en tiempo de ejecución.

#### Tecnología
- **Framework:** Netflix Eureka Server 3.1.x
- **Dependencia:** `spring-cloud-starter-netflix-eureka-server`
- **Spring Cloud Version:** 2021.0.9

#### Implementación

**Servidor de Registro:**
```xml
<!-- service-discovery/pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

```java
// service-discovery/src/main/java/com/selimhorri/app/ServiceDiscoveryApplication.java
@SpringBootApplication
@EnableEurekaServer
public class ServiceDiscoveryApplication {
    public static void main(String[] args) {
        SpringApplication.run(ServiceDiscoveryApplication.class, args);
    }
}
```

**Configuración del Servidor:**
```yaml
# service-discovery/src/main/resources/application.yml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
  server:
    enable-self-preservation: true
```

**Configuración del Cliente (Ejemplo: order-service):**
```xml
<!-- order-service/pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

```yaml
# order-service/src/main/resources/application.yml
eureka:
  client:
    enabled: true
    register-with-eureka: true
    fetch-registry: true
    service-url:
      defaultZone: ${EUREKA_SERVER_URL:http://localhost:8761/eureka/}
  instance:
    lease-renewal-interval-in-seconds: 5
    lease-expiration-duration-in-seconds: 15
```

#### Servicios Registrados

| Servicio | Puerto | Application Name |
|----------|--------|------------------|
| service-discovery | 8761 | SERVICE-DISCOVERY |
| api-gateway | 80 | API-GATEWAY |
| cloud-config | 9296 | CLOUD-CONFIG |
| user-service | 8081 | USER-SERVICE |
| product-service | 8082 | PRODUCT-SERVICE |
| order-service | 8083 | ORDER-SERVICE |
| payment-service | 8084 | PAYMENT-SERVICE |
| shipping-service | 8085 | SHIPPING-SERVICE |
| favourite-service | 8086 | FAVOURITE-SERVICE |
| proxy-client | 8080 | PROXY-CLIENT |

#### Mecanismo de Funcionamiento

1. **Registro:** Cada servicio envía heartbeat cada 5 segundos (`lease-renewal-interval`)
2. **Expiración:** Si no hay heartbeat en 15 segundos, el servicio se marca como DOWN
3. **Cache:** Clientes cachean el registro y lo actualizan cada 30 segundos
4. **Self-Preservation:** Previene eliminación masiva de servicios por problemas de red

---

### 1.2 API Gateway Pattern

#### Descripción Técnica
Implementación de un gateway reactivo que actúa como punto único de entrada al sistema. Utiliza Spring Cloud Gateway con enrutamiento basado en predicados y filtros. El gateway se integra con Eureka para resolver ubicaciones de servicios dinámicamente mediante el protocolo `lb://`.

#### Tecnología
- **Framework:** Spring Cloud Gateway 3.1.x (reactive)
- **Dependencia:** `spring-cloud-starter-gateway`
- **Load Balancer:** Spring Cloud LoadBalancer

#### Implementación

**Dependencias:**
```xml
<!-- api-gateway/pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

**Configuración de Rutas:**
```yaml
# api-gateway/src/main/resources/application.yml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
            allowed-origins: "*"
            allowed-methods:
              - GET
              - POST
              - PUT
              - DELETE
              - OPTIONS
            allowed-headers: "*"
            allow-credentials: false
            max-age: 3600

      routes:
        - id: order-service
          uri: lb://ORDER-SERVICE
          predicates:
            - Path=/order-service/**

        - id: payment-service
          uri: lb://PAYMENT-SERVICE
          predicates:
            - Path=/payment-service/**

        - id: product-service
          uri: lb://PRODUCT-SERVICE
          predicates:
            - Path=/product-service/**

        - id: shipping-service
          uri: lb://SHIPPING-SERVICE
          predicates:
            - Path=/shipping-service/**

        - id: user-service
          uri: lb://USER-SERVICE
          predicates:
            - Path=/user-service/**

        - id: favourite-service
          uri: lb://FAVOURITE-SERVICE
          predicates:
            - Path=/favourite-service/**

        - id: proxy-client
          uri: lb://PROXY-CLIENT
          predicates:
            - Path=/app/**
          filters:
            - StripPrefix=0

      default-filters:
        - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin
```

#### Características Implementadas

**1. Load Balancing:**
- URI con prefijo `lb://` activa load balancing
- Resolución de instancias mediante Eureka
- Algoritmo Round-Robin por defecto

**2. CORS Global:**
- Configurado para todos los endpoints (`[/**]`)
- Permite todos los orígenes en desarrollo (`allowed-origins: "*"`)
- Métodos HTTP: GET, POST, PUT, DELETE, OPTIONS
- Max-Age: 3600 segundos

**3. Filtros:**
- `DedupeResponseHeader`: Elimina headers duplicados de CORS
- `StripPrefix`: Remueve prefijos de path antes de reenviar

#### Flujo de Request

```
Client Request → API Gateway (Port 80) → Service Discovery (Eureka) → Backend Service
     ↓
  /order-service/api/orders
     ↓
Gateway aplica predicado Path=/order-service/**
     ↓
Resuelve lb://ORDER-SERVICE via Eureka
     ↓
Obtiene instancia (ej: localhost:8083)
     ↓
Reenvía request a http://localhost:8083/order-service/api/orders
```

---

### 1.3 Circuit Breaker Pattern

#### Descripción Técnica
Implementación del patrón Circuit Breaker utilizando Resilience4j para prevenir cascadas de fallos. El circuit breaker monitorea llamadas entre servicios y se abre automáticamente cuando la tasa de fallos supera el umbral configurado. Estados: CLOSED (normal), OPEN (bloqueando llamadas), HALF_OPEN (probando recuperación).

#### Tecnología
- **Framework:** Resilience4j 1.7.x
- **Dependencia:** `spring-cloud-starter-circuitbreaker-resilience4j`
- **Integración:** Spring Cloud Circuit Breaker

#### Implementación

**Dependencias (Parent POM):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
</dependency>
```

**Configuración (api-gateway):**
```yaml
# api-gateway/src/main/resources/application.yml
resilience4j:
  circuitbreaker:
    instances:
      apiGateway:
        register-health-indicator: true
        failure-rate-threshold: 50
        minimum-number-of-calls: 5
        permitted-number-of-calls-in-half-open-state: 3
        sliding-window-size: 10
        wait-duration-in-open-state: 5s
        sliding-window-type: COUNT_BASED
```

**Configuración (order-service):**
```yaml
# order-service/src/main/resources/application.yml
resilience4j:
  circuitbreaker:
    instances:
      orderService:
        register-health-indicator: true
        failure-rate-threshold: 50
        minimum-number-of-calls: 5
        permitted-number-of-calls-in-half-open-state: 3
        sliding-window-size: 10
        wait-duration-in-open-state: 5s
        sliding-window-type: COUNT_BASED
```

#### Parámetros de Configuración

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `failure-rate-threshold` | 50 | Porcentaje de fallos para abrir circuito |
| `minimum-number-of-calls` | 5 | Llamadas mínimas antes de calcular tasa de fallo |
| `sliding-window-size` | 10 | Tamaño de ventana para calcular tasa de fallo |
| `sliding-window-type` | COUNT_BASED | Tipo de ventana (basada en conteo) |
| `wait-duration-in-open-state` | 5s | Tiempo en estado OPEN antes de pasar a HALF_OPEN |
| `permitted-number-of-calls-in-half-open-state` | 3 | Llamadas permitidas en HALF_OPEN para probar recuperación |
| `register-health-indicator` | true | Expone estado en `/actuator/health` |

#### Estados del Circuit Breaker

**1. CLOSED (Circuito Cerrado):**
- Llamadas fluyen normalmente
- Monitorea tasa de fallos
- Si tasa de fallos > 50% y llamadas >= 5 → transición a OPEN

**2. OPEN (Circuito Abierto):**
- Bloquea todas las llamadas
- Retorna fallo inmediatamente sin ejecutar lógica
- Después de 5 segundos → transición a HALF_OPEN

**3. HALF_OPEN (Medio Abierto):**
- Permite 3 llamadas de prueba
- Si todas tienen éxito → transición a CLOSED
- Si alguna falla → transición a OPEN

#### Health Indicator

```bash
# Endpoint expuesto
GET /actuator/health

# Respuesta incluye:
{
  "status": "UP",
  "components": {
    "circuitBreakers": {
      "status": "UP",
      "details": {
        "apiGateway": {
          "status": "UP",
          "details": {
            "failureRate": "0.0%",
            "slowCallRate": "0.0%",
            "state": "CLOSED"
          }
        }
      }
    }
  }
}
```

#### Servicios con Circuit Breaker

1. api-gateway (instance: `apiGateway`)
2. service-discovery (instance: `serviceDiscovery`)
3. cloud-config (instance: `cloudConfig`)
4. proxy-client (instance: `proxyService`)
5. order-service (instance: `orderService`)
6. user-service (instance: `userService`)
7. product-service (instance: `productService`)
8. payment-service (instance: `paymentService`)
9. shipping-service (instance: `shippingService`)
10. favourite-service (instance: `favouriteService`)

---

### 1.4 Load Balancing Pattern

#### Descripción Técnica
Implementación de load balancing client-side utilizando Spring Cloud LoadBalancer. El balanceador distribuye requests entre múltiples instancias de un servicio. Se integra con Eureka para obtener lista de instancias disponibles. Utiliza estrategia Round-Robin por defecto.

#### Tecnología
- **Framework:** Spring Cloud LoadBalancer 3.1.x
- **Dependencia:** `spring-cloud-starter-loadbalancer`
- **Algoritmo:** Round-Robin (default)

#### Implementación

**Configuración (proxy-client):**
```yaml
# proxy-client/src/main/resources/application.yml
spring:
  cloud:
    loadbalancer:
      ribbon:
        enabled: false
      retry:
        enabled: false
      eager-load:
        enabled: true
        clients:
          - USER-SERVICE
          - PRODUCT-SERVICE
          - ORDER-SERVICE
          - PAYMENT-SERVICE
          - SHIPPING-SERVICE
          - FAVOURITE-SERVICE
```

**RestTemplate con Load Balancing:**
```java
// order-service/src/main/java/com/selimhorri/app/config/client/ClientConfig.java
package com.selimhorri.app.config.client;

import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class ClientConfig {

    private final AuthorizationHeaderInterceptor authorizationHeaderInterceptor;

    public ClientConfig(AuthorizationHeaderInterceptor authorizationHeaderInterceptor) {
        this.authorizationHeaderInterceptor = authorizationHeaderInterceptor;
    }

    @LoadBalanced
    @Bean
    public RestTemplate restTemplateBean() {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.setInterceptors(
            Collections.singletonList(authorizationHeaderInterceptor)
        );
        return restTemplate;
    }
}
```

**Uso en Servicios:**
```java
// payment-service/src/main/java/com/selimhorri/app/service/impl/PaymentServiceImpl.java
@Service
@Transactional
public class PaymentServiceImpl implements PaymentService {

    private final RestTemplate restTemplate;

    public PaymentServiceImpl(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Override
    public PaymentDto findById(final Integer paymentId) {
        Payment payment = this.paymentRepository.findById(paymentId)
            .orElseThrow(() -> new PaymentNotFoundException(...));

        PaymentDto paymentDto = this.paymentMappingHelper.map(payment);

        // Load balancing automático al llamar ORDER-SERVICE
        paymentDto.setOrderDto(
            this.restTemplate.getForObject(
                "http://ORDER-SERVICE/order-service/api/orders/" +
                paymentDto.getOrderDto().getOrderId(),
                OrderDto.class
            )
        );

        return paymentDto;
    }
}
```

#### Características Implementadas

**1. Eager Loading:**
- Precarga lista de instancias al iniciar
- Reduce latencia de primer request
- Configurado para 6 servicios principales

**2. Ribbon Deshabilitado:**
- `spring.cloud.loadbalancer.ribbon.enabled: false`
- Uso de Spring Cloud LoadBalancer nativo

**3. Retry Deshabilitado:**
- `spring.cloud.loadbalancer.retry.enabled: false`
- Control explícito de reintentos

#### Resolución de Instancias

```
RestTemplate.getForObject("http://ORDER-SERVICE/...")
     ↓
@LoadBalanced intercepta request
     ↓
Consulta Eureka para instancias de ORDER-SERVICE
     ↓
Obtiene lista: [localhost:8083, host2:8083]
     ↓
Aplica algoritmo Round-Robin
     ↓
Selecciona instancia: localhost:8083
     ↓
Reemplaza URL: http://localhost:8083/...
     ↓
Ejecuta HTTP request
```

#### Servicios con RestTemplate Load-Balanced

1. order-service → llama a PAYMENT-SERVICE, SHIPPING-SERVICE
2. payment-service → llama a ORDER-SERVICE
3. product-service → llama a CATEGORY-SERVICE (interno)
4. user-service → no realiza llamadas externas
5. shipping-service → llama a ORDER-SERVICE
6. favourite-service → llama a USER-SERVICE, PRODUCT-SERVICE
7. proxy-client → llama a todos los servicios (Feign + LoadBalancer)

---

### 1.5 External Configuration Pattern

#### Descripción Técnica
Implementación de gestión centralizada de configuración utilizando Spring Cloud Config Server. El servidor obtiene configuraciones de un repositorio Git y las distribuye a los microservicios. Los servicios consultan el servidor al iniciar y pueden recargar configuraciones en tiempo de ejecución.

#### Tecnología
- **Framework:** Spring Cloud Config Server 3.1.x
- **Dependencia:** `spring-cloud-config-server`
- **Backend:** Git Repository

#### Implementación

**Config Server:**
```xml
<!-- cloud-config/pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
</dependency>
```

```java
// cloud-config/src/main/java/com/selimhorri/app/CloudConfigApplication.java
@SpringBootApplication
@EnableConfigServer
public class CloudConfigApplication {
    public static void main(String[] args) {
        SpringApplication.run(CloudConfigApplication.class, args);
    }
}
```

**Configuración del Servidor:**
```yaml
# cloud-config/src/main/resources/application.yml
server:
  port: 9296

spring:
  application:
    name: CLOUD-CONFIG
  cloud:
    config:
      server:
        git:
          uri: https://github.com/SelimHorri/cloud-config-server
          clone-on-start: true
          default-label: master
```

**Configuración del Cliente (api-gateway):**
```yaml
# api-gateway/src/main/resources/application.yml
spring:
  application:
    name: API-GATEWAY
  config:
    import: ${SPRING_CONFIG_IMPORT:optional:configserver:http://localhost:9296}
```

**Configuración del Cliente (order-service):**
```yaml
# order-service/src/main/resources/application.yml
spring:
  application:
    name: ORDER-SERVICE
  config:
    import: ${SPRING_CONFIG_IMPORT:optional:configserver:http://localhost:9296}
```

#### Estructura del Repositorio Git

```
cloud-config-server/
├── application.yml              # Configuración global
├── application-dev.yml          # Perfil desarrollo
├── application-prod.yml         # Perfil producción
├── api-gateway.yml             # Específico para API Gateway
├── api-gateway-dev.yml
├── api-gateway-prod.yml
├── order-service.yml           # Específico para Order Service
├── order-service-dev.yml
├── order-service-prod.yml
└── ...
```

#### Precedencia de Configuración

**Orden de carga (mayor a menor prioridad):**
1. `{service-name}-{profile}.yml` (ej: `order-service-prod.yml`)
2. `{service-name}.yml` (ej: `order-service.yml`)
3. `application-{profile}.yml` (ej: `application-prod.yml`)
4. `application.yml`
5. Configuración local en `/src/main/resources/`

#### Endpoints del Config Server

```bash
# Obtener configuración de un servicio
GET http://localhost:9296/{application}/{profile}

# Ejemplos:
GET http://localhost:9296/order-service/prod
GET http://localhost:9296/api-gateway/dev
GET http://localhost:9296/user-service/default

# Respuesta JSON:
{
  "name": "order-service",
  "profiles": ["prod"],
  "label": "master",
  "version": "abc123",
  "state": null,
  "propertySources": [
    {
      "name": "https://github.com/.../order-service-prod.yml",
      "source": {
        "server.port": 8083,
        "spring.datasource.url": "jdbc:postgresql://..."
      }
    }
  ]
}
```

#### Variables de Entorno

**Sobrescritura de Config Server URL:**
```bash
# Variable de entorno
export SPRING_CONFIG_IMPORT="configserver:http://cloud-config-server:9296"

# Propiedad del sistema
-Dspring.config.import=configserver:http://cloud-config-server:9296

# Docker Compose
environment:
  - SPRING_CONFIG_IMPORT=configserver:http://cloud-config:9296
```

#### Modo Optional

El prefijo `optional:` permite que los servicios inicien sin Config Server:

```yaml
spring:
  config:
    import: optional:configserver:http://localhost:9296
```

- Si Config Server está disponible → carga configuración remota
- Si Config Server no responde → usa configuración local y continúa

#### Servicios Configurados

Todos los microservicios utilizan Config Server:
1. api-gateway
2. order-service
3. payment-service
4. product-service
5. user-service
6. shipping-service
7. favourite-service
8. proxy-client

---

### 1.6 Database per Service Pattern

#### Descripción Técnica
Cada microservicio mantiene su propia base de datos independiente. No existe acceso directo entre bases de datos de diferentes servicios. La comunicación de datos se realiza exclusivamente mediante APIs REST. Se utiliza Flyway para versionado y migración de schemas.

#### Tecnología
- **Base de datos:** PostgreSQL (producción), H2 (desarrollo)
- **ORM:** Spring Data JPA / Hibernate
- **Migración:** Flyway Core 8.x
- **Dependencias:** `spring-boot-starter-data-jpa`, `flyway-core`

#### Implementación por Servicio

**Order Service:**

```xml
<!-- order-service/pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>2.3.232</version>
    <scope>runtime</scope>
</dependency>
```

```yaml
# order-service/src/main/resources/application-dev.yml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    url: jdbc:h2:mem:ecommerce_dev_db
    username: sa
    password:

  jpa:
    hibernate:
      ddl-auto: none
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect
        format_sql: true

  flyway:
    baseline-on-migrate: true
    enabled: true
```

```yaml
# order-service/src/main/resources/application-prod.yml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: ${DB_URL:jdbc:postgresql://localhost:5432/ecommerce_orders_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    hikari:
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      maximum-pool-size: 10

  jpa:
    hibernate:
      ddl-auto: none
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: false

  flyway:
    baseline-on-migrate: true
    enabled: true
```

**Migraciones Flyway (Order Service):**

```
order-service/src/main/resources/db/migration/
├── V1__create_carts_table.sql
├── V2__insert_carts_table.sql
├── V3__create_orders_table.sql
├── V4__insert_orders_table.sql
└── V5__create_orders_cart_id_fk.sql
```

```sql
-- V3__create_orders_table.sql
CREATE TABLE IF NOT EXISTS orders (
    order_id INT NOT NULL AUTO_INCREMENT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_desc VARCHAR(255),
    order_fee DECIMAL(10, 2) NOT NULL,
    cart_id INT NOT NULL,
    PRIMARY KEY (order_id)
);
```

**Product Service:**

```
product-service/src/main/resources/db/migration/
├── V1__create_categories_table.sql
├── V2__insert_categories_table.sql
├── V3__create_products_table.sql
├── V4__insert_products_table.sql
├── V5__create_categories_parent_category_id_fk.sql
└── V6__create_products_category_id_fk.sql
```

**Repository Pattern:**
```java
// order-service/src/main/java/com/selimhorri/app/repository/OrderRepository.java
package com.selimhorri.app.repository;

import com.selimhorri.app.domain.Order;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Integer> {
    // Spring Data JPA genera implementación automáticamente
}
```

#### Schemas de Base de Datos

| Servicio | Base de Datos (Prod) | Tablas Principales |
|----------|----------------------|-------------------|
| order-service | `ecommerce_orders_db` | orders, carts, order_items |
| product-service | `ecommerce_products_db` | products, categories |
| user-service | `ecommerce_users_db` | users, credentials, addresses, verification_tokens |
| payment-service | `ecommerce_payments_db` | payments |
| shipping-service | `ecommerce_shipping_db` | order_items (shipping info) |
| favourite-service | `ecommerce_favourites_db` | favourites |

#### Comunicación entre Servicios

Los servicios NO acceden directamente a bases de datos ajenas. Ejemplo:

```java
// payment-service necesita datos de order-service
@Service
public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepository;  // Propia DB
    private final RestTemplate restTemplate;            // Llamada HTTP

    @Override
    public PaymentDto findById(Integer paymentId) {
        // 1. Consulta propia base de datos
        Payment payment = paymentRepository.findById(paymentId)
            .orElseThrow(...);

        PaymentDto dto = mapper.map(payment);

        // 2. Obtiene datos de order-service via REST API
        OrderDto order = restTemplate.getForObject(
            "http://ORDER-SERVICE/order-service/api/orders/" + dto.getOrderDto().getOrderId(),
            OrderDto.class
        );

        dto.setOrderDto(order);
        return dto;
    }
}
```

#### HikariCP Connection Pool

```yaml
spring:
  datasource:
    hikari:
      connection-timeout: 30000      # 30 segundos max para obtener conexión
      idle-timeout: 600000           # 10 minutos idle antes de cerrar
      max-lifetime: 1800000          # 30 minutos max vida de conexión
      maximum-pool-size: 10          # Máximo 10 conexiones por servicio
      minimum-idle: 5                # Mínimo 5 conexiones idle
```

#### Estrategia de Deployment

**Desarrollo (H2):**
- Base de datos en memoria
- Schema recreado en cada reinicio
- Flyway migrations se ejecutan automáticamente
- Datos de prueba insertados via migrations

**Producción (PostgreSQL):**
- Base de datos persistente por servicio
- Flyway gestiona evolución de schema
- Conexiones pool via HikariCP
- Variables de entorno para credenciales

---

## 2. PATRONES DE OBSERVABILIDAD

### 2.1 Distributed Tracing

#### Descripción Técnica
Implementación de rastreo distribuido utilizando Spring Cloud Sleuth para generación de trace IDs y span IDs, junto con Zipkin para recolección y visualización de trazas. Cada request recibe un trace ID único que se propaga a través de todos los servicios involucrados.

#### Tecnología
- **Framework:** Spring Cloud Sleuth 3.1.x
- **Collector:** Zipkin Server
- **Dependencias:** `spring-cloud-starter-sleuth`, `spring-cloud-sleuth-zipkin`

#### Implementación

**Dependencias (Parent POM):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

**Configuración (api-gateway):**
```yaml
# api-gateway/src/main/resources/application.yml
spring:
  application:
    name: API-GATEWAY
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://localhost:9411/}
  sleuth:
    sampler:
      probability: 1.0
```

**Configuración (order-service):**
```yaml
# order-service/src/main/resources/application.yml
spring:
  application:
    name: ORDER-SERVICE
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://localhost:9411/}
  sleuth:
    sampler:
      probability: 1.0
```

#### Estructura de Trace

**Trace ID:** Identificador único para el request completo
**Span ID:** Identificador único para cada operación dentro del trace

```
[API-GATEWAY,traceId=a1b2c3,spanId=x1y2] → Recibe request
    ↓
[ORDER-SERVICE,traceId=a1b2c3,spanId=x3y4,parentSpanId=x1y2] → Procesa orden
    ↓
[PAYMENT-SERVICE,traceId=a1b2c3,spanId=x5y6,parentSpanId=x3y4] → Procesa pago
    ↓
[SHIPPING-SERVICE,traceId=a1b2c3,spanId=x7y8,parentSpanId=x3y4] → Crea envío
```

#### Propagación de Headers HTTP

Sleuth automáticamente inyecta headers en requests HTTP:

```
X-B3-TraceId: a1b2c3d4e5f6g7h8
X-B3-SpanId: x1y2z3w4
X-B3-ParentSpanId: p1q2r3s4
X-B3-Sampled: 1
```

#### Logging con Trace Context

Sleuth añade trace information a los logs:

```
2025-11-13 10:30:45.123 INFO [API-GATEWAY,a1b2c3,x1y2] 12345 --- [nio-80-exec-1] c.s.a.c.GatewayController : Processing request
2025-11-13 10:30:45.234 INFO [ORDER-SERVICE,a1b2c3,x3y4] 12346 --- [nio-8083-exec-2] c.s.o.s.OrderServiceImpl : Creating order
2025-11-13 10:30:45.345 INFO [PAYMENT-SERVICE,a1b2c3,x5y6] 12347 --- [nio-8084-exec-3] c.s.p.s.PaymentServiceImpl : Processing payment
```

Formato: `[application-name,traceId,spanId]`

#### Sampling

```yaml
spring:
  sleuth:
    sampler:
      probability: 1.0  # 100% de requests son trazados
```

- `probability: 1.0` → Todos los requests
- `probability: 0.1` → 10% de requests (producción para reducir overhead)

#### Zipkin Integration

**Envío de Spans:**
- Sleuth envía spans a Zipkin via HTTP POST
- URL: `http://localhost:9411/api/v2/spans`
- Formato: JSON
- Asíncrono (no bloquea request)

**Zipkin UI:**
```
http://localhost:9411/zipkin/
```

**Query de Traces:**
- Búsqueda por trace ID
- Búsqueda por servicio
- Búsqueda por tag
- Visualización de timeline
- Análisis de latencias

#### Servicios con Tracing

Todos los microservicios tienen Sleuth + Zipkin configurado:
1. api-gateway
2. order-service
3. payment-service
4. product-service
5. user-service
6. shipping-service
7. favourite-service
8. proxy-client
9. service-discovery
10. cloud-config

---

### 2.2 Health Check Pattern

#### Descripción Técnica
Implementación de health checks mediante Spring Boot Actuator. Expone endpoints de salud que reportan el estado del servicio y sus dependencias. Se integra con Kubernetes para liveness y readiness probes. Incluye health indicators de circuit breakers.

#### Tecnología
- **Framework:** Spring Boot Actuator 2.7.x
- **Dependencia:** `spring-boot-starter-actuator`
- **Protocolo:** HTTP/REST

#### Implementación

**Dependencias (Parent POM):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Configuración (api-gateway):**
```yaml
# api-gateway/src/main/resources/application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info,metrics
      base-path: /actuator

  endpoint:
    health:
      show-details: always
      probes:
        enabled: true

  health:
    circuitbreakers:
      enabled: true
```

**Configuración (order-service):**
```yaml
# order-service/src/main/resources/application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info,metrics
      base-path: /actuator

  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
```

#### Endpoints Expuestos

**Base Path:** `/actuator`

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/actuator/health` | GET | Health check completo |
| `/actuator/health/liveness` | GET | Kubernetes liveness probe |
| `/actuator/health/readiness` | GET | Kubernetes readiness probe |
| `/actuator/info` | GET | Información del servicio |
| `/actuator/metrics` | GET | Métricas disponibles |
| `/actuator/prometheus` | GET | Métricas en formato Prometheus |

#### Health Check Response

```bash
GET http://localhost:8083/actuator/health

Response:
{
  "status": "UP",
  "components": {
    "circuitBreakers": {
      "status": "UP",
      "details": {
        "orderService": {
          "status": "UP",
          "details": {
            "failureRate": "0.0%",
            "slowCallRate": "0.0%",
            "bufferedCalls": 5,
            "failedCalls": 0,
            "slowCalls": 0,
            "state": "CLOSED"
          }
        }
      }
    },
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 250790436864,
        "free": 100000000000,
        "threshold": 10485760,
        "exists": true
      }
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

#### Health Indicators Incluidos

**1. Database Health:**
- Valida conexión a base de datos
- Ejecuta query de validación
- Status: UP si conexión exitosa, DOWN si falla

**2. Circuit Breaker Health:**
- Reporta estado de cada circuit breaker
- Incluye métricas (failure rate, call count, state)
- Status: UP si circuito funcional, DOWN si degradado

**3. Disk Space Health:**
- Verifica espacio en disco
- Threshold configurable
- Status: DOWN si espacio < threshold

**4. Ping Health:**
- Health check básico
- Siempre UP si aplicación responde

#### Kubernetes Probes

**Liveness Probe:**
```yaml
# Kubernetes deployment manifest
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8083
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8083
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

**Diferencia:**
- **Liveness:** ¿El pod está vivo? Si falla → restart pod
- **Readiness:** ¿El pod está listo para recibir tráfico? Si falla → remove from service

#### Uso en E2E Tests

```java
// tests/src/test/java/com/selimhorri/app/utils/ServiceHealthCheck.java
@Component
public class ServiceHealthCheck {

    private static final int MAX_RETRIES = 30;
    private static final int RETRY_DELAY = 2000;

    private final RestTemplate restTemplate;

    @Retryable(maxAttempts = MAX_RETRIES, backoff = @Backoff(delay = RETRY_DELAY))
    public boolean waitForService(String serviceUrl) {
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(
                serviceUrl + "/actuator/health",
                String.class
            );
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.warn("Service not ready: {}", serviceUrl);
            throw new RuntimeException("Service health check failed");
        }
    }
}
```

#### Configuración de Seguridad

Por defecto, `/actuator/health` es público. Para proteger otros endpoints:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info  # Solo exponer health e info públicamente
```

#### Servicios con Health Checks

Todos los microservicios implementan health checks:
1. api-gateway (Port 80, path: `/actuator/health`)
2. order-service (Port 8083, path: `/actuator/health`)
3. payment-service (Port 8084, path: `/actuator/health`)
4. product-service (Port 8082, path: `/actuator/health`)
5. user-service (Port 8081, path: `/actuator/health`)
6. shipping-service (Port 8085, path: `/actuator/health`)
7. favourite-service (Port 8086, path: `/actuator/health`)
8. proxy-client (Port 8080, path: `/actuator/health`)
9. service-discovery (Port 8761, path: `/actuator/health`)
10. cloud-config (Port 9296, path: `/actuator/health`)

---

### 2.3 Metrics Collection

#### Descripción Técnica
Implementación de recolección de métricas mediante Micrometer con registro en Prometheus. Exporta métricas de JVM, HTTP requests, conexiones de base de datos, y métricas custom. Prometheus scrapes periódicamente el endpoint `/actuator/prometheus`.

#### Tecnología
- **Framework:** Micrometer 1.9.x
- **Registry:** Prometheus
- **Dependencia:** `micrometer-registry-prometheus`
- **Formato:** Prometheus Text Format

#### Implementación

**Dependencias (Parent POM):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
    <scope>runtime</scope>
</dependency>
```

**Dependencias por Servicio:**
```xml
<!-- order-service/pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
    <scope>runtime</scope>
</dependency>
```

**Configuración (api-gateway):**
```yaml
# api-gateway/src/main/resources/application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info,metrics

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

**Configuración (order-service):**
```yaml
# order-service/src/main/resources/application.yml
management:
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

#### Métricas Exportadas

**1. JVM Metrics:**
```
# Uso de memoria
jvm_memory_used_bytes{area="heap",id="PS Eden Space",application="ORDER-SERVICE"}
jvm_memory_used_bytes{area="nonheap",id="Metaspace",application="ORDER-SERVICE"}

# Garbage Collection
jvm_gc_pause_seconds_count{action="end of minor GC",cause="Allocation Failure"}
jvm_gc_pause_seconds_sum{action="end of minor GC",cause="Allocation Failure"}

# Threads
jvm_threads_live_threads{application="ORDER-SERVICE"}
jvm_threads_daemon_threads{application="ORDER-SERVICE"}
```

**2. HTTP Metrics:**
```
# Total de requests
http_server_requests_seconds_count{
  method="GET",
  uri="/order-service/api/orders",
  status="200",
  application="ORDER-SERVICE"
}

# Suma de latencias
http_server_requests_seconds_sum{
  method="GET",
  uri="/order-service/api/orders",
  status="200",
  application="ORDER-SERVICE"
}

# Histograma de latencias
http_server_requests_seconds_bucket{
  method="GET",
  uri="/order-service/api/orders",
  status="200",
  le="0.005",
  application="ORDER-SERVICE"
}
```

**3. Database Connection Pool Metrics:**
```
# Conexiones activas
hikaricp_connections_active{pool="HikariPool-1",application="ORDER-SERVICE"}

# Conexiones idle
hikaricp_connections_idle{pool="HikariPool-1",application="ORDER-SERVICE"}

# Tiempo de espera por conexión
hikaricp_connections_acquire_seconds_count{pool="HikariPool-1"}
hikaricp_connections_acquire_seconds_sum{pool="HikariPool-1"}
```

**4. Circuit Breaker Metrics:**
```
# Llamadas exitosas
resilience4j_circuitbreaker_calls_seconds_count{
  kind="successful",
  name="orderService",
  application="ORDER-SERVICE"
}

# Llamadas fallidas
resilience4j_circuitbreaker_calls_seconds_count{
  kind="failed",
  name="orderService",
  application="ORDER-SERVICE"
}

# Estado del circuit breaker
resilience4j_circuitbreaker_state{
  name="orderService",
  state="closed",
  application="ORDER-SERVICE"
} 1.0
```

**5. Tomcat Metrics:**
```
# Threads activos
tomcat_threads_busy_threads{application="ORDER-SERVICE"}

# Requests procesados
tomcat_sessions_created_sessions_total{application="ORDER-SERVICE"}
```

#### Endpoint de Métricas

```bash
# Formato Prometheus
GET http://localhost:8083/actuator/prometheus

Response (text/plain):
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{area="heap",id="PS Eden Space",application="ORDER-SERVICE",} 2.5165824E7

# HELP http_server_requests_seconds
# TYPE http_server_requests_seconds summary
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/order-service/api/orders",application="ORDER-SERVICE",} 42.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/order-service/api/orders",application="ORDER-SERVICE",} 1.234567
```

#### Percentile Histograms

Configuración para generar histogramas de latencia:

```yaml
management:
  metrics:
    distribution:
      percentiles-histogram:
        http.server.requests: true
```

Esto genera buckets para calcular percentiles (p50, p90, p95, p99):

```
http_server_requests_seconds_bucket{le="0.001"} 10
http_server_requests_seconds_bucket{le="0.002"} 25
http_server_requests_seconds_bucket{le="0.005"} 35
http_server_requests_seconds_bucket{le="0.01"} 40
http_server_requests_seconds_bucket{le="0.025"} 41
http_server_requests_seconds_bucket{le="+Inf"} 42
```

#### Tags Comunes

Todas las métricas incluyen el tag `application`:

```yaml
management:
  metrics:
    tags:
      application: ${spring.application.name}
```

Esto permite filtrar en Prometheus:

```promql
# Métricas solo de ORDER-SERVICE
http_server_requests_seconds_count{application="ORDER-SERVICE"}

# Métricas de todos los servicios
http_server_requests_seconds_count
```

#### Prometheus Scrape Configuration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'spring-boot-services'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets:
        - 'api-gateway:80'
        - 'order-service:8083'
        - 'payment-service:8084'
        - 'product-service:8082'
        - 'user-service:8081'
        - 'shipping-service:8085'
        - 'favourite-service:8086'
        - 'proxy-client:8080'
    scrape_interval: 15s
```

#### Queries PromQL Útiles

```promql
# Tasa de requests por segundo
rate(http_server_requests_seconds_count[5m])

# Latencia promedio (últimos 5 minutos)
rate(http_server_requests_seconds_sum[5m]) / rate(http_server_requests_seconds_count[5m])

# P95 de latencia
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Tasa de errores (status 5xx)
rate(http_server_requests_seconds_count{status=~"5.."}[5m])

# Memoria heap usada
jvm_memory_used_bytes{area="heap"}

# Circuit breakers abiertos
resilience4j_circuitbreaker_state{state="open"}
```

#### Servicios con Metrics Export

Todos los microservicios exportan métricas a Prometheus:
1. api-gateway
2. order-service
3. payment-service
4. product-service
5. user-service
6. shipping-service
7. favourite-service
8. proxy-client
9. service-discovery
10. cloud-config

---

## 3. PATRONES DE SEGURIDAD

### 3.1 JWT Authentication & Authorization

#### Descripción Técnica
Implementación de autenticación stateless mediante JSON Web Tokens (JWT). El servicio proxy-client actúa como gateway de autenticación, validando credenciales y generando tokens. Los tokens se transmiten en el header `Authorization: Bearer <token>`. Spring Security valida tokens en cada request mediante un filtro personalizado.

#### Tecnología
- **Library:** JJWT 0.9.1
- **Framework:** Spring Security 5.7.x
- **Algoritmo:** HS512 (HMAC-SHA512)
- **Session Management:** Stateless

#### Implementación

**Dependencias:**
```xml
<!-- proxy-client/pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt</artifactId>
    <version>0.9.1</version>
</dependency>
```

**JWT Service:**
```java
// proxy-client/src/main/java/com/selimhorri/app/jwt/service/JwtService.java
package com.selimhorri.app.jwt.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    @Value("${app.jwt.secret-key}")
    private String secretKey;

    @Value("${app.jwt.expiration-in-ms}")
    private Long expirationInMs;

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
            .setSigningKey(secretKey)
            .parseClaimsJws(token)
            .getBody();
    }

    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public String generateToken(String username) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, username);
    }

    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
            .setClaims(claims)
            .setSubject(subject)
            .setIssuedAt(new Date(System.currentTimeMillis()))
            .setExpiration(new Date(System.currentTimeMillis() + expirationInMs))
            .signWith(SignatureAlgorithm.HS512, secretKey)
            .compact();
    }

    public Boolean validateToken(String token, String username) {
        final String extractedUsername = extractUsername(token);
        return (extractedUsername.equals(username) && !isTokenExpired(token));
    }
}
```

**Configuración:**
```yaml
# proxy-client/src/main/resources/application.yml
app:
  jwt:
    secret-key: ${JWT_SECRET_KEY:mySecretKey1234567890123456789012345678901234567890}
    expiration-in-ms: 86400000  # 24 horas
```

**JWT Request Filter:**
```java
// proxy-client/src/main/java/com/selimhorri/app/config/filter/JwtRequestFilter.java
package com.selimhorri.app.config.filter;

import com.selimhorri.app.jwt.service.JwtService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component
public class JwtRequestFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    public JwtRequestFilter(JwtService jwtService, UserDetailsService userDetailsService) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authorizationHeader = request.getHeader("Authorization");

        String username = null;
        String jwt = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            username = jwtService.extractUsername(jwt);
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);

            if (jwtService.validateToken(jwt, userDetails.getUsername())) {
                UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(
                        userDetails,
                        null,
                        userDetails.getAuthorities()
                    );

                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        filterChain.doFilter(request, response);
    }
}
```

**Security Configuration:**
```java
// proxy-client/src/main/java/com/selimhorri/app/security/SecurityConfig.java
package com.selimhorri.app.security;

import com.selimhorri.app.config.filter.JwtRequestFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    private final JwtRequestFilter jwtRequestFilter;

    public SecurityConfig(JwtRequestFilter jwtRequestFilter) {
        this.jwtRequestFilter = jwtRequestFilter;
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeRequests()
                .antMatchers("/app/api/authenticate", "/app/api/register").permitAll()
                .anyRequest().authenticated()
            .and()
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS);

        http.addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }
}
```

**Authentication Service:**
```java
// proxy-client/src/main/java/com/selimhorri/app/business/auth/service/AuthenticationService.java
@Service
public class AuthenticationService {

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final CredentialClientService credentialClientService;

    public AuthenticationResponseDto authenticate(AuthenticationRequestDto requestDto) {
        // 1. Autenticar credenciales
        authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                requestDto.getUsername(),
                requestDto.getPassword()
            )
        );

        // 2. Obtener detalles del usuario
        CredentialDto credential = credentialClientService
            .findByUsername(requestDto.getUsername());

        // 3. Generar JWT token
        String jwtToken = jwtService.generateToken(requestDto.getUsername());

        // 4. Retornar respuesta con token
        return AuthenticationResponseDto.builder()
            .jwtToken(jwtToken)
            .username(requestDto.getUsername())
            .build();
    }
}
```

#### Flujo de Autenticación

**1. Login:**
```
POST /app/api/authenticate
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password123"
}

Response:
{
  "jwtToken": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIiwiaWF0IjoxNjg...",
  "username": "user@example.com"
}
```

**2. Request Autorizado:**
```
GET /app/api/orders
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIiwiaWF0IjoxNjg...

→ JwtRequestFilter extrae token
→ Valida firma con secretKey
→ Valida expiración
→ Carga UserDetails
→ Establece Authentication en SecurityContext
→ Request procede a controller
```

**3. Request No Autorizado:**
```
GET /app/api/orders
(Sin header Authorization)

→ JwtRequestFilter detecta ausencia de token
→ SecurityContext queda sin Authentication
→ Spring Security retorna 401 Unauthorized
```

#### Estructura del JWT Token

**Header:**
```json
{
  "alg": "HS512",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "sub": "user@example.com",
  "iat": 1700000000,
  "exp": 1700086400
}
```

**Signature:**
```
HMACSHA512(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secretKey
)
```

#### Endpoints Públicos vs Protegidos

**Públicos (sin autenticación):**
- `POST /app/api/authenticate` - Login
- `POST /app/api/register` - Registro

**Protegidos (requieren JWT):**
- Todos los demás endpoints bajo `/app/api/**`

---

### 3.2 Authorization Header Propagation

#### Descripción Técnica
Implementación de interceptores HTTP para propagar el header `Authorization` en llamadas service-to-service. Cada servicio que realiza llamadas REST a otros servicios utiliza un interceptor que copia el header de autenticación del request entrante y lo añade al request saliente.

#### Tecnología
- **Framework:** Spring RestTemplate Interceptor
- **Interface:** `ClientHttpRequestInterceptor`

#### Implementación

**Interceptor (order-service):**
```java
// order-service/src/main/java/com/selimhorri/app/config/interceptor/AuthorizationHeaderInterceptor.java
package com.selimhorri.app.config.interceptor;

import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

@Component
public class AuthorizationHeaderInterceptor implements ClientHttpRequestInterceptor {

    private static final String AUTHORIZATION_HEADER = "Authorization";

    @Override
    public ClientHttpResponse intercept(HttpRequest request,
                                        byte[] body,
                                        ClientHttpRequestExecution execution)
            throws IOException {

        ServletRequestAttributes attributes =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

        if (attributes != null) {
            HttpServletRequest httpRequest = attributes.getRequest();
            String authHeader = httpRequest.getHeader(AUTHORIZATION_HEADER);

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                request.getHeaders().set(AUTHORIZATION_HEADER, authHeader);
            }
        }

        return execution.execute(request, body);
    }
}
```

**Configuración RestTemplate:**
```java
// order-service/src/main/java/com/selimhorri/app/config/client/ClientConfig.java
package com.selimhorri.app.config.client;

import com.selimhorri.app.config.interceptor.AuthorizationHeaderInterceptor;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

@Configuration
public class ClientConfig {

    private final AuthorizationHeaderInterceptor authorizationHeaderInterceptor;

    public ClientConfig(AuthorizationHeaderInterceptor authorizationHeaderInterceptor) {
        this.authorizationHeaderInterceptor = authorizationHeaderInterceptor;
    }

    @LoadBalanced
    @Bean
    public RestTemplate restTemplateBean() {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.setInterceptors(
            Collections.singletonList(authorizationHeaderInterceptor)
        );
        return restTemplate;
    }
}
```

#### Flujo de Propagación

```
Client
  ↓ (Authorization: Bearer token123)
API Gateway (Port 80)
  ↓ (Authorization: Bearer token123)
Proxy Client (Port 8080)
  ↓ (Authorization: Bearer token123)
Order Service (Port 8083)
  ↓
  |- Recibe request con Authorization header
  |- RequestContextHolder captura header
  |- Al hacer llamada REST a otro servicio:
  |    RestTemplate.getForObject("http://PAYMENT-SERVICE/...")
  ↓
AuthorizationHeaderInterceptor
  ↓
  |- Extrae header del RequestContext
  |- Añade header al outgoing request
  ↓ (Authorization: Bearer token123)
Payment Service (Port 8084)
  ↓
  |- Recibe request con Authorization header propagado
  |- Puede validar el token si es necesario
```

#### RequestContextHolder

Spring mantiene el contexto del request actual en un ThreadLocal:

```java
ServletRequestAttributes attributes =
    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

HttpServletRequest httpRequest = attributes.getRequest();
String authHeader = httpRequest.getHeader("Authorization");
```

Esto permite acceder al header original incluso desde capas profundas de la aplicación.

#### Servicios con Header Propagation

Implementado en todos los servicios que realizan llamadas REST:
1. order-service → llama a payment-service, shipping-service
2. payment-service → llama a order-service
3. product-service → llamadas internas
4. shipping-service → llama a order-service
5. favourite-service → llama a user-service, product-service
6. user-service → no realiza llamadas externas

---

## 4. PATRONES DE INFRAESTRUCTURA

### 4.1 Containerization Pattern

#### Descripción Técnica
Cada microservicio se empaqueta como imagen Docker utilizando multi-stage builds. Las imágenes se construyen con Maven como build stage y JRE como runtime stage para minimizar tamaño. Las imágenes se publican en Docker Hub y se despliegan en Kubernetes DigitalOcean.

#### Tecnología
- **Container Runtime:** Docker 20.x
- **Orchestrator:** Kubernetes 1.31.9
- **Registry:** Docker Hub
- **Base Images:** Eclipse Temurin JDK 11 / JRE 11

#### Implementación

**Dockerfile (order-service):**
```dockerfile
# order-service/Dockerfile
FROM maven:3.8.6-eclipse-temurin-11 AS build
WORKDIR /app

# Copy parent POM
COPY pom.xml ./
COPY proxy-client/pom.xml ./proxy-client/
COPY order-service/pom.xml ./order-service/

# Download dependencies (cacheable layer)
RUN mvn dependency:go-offline -B -pl order-service -am

# Copy source code
COPY proxy-client/src ./proxy-client/src
COPY order-service/src ./order-service/src

# Build JAR
RUN mvn clean package -DskipTests -pl order-service -am

# Runtime stage
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /app/order-service/target/order-service-v0.1.0.jar app.jar

# Expose port
EXPOSE 8083

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Docker Compose (Desarrollo):**
```yaml
# docker-compose.yml
version: '3.8'

services:
  service-discovery:
    build:
      context: .
      dockerfile: service-discovery/Dockerfile
    ports:
      - "8761:8761"
    environment:
      - SPRING_PROFILES_ACTIVE=dev

  cloud-config:
    build:
      context: .
      dockerfile: cloud-config/Dockerfile
    ports:
      - "9296:9296"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - EUREKA_SERVER_URL=http://service-discovery:8761/eureka/

  order-service:
    build:
      context: .
      dockerfile: order-service/Dockerfile
    ports:
      - "8083:8083"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - EUREKA_SERVER_URL=http://service-discovery:8761/eureka/
      - SPRING_CONFIG_IMPORT=configserver:http://cloud-config:9296
    depends_on:
      - service-discovery
      - cloud-config
```

**GitHub Actions Build:**
```yaml
# .github/workflows/build.yml
- name: Build Docker image
  run: |
    docker build \
      -t ${{ github.event.inputs.docker_user }}/order-service:${VERSION_TAG} \
      -f order-service/Dockerfile \
      .

- name: Push Docker image
  run: |
    echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ github.event.inputs.docker_user }}" --password-stdin
    docker push ${{ github.event.inputs.docker_user }}/order-service:${VERSION_TAG}
    docker tag ${{ github.event.inputs.docker_user }}/order-service:${VERSION_TAG} \
               ${{ github.event.inputs.docker_user }}/order-service:latest
    docker push ${{ github.event.inputs.docker_user }}/order-service:latest
```

#### Kubernetes Deployment

**Deployment Manifest (order-service):**
```yaml
# infrastructure/kubernetes/base/order-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: order-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: luisrojasc/order-service:latest
        ports:
        - containerPort: 8083
          name: http
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: EUREKA_SERVER_URL
          value: "http://service-discovery:8761/eureka/"
        - name: SPRING_CONFIG_IMPORT
          value: "configserver:http://cloud-config:9296"
        - name: DB_URL
          value: "jdbc:postgresql://postgresql:5432/ecommerce_orders_db"
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8083
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8083
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  labels:
    app: order-service
spec:
  type: ClusterIP
  ports:
  - port: 8083
    targetPort: 8083
    protocol: TCP
    name: http
  selector:
    app: order-service
```

#### Multi-Stage Build Benefits

**Separación Build / Runtime:**
- Build stage: Maven + JDK (>500MB)
- Runtime stage: JRE Alpine (~200MB)
- Reducción: ~60% tamaño imagen

**Dependency Caching:**
```dockerfile
# Capa cacheable - solo se rebuilds si POMs cambian
RUN mvn dependency:go-offline -B

# Capa con código fuente - rebuilds en cada cambio
COPY src ./src
RUN mvn clean package
```

#### Imágenes Publicadas

Registry: `docker.io/luisrojasc`

| Servicio | Imagen | Tamaño |
|----------|--------|--------|
| api-gateway | luisrojasc/api-gateway:latest | ~250MB |
| order-service | luisrojasc/order-service:latest | ~280MB |
| payment-service | luisrojasc/payment-service:latest | ~280MB |
| product-service | luisrojasc/product-service:latest | ~280MB |
| user-service | luisrojasc/user-service:latest | ~280MB |
| shipping-service | luisrojasc/shipping-service:latest | ~280MB |
| favourite-service | luisrojasc/favourite-service:latest | ~280MB |
| proxy-client | luisrojasc/proxy-client:latest | ~300MB |
| service-discovery | luisrojasc/service-discovery:latest | ~250MB |
| cloud-config | luisrojasc/cloud-config:latest | ~250MB |

#### Kubernetes Cluster

**Provider:** DigitalOcean Kubernetes (DOKS)
**Version:** 1.31.9-do.5
**Nodes:** 3x s-4vcpu-8gb (24GB RAM total)
**Namespaces:**
- `prod` - Producción
- `dev` - Desarrollo
- `monitoring` - Prometheus, Grafana, Alertmanager
- `tracing` - Zipkin (referenciado)

---

### 4.2 Environment-Based Configuration

#### Descripción Técnica
Configuración multi-ambiente mediante Spring Profiles. Cada servicio tiene múltiples archivos `application-{profile}.yml` con configuraciones específicas de entorno. Los perfiles se activan mediante variable de entorno `SPRING_PROFILES_ACTIVE`. Se integra con Config Server para sobrescritura centralizada.

#### Tecnología
- **Framework:** Spring Boot Profiles 2.7.x
- **Activation:** Environment variable `SPRING_PROFILES_ACTIVE`
- **Precedence:** Config Server > Profile-specific > Default

#### Implementación

**Estructura de Archivos (order-service):**
```
order-service/src/main/resources/
├── application.yml              # Configuración base
├── application-dev.yml          # Desarrollo (H2, debug logging)
├── application-prod.yml         # Producción (PostgreSQL, minimal logging)
├── application-stage.yml        # Staging (PostgreSQL, moderate logging)
├── application-default.yml      # Fallback configuration
└── application-e2e.yml          # End-to-end tests
```

**application.yml (Base):**
```yaml
# order-service/src/main/resources/application.yml
spring:
  application:
    name: ORDER-SERVICE
  config:
    import: ${SPRING_CONFIG_IMPORT:optional:configserver:http://localhost:9296}

server:
  port: 8083

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_SERVER_URL:http://localhost:8761/eureka/}
  instance:
    prefer-ip-address: true
```

**application-dev.yml:**
```yaml
# order-service/src/main/resources/application-dev.yml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    url: jdbc:h2:mem:ecommerce_dev_db
    username: sa
    password:

  h2:
    console:
      enabled: true
      path: /h2-console

  jpa:
    hibernate:
      ddl-auto: none
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect
        format_sql: true

  flyway:
    baseline-on-migrate: true
    enabled: true

logging:
  level:
    root: INFO
    com.selimhorri.app: DEBUG
    org.hibernate.SQL: DEBUG
    org.springframework.web: DEBUG
```

**application-prod.yml:**
```yaml
# order-service/src/main/resources/application-prod.yml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: ${DB_URL:jdbc:postgresql://localhost:5432/ecommerce_orders_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    hikari:
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      maximum-pool-size: 10
      minimum-idle: 5

  jpa:
    hibernate:
      ddl-auto: none
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: false

  flyway:
    baseline-on-migrate: true
    enabled: true

logging:
  level:
    root: WARN
    com.selimhorri.app: INFO
```

**application-e2e.yml:**
```yaml
# order-service/src/main/resources/application-e2e.yml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    url: jdbc:h2:mem:ecommerce_e2e_db
    username: sa
    password:

  jpa:
    hibernate:
      ddl-auto: create-drop

  flyway:
    enabled: false

logging:
  level:
    root: ERROR
    com.selimhorri.app: INFO
```

#### Activación de Profiles

**Variable de Entorno:**
```bash
export SPRING_PROFILES_ACTIVE=prod
java -jar order-service.jar
```

**System Property:**
```bash
java -Dspring.profiles.active=prod -jar order-service.jar
```

**Docker:**
```dockerfile
ENV SPRING_PROFILES_ACTIVE=prod
```

**Docker Compose:**
```yaml
environment:
  - SPRING_PROFILES_ACTIVE=prod
```

**Kubernetes:**
```yaml
env:
- name: SPRING_PROFILES_ACTIVE
  value: "prod"
```

#### Precedencia de Configuración

**Orden (mayor a menor prioridad):**
1. Variables de entorno (ej: `DB_URL`)
2. Config Server properties (`order-service-prod.yml` en Git)
3. Local profile-specific (`application-prod.yml`)
4. Local default (`application.yml`)

**Ejemplo de sobrescritura:**
```yaml
# application.yml
server:
  port: 8083

# application-prod.yml
server:
  port: 8083

# Environment variable
export SERVER_PORT=9000

# Resultado: port 9000 (env var gana)
```

#### Profile-Specific Beans

```java
@Configuration
@Profile("dev")
public class DevConfig {

    @Bean
    public DataSource dataSource() {
        // H2 in-memory datasource
        return new EmbeddedDatabaseBuilder()
            .setType(EmbeddedDatabaseType.H2)
            .build();
    }
}

@Configuration
@Profile("prod")
public class ProdConfig {

    @Bean
    public DataSource dataSource() {
        // PostgreSQL datasource con connection pooling
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(dbUrl);
        config.setMaximumPoolSize(10);
        return new HikariDataSource(config);
    }
}
```

#### Configuración por Ambiente

| Característica | dev | prod | e2e |
|---------------|-----|------|-----|
| Database | H2 (memory) | PostgreSQL | H2 (memory) |
| Logging Level | DEBUG | INFO/WARN | ERROR |
| SQL Logging | Enabled | Disabled | Disabled |
| H2 Console | Enabled | Disabled | Disabled |
| Flyway | Enabled | Enabled | Disabled |
| DDL Auto | none | none | create-drop |
| Connection Pool | Default | HikariCP | Default |

---

### 4.3 Database Migration Pattern

#### Descripción Técnica
Gestión de evolución de schema mediante Flyway. Las migraciones se definen como scripts SQL versionados con nomenclatura `V{version}__{description}.sql`. Flyway ejecuta scripts en orden secuencial y mantiene historial en tabla `flyway_schema_history`. Implementado en todos los servicios con base de datos propia.

#### Tecnología
- **Framework:** Flyway Core 8.x
- **Dependencia:** `flyway-core`
- **Naming Convention:** `V{version}__{description}.sql`

#### Implementación

**Dependencias:**
```xml
<!-- order-service/pom.xml -->
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
```

**Configuración:**
```yaml
# order-service/src/main/resources/application.yml
spring:
  flyway:
    baseline-on-migrate: true
    enabled: true
    locations: classpath:db/migration
    baseline-version: 0
```

**Estructura de Migraciones:**
```
order-service/src/main/resources/db/migration/
├── V1__create_carts_table.sql
├── V2__insert_carts_table.sql
├── V3__create_orders_table.sql
├── V4__insert_orders_table.sql
└── V5__create_orders_cart_id_fk.sql
```

**Migración V1:**
```sql
-- order-service/src/main/resources/db/migration/V1__create_carts_table.sql
CREATE TABLE IF NOT EXISTS carts (
    cart_id INT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (cart_id)
);
```

**Migración V2:**
```sql
-- order-service/src/main/resources/db/migration/V2__insert_carts_table.sql
INSERT INTO carts (cart_id) VALUES
    (1),
    (2),
    (3),
    (4),
    (5);
```

**Migración V3:**
```sql
-- order-service/src/main/resources/db/migration/V3__create_orders_table.sql
CREATE TABLE IF NOT EXISTS orders (
    order_id INT NOT NULL AUTO_INCREMENT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_desc VARCHAR(255),
    order_fee DECIMAL(10, 2) NOT NULL,
    cart_id INT NOT NULL,
    PRIMARY KEY (order_id)
);
```

**Migración V5:**
```sql
-- order-service/src/main/resources/db/migration/V5__create_orders_cart_id_fk.sql
ALTER TABLE orders
ADD CONSTRAINT orders_cart_id_fk
FOREIGN KEY (cart_id)
REFERENCES carts (cart_id)
ON DELETE CASCADE
ON UPDATE CASCADE;
```

#### Product Service Migrations

```
product-service/src/main/resources/db/migration/
├── V1__create_categories_table.sql
├── V2__insert_categories_table.sql
├── V3__create_products_table.sql
├── V4__insert_products_table.sql
├── V5__create_categories_parent_category_id_fk.sql
└── V6__create_products_category_id_fk.sql
```

**V1 - Tabla Categories:**
```sql
-- V1__create_categories_table.sql
CREATE TABLE IF NOT EXISTS categories (
    category_id INT NOT NULL AUTO_INCREMENT,
    category_title VARCHAR(255) NOT NULL,
    category_image_url VARCHAR(500),
    parent_category_id INT,
    PRIMARY KEY (category_id)
);
```

**V3 - Tabla Products:**
```sql
-- V3__create_products_table.sql
CREATE TABLE IF NOT EXISTS products (
    product_id INT NOT NULL AUTO_INCREMENT,
    product_title VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    sku VARCHAR(100) UNIQUE NOT NULL,
    price_unit DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id)
);
```

**V6 - Foreign Key:**
```sql
-- V6__create_products_category_id_fk.sql
ALTER TABLE products
ADD CONSTRAINT products_category_id_fk
FOREIGN KEY (category_id)
REFERENCES categories (category_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;
```

#### Tabla de Historial Flyway

Flyway crea automáticamente `flyway_schema_history`:

```sql
SELECT * FROM flyway_schema_history;

+----------------+---------+----------------------------+----------+---------------------+
| installed_rank | version | description                | type     | installed_on        |
+----------------+---------+----------------------------+----------+---------------------+
|              1 | 1       | create carts table         | SQL      | 2025-11-13 10:00:00 |
|              2 | 2       | insert carts table         | SQL      | 2025-11-13 10:00:01 |
|              3 | 3       | create orders table        | SQL      | 2025-11-13 10:00:02 |
|              4 | 4       | insert orders table        | SQL      | 2025-11-13 10:00:03 |
|              5 | 5       | create orders cart id fk   | SQL      | 2025-11-13 10:00:04 |
+----------------+---------+----------------------------+----------+---------------------+
```

#### Baseline on Migrate

```yaml
spring:
  flyway:
    baseline-on-migrate: true
    baseline-version: 0
```

- Permite ejecutar Flyway sobre base de datos existente
- Marca versión base como `0`
- Solo ejecuta migraciones posteriores a baseline

#### Naming Convention

**Formato obligatorio:** `V{version}__{description}.sql`

- `V` - Prefijo obligatorio (mayúscula)
- `{version}` - Número entero secuencial (1, 2, 3...)
- `__` - Doble underscore separador
- `{description}` - Snake_case descripción
- `.sql` - Extensión obligatoria

**Válidos:**
- `V1__create_table.sql`
- `V2__add_column.sql`
- `V10__update_constraints.sql`

**Inválidos:**
- `v1__create_table.sql` (v minúscula)
- `V1_create_table.sql` (un solo underscore)
- `V1.1__create_table.sql` (versión decimal)

#### Ejecución de Migraciones

**Al iniciar aplicación:**
1. Spring Boot detecta Flyway en classpath
2. Flyway escanea `classpath:db/migration`
3. Compara scripts con `flyway_schema_history`
4. Ejecuta scripts pendientes en orden
5. Registra ejecuciones en historial
6. Aplicación continúa iniciando

**Fallo en migración:**
- Aplicación no inicia
- Migración fallida se marca con `success = false`
- Debe corregirse script y reiniciar

#### Rollback

Flyway Community Edition NO soporta rollback automático. Opciones:

**1. Nueva migración para revertir:**
```sql
-- V6__drop_column.sql revierte V5__add_column.sql
ALTER TABLE orders DROP COLUMN new_column;
```

**2. Flyway Teams (paid):**
```sql
-- U5__undo_add_column.sql
ALTER TABLE orders DROP COLUMN new_column;
```

#### Servicios con Flyway

| Servicio | Migraciones | Tablas Gestionadas |
|----------|-------------|-------------------|
| order-service | 5 scripts | carts, orders |
| product-service | 6 scripts | categories, products |
| user-service | ~10 scripts | users, credentials, addresses, verification_tokens |
| payment-service | ~4 scripts | payments |
| shipping-service | ~3 scripts | order_items |
| favourite-service | ~3 scripts | favourites |

---

## RESUMEN EJECUTIVO

### Clasificación de Patrones Implementados

#### 🎯 Patrones Implementados EXPLÍCITAMENTE por el Equipo (Valor Académico Alto)

**Microservicios Avanzados (5):**
1. ✅ **Service Registry & Discovery** (Netflix Eureka) - Implementación explícita adicional al DNS de K8s
2. ✅ **API Gateway** (Spring Cloud Gateway) - Código y configuración custom
3. ✅ **Circuit Breaker** (Resilience4j) - Configuración detallada en cada servicio
4. ✅ **External Configuration** (Spring Cloud Config Server) - Servidor desplegado + Git backend
5. ✅ **Database per Service** (PostgreSQL/H2 + Flyway) - Diseño arquitectónico consciente

**Observabilidad (2):**
1. ✅ **Distributed Tracing** (Spring Cloud Sleuth + Zipkin) - Instrumentación explícita
2. ✅ **Metrics Collection** (Micrometer + Prometheus) - Exportación configurada

**Seguridad (2):**
1. ✅ **JWT Authentication** (JJWT + Spring Security) - Código completo desarrollado
2. ✅ **Authorization Header Propagation** - Interceptor custom implementado

**Infraestructura (2):**
1. ✅ **Environment-Based Configuration** (Spring Profiles) - Múltiples archivos por servicio
2. ✅ **Database Migration** (Flyway) - Scripts versionados en cada servicio

**Subtotal:** **11 patrones con implementación explícita**

---

#### ⚙️ Patrones que Aprovechan Capacidades de DigitalOcean/Kubernetes (Valor Académico Medio)

**Patrones Híbridos (Configuración + Infraestructura Gestionada):**

1. **Load Balancing** (Spring Cloud LoadBalancer + DO Load Balancer)
   - **Implementado por equipo:**
     - `@LoadBalanced` en RestTemplate (client-side load balancing)
     - Configuración de eager loading
   - **Provisto por DO/K8s:**
     - Load Balancer externo (tipo LoadBalancer service)
     - Kube-proxy IPVS/iptables balancing
   - **Conclusión:** ⚠️ **Híbrido** - Hay código explícito pero aprovecha infraestructura

2. **Health Checks** (Spring Actuator + K8s Probes)
   - **Implementado por equipo:**
     - Endpoints `/actuator/health`, `/actuator/health/liveness`, `/actuator/health/readiness`
     - Health indicators custom (Circuit Breaker, DB)
     - Configuración `show-details: always`
   - **Provisto por DO/K8s:**
     - Liveness/Readiness probe mechanism
     - Restart/Remove from service logic
   - **Conclusión:** ⚠️ **Híbrido** - Health indicators son custom, mecanismo de probing es K8s

3. **Containerization** (Docker + DigitalOcean Kubernetes)
   - **Implementado por equipo:**
     - Dockerfiles multi-stage por servicio
     - Manifiestos K8s (Deployments, Services, Ingress)
     - GitHub Actions CI/CD
   - **Provisto por DO/K8s:**
     - Cluster Kubernetes gestionado
     - Nodos, networking, storage
     - Auto-healing, scheduling
   - **Conclusión:** ⚠️ **Híbrido** - Dockerfiles y manifiestos son custom, cluster es gestionado

**Subtotal:** **3 patrones híbridos**

---

#### ❌ Patrones que Vienen "Gratis" con K8s (Sin Implementación Explícita)

1. **Service Discovery Básico de Kubernetes**
   - DNS automático: `http://service-name.namespace.svc.cluster.local`
   - CoreDNS provisto por K8s
   - **Nota:** SÍ implementamos Eureka como capa adicional, pero K8s ya tiene service discovery

2. **Self-Healing**
   - Restart de pods fallidos
   - Reemplazo de nodos unhealthy
   - **No requirió implementación del equipo**

3. **Horizontal Pod Autoscaling (HPA)**
   - Capacidad presente pero **NO configurada** en manifiestos
   - **No se está usando activamente**

4. **Network Policies**
   - Capacidad presente pero **NO configurada**
   - Cluster sin network policies custom

5. **Secrets Management**
   - K8s Secrets usado para credenciales DB
   - **Configuración mínima**, no hay rotación automática ni integración con vault

---

### 📊 Conteo Real para Proyecto Académico

#### Patrones con ALTA Evidencia de Implementación (11):
1. Service Registry & Discovery (Eureka)
2. API Gateway (Spring Cloud Gateway)
3. Circuit Breaker (Resilience4j)
4. External Configuration (Spring Cloud Config)
5. Database per Service
6. Distributed Tracing (Sleuth + Zipkin)
7. Metrics Collection (Micrometer + Prometheus)
8. JWT Authentication
9. Authorization Header Propagation
10. Environment-Based Configuration (Spring Profiles)
11. Database Migration (Flyway)

#### Patrones con MEDIA Evidencia (Híbridos) (3):
1. Load Balancing (Client-side + Infrastructure)
2. Health Checks (Actuator + K8s Probes)
3. Containerization (Dockerfiles + DO K8s)

#### Total Justificable Académicamente: **11-14 patrones**
- **Conservador:** 11 patrones (solo explícitos)
- **Moderado:** 14 patrones (incluyendo híbridos con configuración significativa)

### Tecnologías Base

- **Spring Boot:** 2.7.18
- **Spring Cloud:** 2021.0.9
- **Java:** 11
- **Kubernetes:** 1.31.9
- **PostgreSQL:** 15.x
- **Docker:** 20.x

### Métricas del Sistema

- **Microservicios:** 10
- **Líneas de Código:** ~30,000
- **Archivos Java:** 301
- **Endpoints REST:** ~50
- **Tablas de Base de Datos:** ~20
- **Migraciones Flyway:** ~30
- **Dockerfiles:** 10 (multi-stage custom builds)
- **Manifiestos K8s:** 25+ (Deployments, Services, Ingress custom)

### Evidencia de Implementación por Patrón

| Patrón | Tipo de Evidencia | Archivos Clave | Líneas de Código |
|--------|-------------------|----------------|------------------|
| Service Registry | Código + Config | `ServiceDiscoveryApplication.java`, `application.yml` × 10 servicios | ~500 |
| API Gateway | Código + Config | `ApiGatewayApplication.java`, rutas configuradas | ~800 |
| Circuit Breaker | Config | `application.yml` × 10 servicios (resilience4j) | ~200 |
| External Config | Código + Servidor | `CloudConfigApplication.java`, Git repo | ~300 |
| DB per Service | Arquitectura | Schemas separados, repositories | ~2,000 |
| Distributed Tracing | Config | `application.yml` (sleuth/zipkin) × 10 | ~100 |
| Metrics Collection | Config | `application.yml` (micrometer) × 10 | ~100 |
| JWT Auth | Código | `JwtService.java`, `JwtRequestFilter.java`, `SecurityConfig.java` | ~600 |
| Auth Propagation | Código | `AuthorizationHeaderInterceptor.java` × 7 servicios | ~350 |
| Spring Profiles | Config | `application-{profile}.yml` × 10 servicios × 4 perfiles | ~4,000 |
| Flyway Migration | Scripts SQL | `V1__*.sql` a `V6__*.sql` × 6 servicios | ~1,500 |
| **TOTAL EXPLÍCITO** | | | **~10,450 LOC**|

---

## 5. PATRONES PARCIALMENTE IMPLEMENTADOS

### 5.1 Retry Pattern

#### Descripción Técnica
Patrón de reintento implementado parcialmente en tests E2E para health checks. Utiliza Spring Retry con anotación `@Retryable` para reintentar operaciones que fallan temporalmente. Actualmente NO está implementado en la comunicación service-to-service de producción.

#### Tecnología
- **Framework:** Spring Retry (en tests)
- **Anotación:** `@Retryable`
- **Estado:** Parcialmente implementado (solo en tests)

#### Implementación Actual

**ServiceHealthCheck (E2E Tests):**
```java
// tests/src/test/java/com/selimhorri/app/utils/ServiceHealthCheck.java
package com.selimhorri.app.utils;

import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class ServiceHealthCheck {

    private static final int MAX_RETRIES = 30;
    private static final int RETRY_DELAY = 2000;

    private final RestTemplate restTemplate;

    public ServiceHealthCheck(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Retryable(
        maxAttempts = MAX_RETRIES,
        backoff = @Backoff(delay = RETRY_DELAY)
    )
    public boolean waitForService(String serviceUrl) {
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(
                serviceUrl + "/actuator/health",
                String.class
            );
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.warn("Service not ready: {}", serviceUrl);
            throw new RuntimeException("Service health check failed");
        }
    }
}
```

**Configuración de Retry:**
```java
// tests/src/test/java/com/selimhorri/app/config/RetryConfig.java
@Configuration
@EnableRetry
public class RetryConfig {
    // Spring Retry habilitado para tests E2E
}
```

#### Uso Actual

**E2E Test Setup:**
```java
@SpringBootTest
public class E2ETestBase {

    @Autowired
    private ServiceHealthCheck healthCheck;

    @BeforeAll
    void waitForServices() {
        // Espera hasta 60 segundos (30 reintentos × 2 segundos)
        healthCheck.waitForService("http://api-gateway");
        healthCheck.waitForService("http://order-service:8083");
        healthCheck.waitForService("http://product-service:8082");
    }
}
```

#### Limitaciones Actuales

1. **Solo en Tests:** No está implementado en código de producción
2. **Sin Configuración Granular:** No hay control por tipo de error
3. **Sin Exponential Backoff:** Delay constante de 2 segundos
4. **Sin Circuit Breaker Integration:** No se integra con Resilience4j

#### Implementación Recomendada para Producción

**Con Resilience4j (Recomendado):**
```yaml
# order-service/src/main/resources/application.yml
resilience4j:
  retry:
    instances:
      orderService:
        max-attempts: 3
        wait-duration: 500ms
        retry-exceptions:
          - org.springframework.web.client.ResourceAccessException
          - java.net.SocketTimeoutException
        ignore-exceptions:
          - com.selimhorri.app.exception.BusinessException
```

```java
// order-service con retry
@Service
public class OrderServiceImpl {

    @Retry(name = "orderService", fallbackMethod = "getOrderFallback")
    public OrderDto getOrder(Integer orderId) {
        return restTemplate.getForObject(
            "http://ORDER-SERVICE/api/orders/" + orderId,
            OrderDto.class
        );
    }

    public OrderDto getOrderFallback(Integer orderId, Exception e) {
        log.error("Failed to get order after retries: {}", orderId, e);
        return OrderDto.builder().orderId(orderId).status("UNAVAILABLE").build();
    }
}
```

#### Beneficios de Implementación Completa

- **Resiliencia ante fallos transitorios:** Red, timeouts temporales
- **Mejor experiencia de usuario:** Menos errores visibles
- **Integración con Circuit Breaker:** Evita reintentos cuando circuito está abierto
- **Configuración declarativa:** Sin cambios de código

---

### 5.2 Timeout Pattern

#### Descripción Técnica
Timeouts parcialmente configurados solo en Feign clients del proxy-client. Los RestTemplate de comunicación service-to-service NO tienen timeouts explícitos configurados, dependiendo de defaults del sistema operativo (potencialmente infinitos).

#### Tecnología
- **Framework:** OpenFeign (solo proxy-client)
- **Estado:** Parcialmente implementado (solo Feign clients)

#### Implementación Actual

**Feign Client Configuration:**
```yaml
# proxy-client/src/main/resources/application.yml
feign:
  client:
    config:
      default:
        connectTimeout: 5000      # 5 segundos
        readTimeout: 10000        # 10 segundos
```

**Ejemplo de Feign Client:**
```java
// proxy-client/src/main/java/com/selimhorri/app/client/OrderServiceClient.java
@FeignClient(name = "ORDER-SERVICE")
public interface OrderServiceClient {

    @GetMapping("/order-service/api/orders/{orderId}")
    OrderDto getOrder(@PathVariable Integer orderId);
    // Usa timeouts configurados: 5s connect, 10s read
}
```

#### Limitaciones Actuales

**RestTemplate sin Timeouts:**
```java
// order-service - NO tiene timeouts configurados
@LoadBalanced
@Bean
public RestTemplate restTemplateBean() {
    RestTemplate restTemplate = new RestTemplate();
    restTemplate.setInterceptors(
        Collections.singletonList(authorizationHeaderInterceptor)
    );
    return restTemplate;
    // ❌ Sin timeout - puede colgar indefinidamente
}
```

#### Riesgos Actuales

1. **Cuelgues Indefinidos:** Si un servicio no responde, el caller espera infinitamente
2. **Resource Exhaustion:** Threads bloqueados consumen recursos
3. **Cascadas de Latencia:** Un servicio lento afecta a todos los callers
4. **Sin Protección Circuit Breaker:** Timeouts infinitos evitan que CB se abra

#### Implementación Recomendada

**RestTemplate con Timeouts:**
```java
// order-service/src/main/java/com/selimhorri/app/config/client/ClientConfig.java
@Configuration
public class ClientConfig {

    @LoadBalanced
    @Bean
    public RestTemplate restTemplateBean(
            AuthorizationHeaderInterceptor authInterceptor) {

        // Configurar timeouts
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);      // 5 segundos para conectar
        factory.setReadTimeout(10000);        // 10 segundos para leer respuesta

        RestTemplate restTemplate = new RestTemplate(factory);
        restTemplate.setInterceptors(
            Collections.singletonList(authInterceptor)
        );

        return restTemplate;
    }
}
```

**Con Apache HttpClient (Más Control):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
</dependency>
```

```java
@Configuration
public class ClientConfig {

    @LoadBalanced
    @Bean
    public RestTemplate restTemplateBean(
            AuthorizationHeaderInterceptor authInterceptor) {

        RequestConfig requestConfig = RequestConfig.custom()
            .setConnectTimeout(5000)           // Conexión
            .setConnectionRequestTimeout(3000) // Obtener conexión del pool
            .setSocketTimeout(10000)           // Socket read
            .build();

        CloseableHttpClient httpClient = HttpClients.custom()
            .setDefaultRequestConfig(requestConfig)
            .setMaxConnTotal(100)              // Pool size
            .setMaxConnPerRoute(20)            // Conexiones por ruta
            .build();

        HttpComponentsClientHttpRequestFactory factory =
            new HttpComponentsClientHttpRequestFactory(httpClient);

        RestTemplate restTemplate = new RestTemplate(factory);
        restTemplate.setInterceptors(
            Collections.singletonList(authInterceptor)
        );

        return restTemplate;
    }
}
```

**Configuración Externalizada:**
```yaml
# order-service/src/main/resources/application.yml
http:
  client:
    connect-timeout: 5000
    read-timeout: 10000
    connection-request-timeout: 3000
    max-connections-total: 100
    max-connections-per-route: 20
```

```java
@Configuration
@ConfigurationProperties(prefix = "http.client")
public class HttpClientProperties {
    private int connectTimeout = 5000;
    private int readTimeout = 10000;
    // getters/setters
}
```

#### Beneficios de Implementación Completa

- **Previene Cuelgues:** Fallos rápidos en lugar de esperas infinitas
- **Mejora Circuit Breaker:** Timeouts permiten detectar servicios lentos
- **Resource Management:** Libera threads bloqueados
- **Configuración por Ambiente:** Timeouts diferentes dev/prod

---

## 6. PATRONES RECOMENDADOS PARA IMPLEMENTAR

### 6.1 Bulkhead Pattern ⭐ (ALTA PRIORIDAD)

#### Descripción
Aislamiento de recursos para evitar que un servicio lento o fallido consuma todos los threads/conexiones disponibles, afectando otras funcionalidades.

#### Por Qué Implementarlo

**Problema Actual:**
```
Thread Pool Compartido (50 threads)
     ↓
[Slow Service] consume 45 threads esperando respuesta
     ↓
[Fast Services] solo tienen 5 threads disponibles
     ↓
Sistema completo degradado por UN servicio lento
```

#### Implementación con Resilience4j

**1. Configuración:**
```yaml
# order-service/src/main/resources/application.yml
resilience4j:
  bulkhead:
    instances:
      paymentService:
        max-concurrent-calls: 10
        max-wait-duration: 100ms
      shippingService:
        max-concurrent-calls: 5
        max-wait-duration: 50ms
```

**2. Aplicar Anotación:**
```java
// order-service
@Service
public class OrderServiceImpl {

    @Bulkhead(name = "paymentService", fallbackMethod = "paymentFallback")
    public PaymentDto processPayment(Integer orderId) {
        return restTemplate.getForObject(
            "http://PAYMENT-SERVICE/api/payments",
            PaymentDto.class
        );
    }

    public PaymentDto paymentFallback(Integer orderId, BulkheadFullException e) {
        log.error("Payment bulkhead full for order: {}", orderId);
        return PaymentDto.builder().status("PENDING").build();
    }
}
```

**3. Verificar Métricas:**
```bash
# Métricas expuestas en /actuator/prometheus
resilience4j_bulkhead_available_concurrent_calls{name="paymentService"}
resilience4j_bulkhead_max_allowed_concurrent_calls{name="paymentService"}
```

#### Beneficios

- **Aislamiento:** Fallos en un servicio no afectan otros
- **Previsibilidad:** Límites conocidos de recursos
- **Degradación Controlada:** Fallbacks cuando bulkhead lleno
- **Fácil Implementación:** Ya tienes Resilience4j

#### Esfuerzo de Implementación

- **Tiempo:** 2-3 horas
- **Dificultad:** Media
- **Archivos a modificar:** ~6 servicios
- **Testing:** Simular carga con JMeter/Locust

---

### 6.2 Rate Limiting Pattern ⭐ (ALTA PRIORIDAD)

#### Descripción
Limitar el número de requests que un cliente puede hacer en un período de tiempo para prevenir abuso y garantizar disponibilidad.

#### Por Qué Implementarlo

**Problema Actual:**
```
Cliente malicioso envía 10,000 requests/segundo
     ↓
API Gateway acepta todo
     ↓
Servicios backend colapsan
     ↓
Sistema DOWN para todos los usuarios
```

#### Implementación en API Gateway

**Opción 1: Resilience4j Rate Limiter**

```yaml
# api-gateway/src/main/resources/application.yml
resilience4j:
  ratelimiter:
    instances:
      apiGateway:
        limit-for-period: 100        # 100 requests
        limit-refresh-period: 1s     # por segundo
        timeout-duration: 0s         # rechazar inmediatamente si excede
```

```java
// api-gateway
@Configuration
public class RateLimiterConfig {

    @Bean
    public GlobalFilter rateLimiterFilter(RateLimiterRegistry registry) {
        return (exchange, chain) -> {
            String clientIp = exchange.getRequest().getRemoteAddress()
                .getAddress().getHostAddress();

            RateLimiter rateLimiter = registry.rateLimiter("apiGateway");

            return Mono.fromCallable(() -> rateLimiter.acquirePermission())
                .flatMap(permitted -> {
                    if (permitted) {
                        return chain.filter(exchange);
                    } else {
                        exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
                        return exchange.getResponse().setComplete();
                    }
                });
        };
    }
}
```

**Opción 2: Bucket4j (Más Avanzado)**

```xml
<dependency>
    <groupId>com.github.vladimir-bukhtoyarov</groupId>
    <artifactId>bucket4j-core</artifactId>
    <version>8.1.0</version>
</dependency>
```

```java
@Component
public class RateLimitingFilter implements GlobalFilter, Ordered {

    private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String clientIp = exchange.getRequest().getRemoteAddress()
            .getAddress().getHostAddress();

        Bucket bucket = cache.computeIfAbsent(clientIp, k -> createBucket());

        if (bucket.tryConsume(1)) {
            return chain.filter(exchange);
        } else {
            exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            exchange.getResponse().getHeaders().add("X-Rate-Limit-Retry-After-Seconds", "1");
            return exchange.getResponse().setComplete();
        }
    }

    private Bucket createBucket() {
        Bandwidth limit = Bandwidth.classic(100, Refill.intervally(100, Duration.ofSeconds(1)));
        return Bucket.builder().addLimit(limit).build();
    }

    @Override
    public int getOrder() {
        return -1; // Alta prioridad
    }
}
```

#### Configuración por Endpoint

```java
// Rate limiting diferente por tipo de operación
public class RateLimitConfig {

    public Bucket getBucketForPath(String path) {
        if (path.startsWith("/app/api/authenticate")) {
            // Login: más restrictivo
            return createBucket(10, Duration.ofMinutes(1));
        } else if (path.startsWith("/app/api/orders")) {
            // Órdenes: moderado
            return createBucket(50, Duration.ofMinutes(1));
        } else {
            // Otros: permisivo
            return createBucket(100, Duration.ofMinutes(1));
        }
    }
}
```

#### Beneficios

- **Protección DDoS:** Previene ataques de fuerza bruta
- **Fair Usage:** Garantiza disponibilidad para todos
- **Previene Sobrecarga:** Protege backend de spikes
- **Configuración Granular:** Límites por endpoint/cliente

#### Esfuerzo de Implementación

- **Tiempo:** 2-4 horas
- **Dificultad:** Media
- **Archivos a modificar:** api-gateway principalmente
- **Testing:** Apache Bench o Locust

---

### 6.3 Feature Toggle Pattern ⭐ (PRIORIDAD MEDIA)

#### Descripción
Activar/desactivar funcionalidades en runtime sin redesplegar código, permitiendo despliegues graduales y A/B testing.

#### Por Qué Implementarlo

**Casos de Uso:**
1. **Despliegue Gradual:** Activar feature para 10% de usuarios
2. **Kill Switch:** Desactivar feature problemática sin rollback
3. **A/B Testing:** Probar dos implementaciones simultáneamente
4. **Ambiente-Específico:** Feature solo en dev/staging

#### Implementación con Spring Cloud Config

**1. Configuración Centralizada:**
```yaml
# Config Server: application-prod.yml
features:
  new-payment-flow:
    enabled: false
    rollout-percentage: 0
  recommendation-engine:
    enabled: true
    rollout-percentage: 100
  experimental-checkout:
    enabled: false
```

**2. Feature Toggle Service:**
```java
// Shared library o cada servicio
@Service
@ConfigurationProperties(prefix = "features")
public class FeatureToggleService {

    private Map<String, FeatureConfig> toggles = new HashMap<>();

    public boolean isEnabled(String featureName) {
        FeatureConfig config = toggles.get(featureName);
        if (config == null || !config.isEnabled()) {
            return false;
        }

        // Rollout percentage check
        if (config.getRolloutPercentage() < 100) {
            return ThreadLocalRandom.current().nextInt(100) < config.getRolloutPercentage();
        }

        return true;
    }

    @Data
    public static class FeatureConfig {
        private boolean enabled;
        private int rolloutPercentage = 100;
    }

    // Getters/setters para Spring binding
    public Map<String, FeatureConfig> getToggles() {
        return toggles;
    }

    public void setToggles(Map<String, FeatureConfig> toggles) {
        this.toggles = toggles;
    }
}
```

**3. Uso en Código:**
```java
// order-service
@Service
public class OrderServiceImpl {

    private final FeatureToggleService featureToggle;

    public OrderDto createOrder(OrderDto orderDto) {
        if (featureToggle.isEnabled("new-payment-flow")) {
            return createOrderWithNewPaymentFlow(orderDto);
        } else {
            return createOrderWithLegacyPaymentFlow(orderDto);
        }
    }
}
```

**4. Anotación Personalizada:**
```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface FeatureToggle {
    String value();
    boolean fallbackToException() default false;
}

@Aspect
@Component
public class FeatureToggleAspect {

    private final FeatureToggleService toggleService;

    @Around("@annotation(featureToggle)")
    public Object checkFeatureToggle(ProceedingJoinPoint pjp, FeatureToggle featureToggle) throws Throwable {
        if (toggleService.isEnabled(featureToggle.value())) {
            return pjp.proceed();
        } else {
            if (featureToggle.fallbackToException()) {
                throw new FeatureDisabledException(featureToggle.value());
            }
            return null;
        }
    }
}
```

**5. Endpoint de Gestión:**
```java
@RestController
@RequestMapping("/admin/features")
public class FeatureToggleController {

    private final FeatureToggleService toggleService;

    @GetMapping
    public Map<String, FeatureConfig> getAllToggles() {
        return toggleService.getToggles();
    }

    @PostMapping("/{featureName}/enable")
    public void enableFeature(@PathVariable String featureName) {
        // Actualizar en Config Server via API
        // Refrescar contexto: @RefreshScope
    }
}
```

#### Beneficios

- **Zero-Downtime Deployment:** Deploy código inactivo, activar después
- **Rápido Rollback:** Desactivar toggle vs redesplegar
- **Testing en Producción:** Canary releases
- **Bajo Riesgo:** Features experimentales aisladas

#### Esfuerzo de Implementación

- **Tiempo:** 3-4 horas
- **Dificultad:** Baja-Media
- **Archivos a modificar:** Config Server + servicios que usan toggles
- **Testing:** Verificar activación/desactivación

---

## 7. ANÁLISIS DE COBERTURA DE PATRONES

### Matriz de Patrones vs Requisitos de Calidad

| Patrón | Disponibilidad | Escalabilidad | Resiliencia | Mantenibilidad | Seguridad | Observabilidad |
|--------|----------------|---------------|-------------|----------------|-----------|----------------|
| Service Registry | ✅ | ✅ | ✅ | ✅ | - | ✅ |
| API Gateway | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Circuit Breaker | ✅ | - | ✅✅✅ | ✅ | - | ✅ |
| Load Balancing | ✅✅ | ✅✅ | ✅ | - | - | - |
| External Config | - | - | - | ✅✅✅ | ✅ | - |
| DB per Service | - | ✅✅ | ✅ | ✅✅ | ✅ | - |
| Distributed Tracing | - | - | ✅ | ✅ | - | ✅✅✅ |
| Health Checks | ✅✅ | ✅ | ✅ | - | - | ✅✅ |
| Metrics Collection | - | ✅ | ✅ | ✅ | - | ✅✅✅ |
| JWT Auth | - | ✅ | - | - | ✅✅✅ | - |
| Containerization | ✅ | ✅✅✅ | ✅ | ✅✅ | ✅ | - |
| DB Migration | - | - | - | ✅✅✅ | ✅ | - |
| **Bulkhead** (Propuesto) | ✅ | - | ✅✅✅ | ✅ | - | ✅ |
| **Rate Limiting** (Propuesto) | ✅✅ | ✅ | ✅✅ | - | ✅✅ | ✅ |
| **Feature Toggle** (Propuesto) | ✅✅ | - | ✅✅ | ✅✅✅ | - | - |

**Leyenda:** ✅ = Contribuye, ✅✅ = Contribuye Significativamente, ✅✅✅ = Contribuye Críticamente

### Resumen de Cobertura Actual

**Fortalezas:**
- ✅ **Observabilidad:** Cobertura completa (Tracing, Metrics, Health)
- ✅ **Mantenibilidad:** Excelente (Config, DB Migration, DB per Service)
- ✅ **Escalabilidad:** Buena (Load Balancing, Containerización)
- ✅ **Seguridad:** JWT completo, DB isolation

**Áreas de Mejora:**
- ⚠️ **Resiliencia:** Buena base (Circuit Breaker) pero falta Bulkhead y Retry completo
- ⚠️ **Disponibilidad:** Puede mejorar con Rate Limiting y Bulkhead
- ⚠️ **Timeouts:** Crítico implementar en producción

---

## 8. PLAN DE IMPLEMENTACIÓN RECOMENDADO

### Fase 1: Estabilización (1-2 días) ⚠️ CRÍTICO

**Objetivo:** Cerrar gaps de patrones parciales

1. **Implementar Timeouts en RestTemplate** (2 horas)
   - Configurar en todos los servicios
   - Testing con servicios lentos simulados

2. **Implementar Retry Pattern** (2 horas)
   - Resilience4j retry en service-to-service calls
   - Integrar con Circuit Breaker

### Fase 2: Patrones Adicionales (2-3 días) 🎯 ENTREGABLES ACADÉMICOS

**Objetivo:** Cumplir con requisito de 3 patrones adicionales

1. **Bulkhead Pattern** (3 horas)
   - Configurar en order-service, payment-service
   - Documentar límites de recursos
   - Testing de aislamiento

2. **Rate Limiting Pattern** (4 horas)
   - Implementar en API Gateway
   - Configurar límites por endpoint
   - Testing con Locust

3. **Feature Toggle Pattern** (3 horas)
   - Setup en Config Server
   - Implementar FeatureToggleService
   - Ejemplo en 1-2 features

### Fase 3: Documentación (1 día) 📝 ACADÉMICO

1. **Actualizar PATRONES_ARQUITECTURA_IMPLEMENTADOS.md**
   - Documentar nuevos patrones con mismo formato
   - Agregar diagramas de flujo
   - Ejemplos de configuración

2. **Crear Documento de Decisiones Arquitectónicas (ADR)**
   - Por qué se eligió cada patrón
   - Trade-offs considerados
   - Alternativas descartadas

3. **Métricas de Impacto**
   - Antes/después de implementar patrones
   - Resiliencia mejorada (% de requests exitosos)
   - Latencias reducidas

---

## 9. RECOMENDACIÓN FINAL PARA ENTREGABLE ACADÉMICO

### ✅ Argumentación para Defensa del Proyecto

**Patrones Actualmente Implementados con Código Explícito: 11**

Estos patrones tienen **evidencia clara y verificable** de implementación:

1. ✅ Service Registry & Discovery (Eureka) - ~500 LOC
2. ✅ API Gateway (Spring Cloud Gateway) - ~800 LOC
3. ✅ Circuit Breaker (Resilience4j) - ~200 LOC config
4. ✅ External Configuration (Cloud Config) - ~300 LOC
5. ✅ Database per Service - ~2,000 LOC
6. ✅ Distributed Tracing (Sleuth + Zipkin) - ~100 LOC config
7. ✅ Metrics Collection (Micrometer) - ~100 LOC config
8. ✅ JWT Authentication - ~600 LOC
9. ✅ Authorization Header Propagation - ~350 LOC
10. ✅ Environment-Based Configuration - ~4,000 LOC config
11. ✅ Database Migration (Flyway) - ~1,500 LOC SQL

**Total: ~10,450 líneas de código/configuración**

---

### 🎯 Tres Patrones Adicionales RECOMENDADOS (Sin Overlap con Infraestructura)

Para cumplir con requisito académico de "implementar 3 patrones adicionales", **evitando confusión con infraestructura gestionada:**

#### Opción A: Patrones de Resiliencia Pura (RECOMENDADO) ⭐

1. **Bulkhead Pattern**
   - ❌ No provisto por DO/K8s
   - ✅ Requiere código explícito (Resilience4j)
   - ✅ Aislamiento de thread pools
   - 📊 Impacto medible: Límites de concurrencia respetados
   - ⏱️ Tiempo: 3 horas

2. **Retry Pattern Completo**
   - ❌ No provisto por DO/K8s
   - ✅ Requiere configuración explícita (Resilience4j)
   - ✅ Ya parcialmente implementado (solo completar)
   - 📊 Impacto medible: % de requests recuperados tras fallo transitorio
   - ⏱️ Tiempo: 2 horas

3. **Rate Limiting Pattern**
   - ❌ No provisto por DO/K8s
   - ✅ Requiere código explícito (Resilience4j o Bucket4j)
   - ✅ Protección API Gateway
   - 📊 Impacto medible: Requests bloqueados por límite
   - ⏱️ Tiempo: 4 horas

**Total Tiempo: 9 horas**

---

#### Opción B: Patrones Mixtos (Resiliencia + Configuración)

1. **Bulkhead Pattern** (3 horas)
2. **Rate Limiting Pattern** (4 horas)
3. **Feature Toggle Pattern** (3 horas)
   - ❌ No provisto por DO/K8s
   - ✅ Requiere implementación explícita
   - ✅ Despliegue gradual de features
   - 📊 Impacto medible: Features activadas/desactivadas sin redeploy

**Total Tiempo: 10 horas**

---

### 📋 Argumentos de Defensa para Patrones Híbridos

Si te preguntan sobre Load Balancing, Health Checks o Containerization:

#### Load Balancing:
- ✅ **SÍ implementamos:** `@LoadBalanced` RestTemplate (client-side LB)
- ✅ **SÍ implementamos:** Configuración de eager loading
- ⚠️ **Infraestructura provee:** Load Balancer externo de DO
- **Argumento:** "Implementamos client-side load balancing con Spring Cloud LoadBalancer, que distribuye llamadas entre instancias registradas en Eureka. Esto es adicional al load balancer de infraestructura."

#### Health Checks:
- ✅ **SÍ implementamos:** Endpoints Actuator custom
- ✅ **SÍ implementamos:** Health indicators (Circuit Breaker, DB)
- ⚠️ **Infraestructura provee:** Liveness/Readiness probe mechanism
- **Argumento:** "Implementamos health indicators personalizados que exponen estado de circuit breakers y conexiones DB. K8s consume estos endpoints pero nosotros definimos la lógica de health."

#### Containerization:
- ✅ **SÍ implementamos:** Dockerfiles multi-stage por servicio
- ✅ **SÍ implementamos:** Manifiestos K8s (25+ archivos YAML)
- ⚠️ **Infraestructura provee:** Cluster K8s gestionado
- **Argumento:** "Diseñamos y escribimos los Dockerfiles con multi-stage builds y todos los manifiestos de Kubernetes. El cluster es gestionado pero la configuración es nuestra."

---

### 📊 Tabla de Evidencia para Presentación

| Patrón | Archivos de Código | Commits Git | Tests | Métricas Observable |
|--------|-------------------|-------------|-------|-------------------|
| Service Registry | `ServiceDiscoveryApplication.java` | ✅ | Health checks | Eureka Dashboard |
| API Gateway | `ApiGatewayApplication.java`, routes config | ✅ | E2E tests | Request routing logs |
| Circuit Breaker | `application.yml` × 10 | ✅ | Failure simulation | `/actuator/health` |
| External Config | `CloudConfigApplication.java`, Git repo | ✅ | Multi-profile tests | Config refresh |
| JWT Auth | `JwtService.java`, `JwtRequestFilter.java` | ✅ | Auth tests | 401/403 responses |
| DB Migration | `V1__*.sql` a `V6__*.sql` | ✅ | Integration tests | `flyway_schema_history` |
| Distributed Tracing | Sleuth config | ✅ | E2E tracing | Zipkin UI |
| Metrics | Micrometer config | ✅ | Prometheus scrape | Grafana dashboards |

---

### 🎓 Conclusión para Entregable Académico

**Estado Actual:**
- ✅ 11 patrones con implementación explícita verificable
- ⚠️ 3 patrones híbridos (pueden argumentarse con evidencia)
- ❌ 0 patrones puramente de infraestructura sin código

**Recomendación:**
Implementar **3 patrones adicionales de Opción A** (Bulkhead, Retry, Rate Limiting) para:
- Llegar a **14 patrones totales con código explícito**
- Evitar cuestionamientos sobre infraestructura gestionada
- Tener evidencia medible de cada patrón
- Tiempo razonable de implementación (9 horas)

**Valor Diferenciador:**
Estos 3 patrones adicionales demuestran comprensión profunda de **resiliencia distribuida**, un tema avanzado que va más allá de simplemente desplegar en Kubernetes.

---

**Documento Actualizado:** 2025-11-13
**Proyecto:** E-Commerce Microservices Backend Application
**Versión:** 0.1.0
