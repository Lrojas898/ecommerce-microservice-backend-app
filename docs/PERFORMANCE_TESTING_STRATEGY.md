# Estrategia de Pruebas de Performance - E-Commerce Microservices

**Taller 2: Pruebas y Lanzamiento**
**Universidad ICESI - Ingeniería de Software V**

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Arquitectura de Pruebas de Performance](#2-arquitectura-de-pruebas-de-performance)
3. [Escenarios de Prueba Implementados](#3-escenarios-de-prueba-implementados)
4. [Estrategia de Carga](#4-estrategia-de-carga)
5. [Métricas y Análisis](#5-métricas-y-análisis)

---

## 1. Introducción

Las pruebas de performance son críticas para validar que la arquitectura de microservicios pueda manejar carga real de producción. Este documento describe la estrategia completa de performance testing implementada con Locust.

### 1.1 Objetivos

- **Validar Capacidad**: Determinar cuántos usuarios concurrentes puede manejar el sistema
- **Identificar Cuellos de Botella**: Detectar servicios o componentes que limitan el rendimiento
- **Establecer Baseline**: Crear métricas de referencia para futuras comparaciones
- **Simular Escenarios Reales**: Probar patrones de uso del mundo real
- **Validar Escalabilidad**: Verificar que el sistema escala horizontalmente

### 1.2 Herramientas

- **Locust 2.15+**: Framework de carga distribuido en Python
- **Python 3.13**: Runtime para scripts de prueba
- **Jenkins**: Orquestación de pruebas en CI/CD
- **Kubernetes**: Ambiente de ejecución

---

## 2. Arquitectura de Pruebas de Performance

### 2.1 Componentes

```
┌─────────────────────────────────────────────────────────┐
│                   LOCUST MASTER                          │
│         (Coordina distributed load testing)              │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐
   │ Worker1 │ │ Worker2 │ │ Worker3 │
   └────┬────┘ └────┬────┘ └────┬────┘
        │           │           │
        └───────────┴───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │    Port-Forward       │
        │  localhost:18080      │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │    API Gateway        │
        │   (Kubernetes)        │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  Product     │        │  Order       │
│  Service     │        │  Service     │
└──────────────┘        └──────────────┘
        │                       │
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  Payment     │        │  Shipping    │
│  Service     │        │  Service     │
└──────────────┘        └──────────────┘
```

### 2.2 Modelo de Usuarios Virtuales

Locust utiliza **greenlets (gevent)** para simular miles de usuarios concurrentes con recursos mínimos:

```python
# Cada usuario virtual es un greenlet (lightweight thread)
class ECommercePurchaseUser(HttpUser):
    # Think time entre acciones
    wait_time = between(3, 10)  # seconds

    # Tasks ponderadas
    @task(5)  # 50% del tiempo
    def browse_products(self):
        ...

    @task(3)  # 30% del tiempo
    def view_product(self):
        ...
```

**Ventajas del modelo**:
- Miles de usuarios con memoria mínima
- No requiere hilos reales del OS
- Eficiente para I/O bound operations (HTTP requests)

---

## 3. Escenarios de Prueba Implementados

### 3.1 ProductServiceLoadTest

#### Propósito
Simular usuarios navegando el catálogo de productos (window shoppers).

#### Implementación

```python
class ProductServiceLoadTest(HttpUser):
    """
    Simula usuarios que:
    - Navegan el catálogo general
    - Ven detalles de productos específicos
    - Exploran categorías
    - Consultan favoritos
    """

    wait_time = between(1, 3)  # Think time realista

    @task(5)  # 45% de las acciones
    def browse_all_products(self):
        """
        GET /app/api/products

        Lógica:
        - Obtiene listado completo de productos
        - Expected response time: < 500ms (p95)
        - Típica landing page
        """
        with self.client.get("/app/api/products",
                            catch_response=True,
                            name="Browse Products") as response:
            if response.status_code == 200:
                try:
                    products = response.json()
                    if len(products) > 0:
                        response.success()
                    else:
                        response.failure("No products returned")
                except:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Status code: {response.status_code}")

    @task(3)  # 27% de las acciones
    def view_product_details(self):
        """
        GET /app/api/products/{id}

        Lógica:
        - ID aleatorio (1-100) para distribuir carga
        - Acepta 404 (producto no existe)
        - Expected response time: < 300ms (p95)
        """
        product_id = random.randint(1, 100)
        with self.client.get(f"/app/api/products/{product_id}",
                            catch_response=True,
                            name="View Product") as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")

    @task(2)  # 18% de las acciones
    def browse_categories(self):
        """
        GET /app/api/categories

        Lógica:
        - Navega categorías de productos
        - Expected response time: < 200ms (p95)
        """
        with self.client.get("/app/api/categories",
                            catch_response=True,
                            name="Browse Categories") as response:
            if response.status_code == 200:
                response.success()

    @task(1)  # 9% de las acciones
    def view_favourites(self):
        """
        GET /app/api/favourites

        Lógica:
        - Consulta favoritos del usuario
        - Acepta 200 y 404 (usuario sin favoritos)
        """
        with self.client.get("/app/api/favourites",
                            catch_response=True,
                            name="View Favourites") as response:
            if response.status_code in [200, 404]:
                response.success()
```

#### Patrones de Carga

| Patrón | Users | Spawn Rate | Duration | Objetivo |
|--------|-------|------------|----------|----------|
| Light | 20 | 2/s | 5min | Validación básica |
| Normal | 50 | 5/s | 10min | Carga esperada |
| Peak | 100 | 10/s | 15min | Hora pico |
| Stress | 200 | 20/s | 20min | Encontrar límites |

#### Métricas Objetivo

- **Throughput**: > 100 RPS
- **Response Time (p95)**: < 500ms
- **Error Rate**: < 0.5%
- **Database Load**: < 70% CPU
- **Memory**: Estable (no leaks)

---

### 3.2 OrderServiceStressTest

#### Propósito
Probar el sistema bajo alta carga de creación de órdenes (Black Friday simulation).

#### Implementación

```python
class OrderServiceStressTest(HttpUser):
    """
    Simula escenario de alta demanda:
    - Creación masiva de órdenes
    - Consulta de órdenes existentes
    - Detalles de órdenes específicas
    """

    wait_time = between(0.5, 2)  # Más agresivo que ProductService

    @task(4)  # 57% de las acciones
    def create_order(self):
        """
        POST /app/api/carts + POST /app/api/orders

        Flujo completo:
        1. Crear carrito con userId aleatorio
        2. Crear orden vinculada al carrito
        3. Validar respuesta 200/201

        Expected response time: < 1000ms (p95)
        """
        # Step 1: Create cart
        cart_data = {"userId": random.randint(1, 100)}
        cart_response = self.client.post("/app/api/carts",
                                         json=cart_data,
                                         name="Create Cart")

        if cart_response.status_code in [200, 201]:
            try:
                cart_id = cart_response.json().get('cartId')
            except:
                cart_id = random.randint(1, 1000)  # Fallback

            # Step 2: Create order
            order_data = {
                "orderDesc": f"Stress Test Order {random.randint(1000, 9999)}",
                "orderFee": round(random.uniform(10.0, 500.0), 2),
                "cart": {"cartId": cart_id}
            }

            with self.client.post("/app/api/orders",
                                 json=order_data,
                                 catch_response=True,
                                 name="Create Order") as response:
                if response.status_code in [200, 201]:
                    response.success()
                else:
                    response.failure(f"Order creation failed: {response.status_code}")

    @task(2)  # 29% de las acciones
    def browse_orders(self):
        """
        GET /app/api/orders

        Lógica:
        - Obtiene listado de órdenes
        - Simula admin/user viendo órdenes
        """
        with self.client.get("/app/api/orders",
                            catch_response=True,
                            name="Browse Orders") as response:
            if response.status_code == 200:
                response.success()

    @task(1)  # 14% de las acciones
    def view_order_details(self):
        """
        GET /app/api/orders/{id}

        Lógica:
        - ID aleatorio para distribuir queries
        - Acepta 404 (orden no existe)
        """
        order_id = random.randint(1, 1000)
        with self.client.get(f"/app/api/orders/{order_id}",
                            catch_response=True,
                            name="View Order Details") as response:
            if response.status_code in [200, 404]:
                response.success()
```

#### Casos de Uso Simulados

1. **Black Friday**: 500 users, spawn 50/s, 30min
2. **Flash Sale**: 300 users, spawn 100/s, 10min
3. **New Product Launch**: 200 users, spawn 20/s, 20min
4. **Regular Peak**: 100 users, spawn 10/s, 15min

#### Cuellos de Botella a Monitorear

- **Database Connection Pool**: Puede agotarse
- **JPA Transactions**: Locks en base de datos
- **Eureka**: Latencia de service discovery
- **Memory**: Objetos Order en heap
- **Network**: Bandwidth entre pods

---

### 3.3 UserAuthenticationLoadTest

#### Propósito
Validar autenticación y registro bajo carga.

#### Implementación

```python
class UserAuthenticationLoadTest(HttpUser):
    """
    Simula:
    - Registro de nuevos usuarios
    - Login/autenticación
    - Consulta de perfiles
    """

    wait_time = between(2, 5)

    @task(5)  # 50% - Login más frecuente que registro
    def login_user(self):
        """
        POST /app/api/authenticate

        Lógica:
        - Username/password aleatorios
        - Acepta 401 (credenciales inválidas) como válido
        - Expected: < 800ms (p95)

        Por qué acepta 401:
        - En load test, no todos los logins serán válidos
        - Queremos medir performance del endpoint, no éxito funcional
        """
        login_data = {
            "username": f"loadtest{random.randint(10000, 99999)}",
            "password": "TestPass123!"
        }

        with self.client.post("/app/api/authenticate",
                             json=login_data,
                             catch_response=True,
                             name="User Login") as response:
            if response.status_code in [200, 401]:
                response.success()

                # Si login exitoso, extraer token
                if response.status_code == 200:
                    try:
                        token = response.json().get('token')
                        # Podría guardar token para requests subsecuentes
                    except:
                        pass

    @task(3)  # 30% - Registros menos frecuentes
    def register_user(self):
        """
        POST /app/api/users

        Lógica:
        - Genera usuario único con timestamp
        - Acepta 409 (usuario ya existe)
        - Expected: < 1500ms (p95) - Más lento por bcrypt

        Por qué es más lento:
        - Password hashing (bcrypt) consume CPU
        - Validaciones de negocio
        - Insert en base de datos
        """
        user_id = random.randint(10000, 99999)
        user_data = {
            "firstName": f"LoadTest{user_id}",
            "lastName": "User",
            "email": f"loadtest{user_id}@example.com",
            "phone": f"+1{random.randint(1000000000, 9999999999)}",
            "username": f"loadtest{user_id}",
            "password": "TestPass123!"
        }

        with self.client.post("/app/api/users",
                             json=user_data,
                             catch_response=True,
                             name="Register User") as response:
            if response.status_code in [200, 201, 409]:
                response.success()

    @task(2)  # 20% - Consultas de perfil
    def get_user_profile(self):
        """
        GET /app/api/users/{id}

        Lógica:
        - ID aleatorio
        - Simula usuario consultando perfil
        - Expected: < 300ms (p95)
        """
        user_id = random.randint(1, 100)
        with self.client.get(f"/app/api/users/{user_id}",
                            catch_response=True,
                            name="Get User Profile") as response:
            if response.status_code in [200, 404]:
                response.success()
```

#### Métricas de Autenticación

| Operación | Response Time (p95) | Throughput | Error Rate |
|-----------|---------------------|------------|------------|
| Login | < 800ms | > 30/s | < 2% |
| Register | < 1500ms | > 10/s | < 1% |
| Get Profile | < 300ms | > 50/s | < 0.5% |

---

### 3.4 CompletePurchaseFlow (Sequential)

#### Propósito
Simular flujo de compra completo end-to-end.

#### Implementación

```python
class CompletePurchaseFlow(SequentialTaskSet):
    """
    Flujo secuencial de 6 pasos.

    Características:
    - Orden estricto de ejecución
    - State management entre pasos
    - Simula usuario real completando compra
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Estado compartido entre tareas
        self.product_id = None
        self.cart_id = None
        self.order_id = None
        self.payment_id = None

    @task
    def step1_browse_products(self):
        """
        GET /app/api/products

        Lógica:
        - Usuario entra a la tienda
        - Ve catálogo completo
        - Selecciona producto aleatorio
        """
        response = self.client.get("/app/api/products",
                                  name="1. Browse Products")
        if response.status_code == 200:
            # Simula selección de producto
            self.product_id = random.randint(1, 50)

    @task
    def step2_view_product(self):
        """
        GET /app/api/products/{id}

        Lógica:
        - Ver detalles del producto seleccionado
        - Leer especificaciones
        """
        if self.product_id:
            self.client.get(f"/app/api/products/{self.product_id}",
                          name="2. View Product Details")

    @task
    def step3_create_cart(self):
        """
        POST /app/api/carts

        Lógica:
        - Crear carrito de compras
        - Asociar a usuario
        - Guardar cart_id para pasos siguientes
        """
        response = self.client.post("/app/api/carts",
                                   json={"userId": random.randint(1, 100)},
                                   name="3. Create Cart")
        if response.status_code in [200, 201]:
            try:
                self.cart_id = response.json().get('cartId')
            except:
                self.cart_id = random.randint(1, 1000)

    @task
    def step4_create_order(self):
        """
        POST /app/api/orders

        Lógica:
        - Crear orden con el carrito
        - Especificar monto y descripción
        - Guardar order_id para payment
        """
        order_data = {
            "orderDesc": "Complete Flow Test Order",
            "orderFee": round(random.uniform(50.0, 300.0), 2),
            "cart": {"cartId": self.cart_id if self.cart_id else random.randint(1, 1000)}
        }

        response = self.client.post("/app/api/orders",
                                   json=order_data,
                                   name="4. Create Order")
        if response.status_code in [200, 201]:
            try:
                self.order_id = response.json().get('orderId')
            except:
                self.order_id = random.randint(1, 10000)

    @task
    def step5_create_payment(self):
        """
        POST /app/api/payments

        Lógica:
        - Procesar pago para la orden
        - Marcar como pagado
        - Guardar payment_id
        """
        if self.order_id:
            payment_data = {
                "order": {"orderId": self.order_id},
                "isPayed": True
            }

            response = self.client.post("/app/api/payments",
                                       json=payment_data,
                                       name="5. Process Payment")
            if response.status_code in [200, 201]:
                try:
                    self.payment_id = response.json().get('paymentId')
                except:
                    self.payment_id = random.randint(1, 10000)

    @task
    def step6_create_shipping(self):
        """
        POST /app/api/shippings

        Lógica:
        - Crear registro de envío
        - Vincular con orden y producto
        - Completar flujo de compra
        """
        if self.order_id and self.product_id:
            shipping_data = {
                "orderId": self.order_id,
                "productId": self.product_id,
                "orderedQuantity": random.randint(1, 5)
            }

            self.client.post("/app/api/shippings",
                           json=shipping_data,
                           name="6. Create Shipping Item")

    @task
    def stop(self):
        """
        Finalizar secuencia.

        interrupt() detiene el SequentialTaskSet
        y permite que el usuario virtual inicie de nuevo.
        """
        self.interrupt()


class ECommercePurchaseUser(HttpUser):
    """
    Usuario que ejecuta el flujo completo.
    """
    wait_time = between(3, 10)  # Espera entre flujos completos
    tasks = [CompletePurchaseFlow]
```

#### Análisis del Flujo

**Comunicación entre Microservicios**:
```
Step 1: User → API Gateway → Product Service
Step 2: User → API Gateway → Product Service
Step 3: User → API Gateway → Order Service (Cart)
Step 4: User → API Gateway → Order Service
Step 5: User → API Gateway → Payment Service
        Payment Service → Order Service (verificación)
Step 6: User → API Gateway → Shipping Service
        Shipping Service → Order Service (consulta)
        Shipping Service → Product Service (consulta)
```

**Métricas del Flujo**:
- **Total Journey Time**: < 5 segundos (p95)
- **Success Rate**: > 95%
- **Abandonment Rate**: < 5%
- **Bottlenecks**: Identificar paso más lento

---

### 3.5 MixedWorkloadUser (Más Realista)

#### Propósito
Simular carga realista con distribución de comportamientos.

#### Implementación

```python
class MixedWorkloadUser(HttpUser):
    """
    Distribución basada en analytics reales de e-commerce:
    - 60% Solo navegan (window shoppers)
    - 20% Crean órdenes (cart abandoners + buyers)
    - 15% Consultan perfil/auth
    - 5% Completan compra completa

    Esta distribución refleja conversion rate típico de 5%
    """

    wait_time = between(1, 5)

    @task(12)  # 60% = 12/20
    def browse_products(self):
        """
        Mayoría de usuarios solo navegan.

        Lógica:
        - Browse general
        - 50% probabilidad de ver detalle
        """
        self.client.get("/app/api/products", name="Browse Products")

        if random.random() > 0.5:
            product_id = random.randint(1, 100)
            self.client.get(f"/app/api/products/{product_id}",
                          name="View Product")

    @task(4)   # 20% = 4/20
    def create_order(self):
        """
        Algunos usuarios crean órdenes.

        Incluye cart abandoners (no completan pago).
        """
        # Create cart
        cart_response = self.client.post("/app/api/carts",
                                         json={"userId": random.randint(1, 100)})
        cart_id = cart_response.json().get('cartId', random.randint(1, 1000)) \
                  if cart_response.status_code in [200, 201] \
                  else random.randint(1, 1000)

        # Create order
        order_data = {
            "orderDesc": f"Mixed Workload Order {random.randint(1, 9999)}",
            "orderFee": round(random.uniform(20.0, 200.0), 2),
            "cart": {"cartId": cart_id}
        }
        self.client.post("/app/api/orders", json=order_data, name="Create Order")

    @task(3)   # 15% = 3/20
    def user_auth(self):
        """
        Usuarios consultando perfil/autenticándose.
        """
        user_id = random.randint(1, 100)
        self.client.get(f"/app/api/users/{user_id}", name="Get User")

    @task(1)   # 5% = 1/20
    def complete_purchase(self):
        """
        Pocos usuarios completan compra completa.

        Este es el conversion rate real.
        """
        # Browse
        product_id = random.randint(1, 50)
        self.client.get(f"/app/api/products/{product_id}")

        # Create cart
        cart_response = self.client.post("/app/api/carts",
                                         json={"userId": random.randint(1, 100)})
        cart_id = cart_response.json().get('cartId', random.randint(1, 1000)) \
                  if cart_response.status_code in [200, 201] \
                  else random.randint(1, 1000)

        # Create order
        order_response = self.client.post("/app/api/orders", json={
            "orderDesc": "Quick Purchase",
            "orderFee": 99.99,
            "cart": {"cartId": cart_id}
        })

        # Process payment
        if order_response.status_code in [200, 201]:
            try:
                order_id = order_response.json().get('orderId', random.randint(1, 1000))
                self.client.post("/app/api/payments", json={
                    "order": {"orderId": order_id},
                    "isPayed": True
                })
            except:
                pass
```

#### Por Qué Esta Distribución

**Datos de E-Commerce Real**:
- Conversion rate promedio: 2-5%
- 70% de usuarios abandonan el carrito
- Solo 30% de visitantes inician compra

**Nuestra Simulación (5% conversion)**:
- 60% solo navegan
- 35% inician compra (cart + order)
- 5% completan compra

---

## 4. Estrategia de Carga

### 4.1 Tipos de Pruebas

#### Smoke Test
```
Users: 10
Spawn Rate: 1/s
Duration: 2min
Objetivo: Validación básica, ¿funciona?
```

#### Load Test
```
Users: 50-100
Spawn Rate: 5-10/s
Duration: 10-15min
Objetivo: Carga esperada normal
```

#### Stress Test
```
Users: 100-500
Spawn Rate: 10-50/s
Duration: 15-30min
Objetivo: Encontrar punto de quiebre
```

#### Spike Test
```
Pattern: 0 → 200 → 0
Spawn Rate: 50/s up, 50/s down
Duration: 5-10min
Objetivo: Recuperación ante picos
```

#### Endurance Test
```
Users: 50
Spawn Rate: 5/s
Duration: 1-2 hours
Objetivo: Memory leaks, degradación
```

### 4.2 Ramp-Up Strategy

**Gradual Ramp-Up** (Recomendado):
```python
# Locust hace esto automáticamente con spawn_rate
# Ejemplo: 100 users, spawn_rate=10/s

# t=0s:  0 users
# t=1s:  10 users
# t=2s:  20 users
# ...
# t=10s: 100 users (plateau)
# Mantiene 100 users hasta fin de prueba
```

**Por Qué Gradual**:
- Evita saturar sistema inmediatamente
- Permite warm-up de caches
- JVM JIT compilation se estabiliza
- Connection pools se llenan gradualmente

---

## 5. Métricas y Análisis

### 5.1 Métricas Capturadas

**Por Locust**:
```
Request Statistics:
- Total Requests
- Failed Requests
- Requests per Second (RPS)
- Average Response Time
- Min/Max Response Time
- Percentiles (50, 66, 75, 80, 90, 95, 98, 99, 100)

Failure Statistics:
- Error type
- Occurrences
- Error message
```

**Por Kubernetes**:
```
Resource Usage:
- CPU usage per pod
- Memory usage per pod
- Network I/O
- Disk I/O

Pod Metrics:
- Restart count
- Ready status
- Age
```

**Por Base de Datos**:
```
Database Metrics:
- Active connections
- Connection pool usage
- Query execution time
- Lock wait time
- Deadlocks
```

### 5.2 Umbrales de Éxito

| Métrica | Objetivo | Crítico Si |
|---------|----------|------------|
| Error Rate | < 1% | > 5% |
| Avg Response Time | < 400ms | > 1000ms |
| p95 Response Time | < 1000ms | > 3000ms |
| p99 Response Time | < 2000ms | > 5000ms |
| Throughput (RPS) | > 50 | < 20 |
| CPU Usage | < 70% | > 90% |
| Memory Usage | < 80% | > 95% |
| DB Connections | < 70% pool | > 90% pool |

### 5.3 Análisis de Resultados

**Indicadores de Sistema Saludable**:
- ✅ Error rate estable y bajo
- ✅ Response time constante durante la prueba
- ✅ RPS sube linealmente con usuarios
- ✅ CPU/Memory estables
- ✅ No degradación over time

**Señales de Alerta**:
- ⚠️ Response time incrementando gradualmente → Memory pressure
- ⚠️ Spikes de response time → Garbage collection pauses
- ⚠️ RPS máximo alcanzado antes de target users → Bottleneck
- ⚠️ Error rate incrementando → Resource exhaustion

**Cuellos de Botella Comunes**:
1. **Database Connection Pool**: Incrementar max connections
2. **CPU Saturation**: Aumentar replicas o CPU limits
3. **Memory Leaks**: Analizar heap dumps
4. **Network Bandwidth**: Revisar service mesh overhead
5. **Eureka Latency**: Cache service discovery

---

## 6. Integración con Pipeline

### 6.1 Ejecución en Jenkins

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'TEST_TYPE', choices: [
            'MixedWorkloadUser',
            'ProductServiceLoadTest',
            'OrderServiceStressTest',
            'UserAuthenticationLoadTest',
            'ECommercePurchaseUser'
        ])
        string(name: 'USERS', defaultValue: '100')
        string(name: 'SPAWN_RATE', defaultValue: '10')
        string(name: 'RUN_TIME', defaultValue: '5m')
    }

    stages {
        stage('Setup') {
            steps {
                sh """
                    cd tests/performance
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                """
            }
        }

        stage('Run Performance Tests') {
            steps {
                sh """
                    cd tests/performance
                    . venv/bin/activate

                    locust -f locustfile.py ${params.TEST_TYPE} \
                        --host=http://172.17.0.1:18080 \
                        --users ${params.USERS} \
                        --spawn-rate ${params.SPAWN_RATE} \
                        --run-time ${params.RUN_TIME} \
                        --headless \
                        --html report.html \
                        --csv report
                """
            }
        }

        stage('Publish Reports') {
            steps {
                publishHTML([
                    reportDir: 'tests/performance',
                    reportFiles: 'report.html',
                    reportName: 'Performance Test Report'
                ])
                archiveArtifacts artifacts: 'tests/performance/report*.csv'
            }
        }
    }
}
```

---

## 7. Conclusiones

### 7.1 Beneficios de la Estrategia

1. **Cobertura Completa**: 5 escenarios cubren todos los flujos críticos
2. **Realismo**: MixedWorkloadUser refleja comportamiento real
3. **Escalabilidad**: Locust puede simular miles de usuarios
4. **Automatización**: Integrado en CI/CD
5. **Métricas Accionables**: Reportes claros para toma de decisiones

### 7.2 Mejoras Futuras

- [ ] Distributed Locust (master-worker)
- [ ] Integration con APM (New Relic, Datadog)
- [ ] Pruebas de chaos engineering
- [ ] Auto-scaling basado en métricas
- [ ] Continuous performance testing

---

**Documento Generado**: 2025-11-03
**Versión**: 1.0
**Autor**: DevOps Team - Taller 2
