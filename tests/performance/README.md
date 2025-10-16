# Performance Tests with Locust

Este directorio contiene las pruebas de rendimiento y estrés para el sistema de e-commerce usando **Locust**.

## Contenido

- `locustfile.py` - Definición de pruebas de carga y estrés
- `requirements.txt` - Dependencias de Python
- Este README - Documentación de uso

## Instalación

```bash
cd tests/performance
pip install -r requirements.txt
```

## Pruebas Disponibles

### 1. ProductServiceLoadTest
Prueba de carga para el servicio de productos.

**Escenario:** Usuarios navegando el catálogo de productos

**Acciones:**
- Ver todos los productos (peso: 5)
- Ver detalles de producto (peso: 3)
- Navegar categorías (peso: 2)
- Ver detalles de categoría (peso: 1)

**Métricas esperadas:**
- GET /products: < 500ms (p95)
- GET /products/{id}: < 300ms (p95)
- GET /categories: < 200ms (p95)

**Uso:**
```bash
locust -f locustfile.py ProductServiceLoadTest \
       --host=http://localhost:8080 \
       --users 50 --spawn-rate 5 --run-time 2m
```

### 2. OrderServiceStressTest
Prueba de estrés para el servicio de órdenes.

**Escenario:** Black Friday / alta demanda de órdenes

**Acciones:**
- Crear órdenes (peso: 4)
- Ver lista de órdenes (peso: 2)
- Ver detalles de orden (peso: 1)

**Métricas esperadas:**
- POST /orders: < 1000ms (p95)
- GET /orders: < 500ms (p95)
- GET /orders/{id}: < 300ms (p95)

**Uso:**
```bash
locust -f locustfile.py OrderServiceStressTest \
       --host=http://localhost:8080 \
       --users 100 --spawn-rate 10 --run-time 3m
```

### 3. UserAuthenticationLoadTest
Prueba de carga para autenticación de usuarios.

**Escenario:** Múltiples usuarios registrándose y accediendo

**Acciones:**
- Registro de usuarios (peso: 3)
- Login (peso: 5)
- Obtener perfil (peso: 2)

**Métricas esperadas:**
- POST /register: < 1500ms (p95)
- POST /login: < 800ms (p95)
- GET /users/{id}: < 300ms (p95)

**Uso:**
```bash
locust -f locustfile.py UserAuthenticationLoadTest \
       --host=http://localhost:8080 \
       --users 30 --spawn-rate 3 --run-time 2m
```

### 4. CompletePurchaseFlow
Flujo completo de compra (E2E).

**Escenario:** Usuario completa todo el proceso de compra

**Pasos secuenciales:**
1. Navegar productos
2. Ver detalles de producto
3. Crear carrito
4. Crear orden
5. Procesar pago
6. Crear envío

**Uso:**
```bash
locust -f locustfile.py ECommercePurchaseUser \
       --host=http://localhost:8080 \
       --users 10 --spawn-rate 1 --run-time 5m
```

### 5. MixedWorkloadUser
Carga mixta realista.

**Escenario:** Distribución realista de comportamientos de usuario

**Distribución:**
- 60% navegando productos
- 20% creando órdenes
- 15% autenticándose
- 5% completando compras

**Uso:**
```bash
locust -f locustfile.py MixedWorkloadUser \
       --host=http://localhost:8080 \
       --users 100 --spawn-rate 10 --run-time 5m
```

## Ejecución

### Con Interfaz Web (recomendado)

```bash
locust -f locustfile.py --host=http://localhost:8080
```

Luego abre http://localhost:8089 en tu navegador y configura:
- Number of users: 100
- Spawn rate: 10
- Host: http://localhost:8080 (o tu API Gateway)

### Sin Interfaz (headless)

```bash
locust -f locustfile.py \
       --host=http://localhost:8080 \
       --users 100 \
       --spawn-rate 10 \
       --run-time 5m \
       --headless \
       --html report.html
```

### Apuntando a Kubernetes

```bash
# Obtener la URL del API Gateway en Kubernetes
kubectl get service api-gateway -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Ejecutar pruebas
locust -f locustfile.py \
       --host=http://<API-GATEWAY-URL> \
       --users 200 \
       --spawn-rate 20 \
       --run-time 10m \
       --headless
```

### Apuntando a AWS EKS

```bash
# Obtener URL del Load Balancer
kubectl get svc -n production

# Ejecutar pruebas de carga
locust -f locustfile.py MixedWorkloadUser \
       --host=http://a1b2c3d4e5f6.us-east-1.elb.amazonaws.com \
       --users 500 \
       --spawn-rate 50 \
       --run-time 15m \
       --headless \
       --html performance-report.html \
       --csv performance-results
```

## Escenarios de Prueba

### Prueba de Carga Normal
Simula tráfico normal de usuarios.

```bash
locust -f locustfile.py MixedWorkloadUser \
       --host=http://localhost:8080 \
       --users 50 \
       --spawn-rate 5 \
       --run-time 10m
```

**Expectativa:** Todos los servicios responden con < 1s (p95)

### Prueba de Estrés
Encuentra el punto de quiebre del sistema.

```bash
locust -f locustfile.py \
       --host=http://localhost:8080 \
       --users 500 \
       --spawn-rate 50 \
       --run-time 20m
```

**Objetivo:** Identificar límites de capacidad

### Prueba de Spike
Simula pico repentino de tráfico.

```bash
locust -f locustfile.py OrderServiceStressTest \
       --host=http://localhost:8080 \
       --users 1000 \
       --spawn-rate 100 \
       --run-time 5m
```

**Escenario:** Flash sale, campaña viral

### Prueba de Resistencia (Soak Test)
Verifica estabilidad a largo plazo.

```bash
locust -f locustfile.py MixedWorkloadUser \
       --host=http://localhost:8080 \
       --users 100 \
       --spawn-rate 10 \
       --run-time 4h
```

**Objetivo:** Detectar memory leaks, degradación

## Métricas Clave

### Tiempos de Respuesta
- **p50 (mediana):** 50% de requests más rápidos que este valor
- **p95:** 95% de requests más rápidos que este valor
- **p99:** 99% de requests más rápidos que este valor

### Throughput
- **RPS (Requests Per Second):** Capacidad del sistema
- **Concurrent Users:** Usuarios simultáneos soportados

### Errores
- **Error Rate:** % de requests fallidos
- **Timeout Rate:** % de requests que exceden tiempo límite

## Análisis de Resultados

### Valores Aceptables (SLA)

| Métrica | Valor Objetivo |
|---------|----------------|
| p95 Response Time | < 1000ms |
| p99 Response Time | < 2000ms |
| Error Rate | < 0.1% |
| Throughput | > 1000 RPS |

### Generar Reporte HTML

```bash
locust -f locustfile.py \
       --host=http://localhost:8080 \
       --users 200 \
       --spawn-rate 20 \
       --run-time 10m \
       --headless \
       --html report-$(date +%Y%m%d-%H%M%S).html
```

### Exportar Datos CSV

```bash
locust -f locustfile.py \
       --host=http://localhost:8080 \
       --users 100 \
       --spawn-rate 10 \
       --run-time 5m \
       --headless \
       --csv results/performance
```

Esto genera:
- `performance_stats.csv` - Estadísticas por endpoint
- `performance_stats_history.csv` - Histórico de métricas
- `performance_failures.csv` - Log de errores

## Integración con CI/CD

### En Jenkinsfile.stage

```groovy
stage('Performance Tests') {
    steps {
        sh '''
            cd tests/performance
            pip install -r requirements.txt
            locust -f locustfile.py \
                   --host=http://staging-api \
                   --users 100 \
                   --spawn-rate 10 \
                   --run-time 5m \
                   --headless \
                   --html performance-report.html
        '''

        publishHTML([
            reportDir: 'tests/performance',
            reportFiles: 'performance-report.html',
            reportName: 'Performance Test Report'
        ])
    }
}
```

## Troubleshooting

### Error: "Connection refused"
- Verifica que los servicios estén corriendo
- Verifica la URL del host
- Verifica que el API Gateway esté accesible

### Error: "Max retries exceeded"
- El sistema está sobrecargado
- Reduce número de usuarios o spawn rate
- Aumenta recursos del cluster

### Respuestas muy lentas
- Verifica logs de los servicios
- Revisa métricas de CPU/Memoria
- Verifica conexiones a base de datos

## Mejores Prácticas

1. **Comenzar pequeño:** Inicia con pocos usuarios y aumenta gradualmente
2. **Monitor en paralelo:** Observa métricas del sistema (CPU, RAM, red)
3. **Ambiente aislado:** No ejecutes en producción sin avisar
4. **Datos realistas:** Usa datos similares a producción
5. **Repetir pruebas:** Ejecuta múltiples veces para validar resultados

## Referencias

- [Locust Documentation](https://docs.locust.io/)
- [Performance Testing Best Practices](https://www.blazemeter.com/blog/performance-testing-best-practices)
