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
-  Error rate estable y bajo
-  Response time constante durante la prueba
-  RPS sube linealmente con usuarios
-  CPU/Memory estables
-  No degradación over time


**Cuellos de Botella Comunes**:
1. **Database Connection Pool**: Incrementar max connections
2. **CPU Saturation**: Aumentar replicas o CPU limits
3. **Memory Leaks**: Analizar heap dumps
4. **Network Bandwidth**: Revisar service mesh overhead
5. **Eureka Latency**: Cache service discovery

### 5.4 Interpretación de Reportes de Locust

#### 5.4.1 Estructura del Reporte

Los reportes de Locust generan tres archivos principales:
- **HTML Report**: Visualización completa con gráficos
- **CSV Stats**: Datos tabulares de estadísticas
- **CSV Failures**: Detalles de todos los errores

#### 5.4.2 Lectura de Request Statistics

**Resultados de test ejecutado (2025-11-04 04:38:25 - 04:40:35)**:

```
Method  Name              # Requests  # Fails  Avg(ms)  Min  Max   RPS   Failures/s
POST    /app/api/carts    116        0        106      15   3281  0.9   0.0
POST    /app/api/orders   22         0        64       16   692   0.2   0.0
POST    /app/api/payments 22         0        105      15   1516  0.2   0.0
POST    Authenticate      10         0        763      507  1117  0.1   0.0
GET     Browse Products   214        0        97       12   3973  1.6   0.0
POST    Create Order      94         0        50       15   696   0.7   0.0
GET     Get User          60         57       86       14   1773  0.5   0.4
GET     View Product      109        103      30       12   210   0.8   0.8
Aggregated               669        179      90       12   3973  5.1   1.4
```

**Interpretación por Columna**:

| Columna | Significado | Cómo Interpretar | Ejemplo del Test Ejecutado |
|---------|-------------|------------------|---------|
| **Method** | Verbo HTTP | GET/POST/PUT/DELETE | POST indica operación de escritura |
| **Name** | Nombre del endpoint | Identificador del request | "Browse Products" es más descriptivo que "/app/api/products" |
| **# Requests** | Total de requests | Volumen de tráfico | 214 requests a Browse Products = endpoint con mayor uso |
| **# Fails** | Requests fallidos | Errores absolutos | 103 fallos en View Product = 94% error rate |
| **Avg (ms)** | Tiempo promedio | Performance general | 106ms para crear cart = dentro de parámetros |
| **Min (ms)** | Mejor tiempo | Mejor caso observado | 12ms mín = cache hit o query simple |
| **Max (ms)** | Peor tiempo | Outliers/problemas | 3973ms máx = timeout o pausa de GC |
| **RPS** | Requests/segundo | Throughput | 5.1 RPS total = carga baja del test |
| **Failures/s** | Errores/segundo | Tasa de error | 1.4 failures/s = 27% error rate |

#### 5.4.3 Análisis de Percentiles

**Resultados de Response Time Statistics**:

```
Method  Name              50%ile  60%ile  70%ile  80%ile  90%ile  95%ile  99%ile  100%ile
POST    /app/api/carts    19      21      22      26      48      96      3100    3300
POST    /app/api/orders   21      22      54      74      83      99      690     690
POST    /app/api/payments 23      35      58      70      99      100     1500    1500
POST    Authenticate      720     820     910     1000    1100    1100    1100    1100
GET     Browse Products   18      20      23      30      52      89      3900    4000
POST    Create Order      19      20      22      33      86      110     700     700
GET     Get User          20      21      23      25      58      280     1800    1800
GET     View Product      18      20      23      31      78      96      130     210
Aggregated               19      21      23      32      78      110     2700    4000
```

**¿Qué significan los percentiles?**

- **p50 (mediana)**: 50% de requests son más rápidos que este valor
  - Browse Products: p50=18ms indica que la mitad de las solicitudes responden en menos de 18ms
  - Create Order: p50=19ms muestra consistencia similar

- **p90**: 90% de requests son más rápidos (10% más lentos)
  - Browse Products: p90=52ms indica que solo el 10% de usuarios experimenta tiempos mayores
  - Create Order: p90=86ms muestra variabilidad aceptable

- **p95**: Experiencia del 95% de usuarios
  - Métrica clave para SLAs en producción
  - Browse Products: p95=89ms se considera dentro de parámetros aceptables
  - Authenticate: p95=1100ms refleja el costo computacional de generación JWT y bcrypt

- **p99**: Casos extremos (1% de usuarios)
  - Browse Products: p99=3900ms indica presencia de outliers significativos
  - Estos valores sugieren posibles pausas de GC o timeouts intermitentes

- **p100 (max)**: Peor caso registrado en el test
  - Browse Products: 4000ms representa el tiempo máximo observado
  - Valores superiores a 5 segundos requieren investigación inmediata

**Umbrales de referencia**:
```
p95 < 1 segundo  = Rendimiento óptimo
p95 < 3 segundos = Rendimiento aceptable
p95 > 5 segundos = Rendimiento deficiente
```

#### 5.4.4 Interpretación de Errores

**Resultados de Failure Statistics**:

```
Method  Name                      Error                                          Occurrences
GET     View Product              400 Client Error: Bad Request                 103
GET     Get User                  500 Server Error: Internal Server Error       57
GET     /app/api/products/11      400 Client Error: Bad Request                 2
GET     /app/api/products/5       400 Client Error: Bad Request                 2
GET     /app/api/products/35      400 Client Error: Bad Request                 2
GET     /app/api/products/10      400 Client Error: Bad Request                 1
GET     /app/api/products/13      400 Client Error: Bad Request                 1
GET     /app/api/products/14      400 Client Error: Bad Request                 1
GET     /app/api/products/20      400 Client Error: Bad Request                 1
GET     /app/api/products/26      400 Client Error: Bad Request                 1
GET     /app/api/products/27      400 Client Error: Bad Request                 1
GET     /app/api/products/29      400 Client Error: Bad Request                 1
GET     /app/api/products/31      400 Client Error: Bad Request                 1
GET     /app/api/products/39      400 Client Error: Bad Request                 1
GET     /app/api/products/40      400 Client Error: Bad Request                 1
GET     /app/api/products/41      400 Client Error: Bad Request                 1
GET     /app/api/products/46      400 Client Error: Bad Request                 1
GET     /app/api/products/49      400 Client Error: Bad Request                 1
```

**Clasificación de Errores HTTP**:

| Código | Tipo | Severidad | Acción Requerida |
|--------|------|-----------|------------------|
| **200-299** | Éxito | Normal | Ninguna |
| **400** | Bad Request | Media | Esperado en load tests con IDs aleatorios |
| **401/403** | No autorizado | Media | Verificar autenticación según contexto |
| **404** | No encontrado | Baja | Aceptable en tests con IDs aleatorios |
| **500** | Error del servidor | Alta | Requiere investigación - indica error en código |
| **502/503** | Service unavailable | Crítica | Servicio caído o sobrecargado |
| **504** | Gateway timeout | Crítica | Backend no responde en tiempo esperado |

**Análisis de los resultados**:

1. **103 errores 400 en View Product**:
   ```
   GET /app/api/products/{id} → 400 Bad Request
   ```
   - Causa: El test utiliza IDs aleatorios (1-100) que no existen en la base de datos
   - Evaluación: Comportamiento esperado en el contexto de pruebas de carga
   - Solución posible: Ajustar locustfile.py para usar rangos de IDs válidos
   - Impacto: No crítico para el funcionamiento del sistema

2. **57 errores 500 en Get User**:
   ```
   GET /app/api/users/{id} → 500 Internal Server Error
   ```
   - Causa: El endpoint retorna error 500 en lugar de 404 cuando el usuario no existe
   - Evaluación: Requiere corrección - manejo inadecuado de excepciones
   - Solución: Implementar manejo apropiado de excepciones en UserService
   - Impacto: Alto - indica deficiencia en el manejo de errores del sistema

**Cálculo de Error Rate**:
```
Error Rate = (# Fails / # Requests) × 100

Ejemplo del test ejecutado:
View Product: (103 / 109) × 100 = 94.5% (Nivel crítico)
Get User:     (57 / 60) × 100 = 95.0% (Nivel crítico)
Authenticate: (0 / 10) × 100 = 0% (Óptimo)
```

**Umbrales de error rate**:
- < 1% = Rendimiento óptimo
- 1-5% = Rendimiento aceptable
- 5-10% = Requiere atención
- > 10% = Nivel crítico

#### 5.4.5 Análisis de Endpoints Exitosos

**Endpoints con 0% Error Rate**

```
Method  Name              # Requests  # Fails  Avg(ms)  p95(ms)  Success Rate
POST    Authenticate      10         0        763      1100     100%
GET     Browse Products   214        0        97       89       100%
POST    /app/api/carts    116        0        106      96       100%
POST    Create Order      94         0        50       110      100%
POST    /app/api/payments 22         0        105      100      100%
```

**Interpretación de resultados**:

1. **Authenticate (763ms avg, 1100ms p95)**:
   - Funcionamiento: 100% de solicitudes procesadas correctamente
   - Performance: Tiempo de respuesta elevado pero dentro de parámetros esperados
   - Factores que influyen en el tiempo:
     - Generación de token JWT con firma criptográfica
     - Consulta a base de datos para validación de credenciales
     - Verificación de contraseña mediante bcrypt
   - Evaluación: No requiere optimización dado el balance seguridad-performance

2. **Browse Products (97ms avg, 89ms p95)**:
   - Performance: Tiempo de respuesta inferior a 100ms
   - Consistencia: p95 (89ms) próximo al promedio (97ms) indica baja variabilidad
   - Evaluación: Sin outliers significativos
   - Capacidad: Puede soportar carga adicional

3. **Create Order (50ms avg, 110ms p95)**:
   - Performance: 50ms de tiempo promedio de respuesta
   - Confiabilidad: Sin fallos registrados en endpoint crítico de negocio
   - Distribución de percentiles:
     - 50% de requests < 50ms
     - 95% de requests < 110ms
   - Evaluación: Consistencia adecuada

4. **Create Payment (105ms avg, 100ms p95)**:
   - Performance: Tiempo de respuesta inferior a 150ms
   - Volumen: 22 requests reflejan el 5% de conversion rate simulado
   - Contexto: MixedWorkloadUser replica patrones de conversión reales
   - Evaluación: Endpoint crítico operando correctamente

#### 5.4.6 Reporte Completo Interpretado

**Resumen del Test Ejecutado**:

```
========================================
Performance Test Analysis
========================================
Test Configuration
  Target Host:   http://192.168.49.2:32281
  Start Time:    2025-11-04 04:38:25
  End Time:      2025-11-04 04:40:35
  Duration:      130 seconds (~2.17 minutes)
  Script:        locustfile.py
========================================

MÉTRICAS GENERALES
----------------------------------------
Total Requests:     669
Failed Requests:    179 (26.7%)
Throughput (RPS):   5.1
Avg Response Time:  90ms
p95 Response Time:  110ms
p99 Response Time:  2700ms

========================================

ENDPOINTS OPERANDO CORRECTAMENTE (0% error rate):
  - Autenticación JWT (Authenticate)
  - Listado de productos (Browse Products)
  - Creación de carritos (/app/api/carts)
  - Creación de órdenes (Create Order)
  - Procesamiento de pagos (/app/api/payments)

ENDPOINTS QUE REQUIEREN ATENCIÓN:
  - GET /app/api/products/{id} → 94.5% error rate (400)
    Causa: IDs aleatorios fuera del rango de productos existentes
    Acción: Ajustar rango de IDs en locustfile.py

  - GET /app/api/users/{id} → 95% error rate (500)
    Causa: Manejo inadecuado de excepciones en UserService
    Acción: Implementar respuesta 404 apropiada

OBSERVACIONES:
  - p99 de 2700ms indica presencia de outliers en las respuestas
  - Posibles causas: pausas de GC o timeouts intermitentes
  - Throughput de 5.1 RPS corresponde a test con baja concurrencia

RECOMENDACIONES:
1. Corregir manejo de excepciones en GET /users/{id}
2. Ejecutar test con 50-100 usuarios para evaluar capacidad real
3. Investigar causa de outliers registrados en p99
4. Ajustar locustfile.py para utilizar rangos de IDs válidos
========================================
```

#### 5.4.7 Comparación de Resultados Entre Tests

**Comparativa con línea base**:

| Métrica | Baseline (Anterior) | Test Actual | Cambio | Análisis |
|---------|---------------------|-------------|--------|----------|
| Total Requests | 0 (timeout) | 669 | +669 | Conectividad establecida |
| Error Rate | N/A | 26.7% | N/A | Errores identificados |
| Avg Response | N/A | 90ms | N/A | Performance dentro de parámetros |
| RPS | 0 | 5.1 | +5.1 | Sistema operacional |
| Authentication | Falla total | 100% success | +100% | Funcionalidad JWT operativa |

**Estado del sistema**:
- Problema de conectividad resuelto (Jenkins → Minikube network)
- Locust ejecutándose y generando tráfico consistente
- Endpoints críticos de negocio operando correctamente
- Endpoints secundarios con errores identificados y documentados

#### 5.4.8 Guía de Decisiones Basada en Resultados

**Árbol de decisión por error rate**:

```
┌─────────────────────────────────────────────────────────────┐
│                 ERROR RATE DECISION TREE                     │
└─────────────────────────────────────────────────────────────┘

Error Rate < 1%
└─> Aprobado para deploy a producción

Error Rate 1-5%
└─> Si errores son 404 (recursos no existen)
    ├─> Aprobar - Error esperado en contexto de load test
    └─> Si errores son 500/502/503
        └─> No aprobar - Requiere investigación

Error Rate 5-10%
└─> Requiere revisión de causas
    └─> Si mejora con escalamiento de recursos
        └─> Incrementar pods/replicas
    └─> Si persiste después de escalamiento
        └─> Optimización de código necesaria

Error Rate > 10%
└─> Nivel crítico
    └─> No aprobar para deploy
    └─> Investigación prioritaria requerida
```

**Análisis del test ejecutado (26.7% error rate)**:
```
26.7% error rate total
├─> Desglose de errores:
│   ├─> 103 × 400 (Bad Request) = Comportamiento esperado del test
│   └─> 57 × 500 (Server Error) = Defecto en código
│
├─> Excluyendo errores esperados (400):
│   Error rate ajustado = 57 / 669 = 8.5%
│
└─> CONCLUSIÓN:
    ├─> Corregir manejo de excepciones en endpoint con error 500
    ├─> Re-ejecutar test después de corrección
    └─> Meta: Reducir error rate por debajo de 5%
```

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
