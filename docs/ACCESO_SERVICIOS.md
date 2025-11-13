# Guía de Acceso a Servicios en Kubernetes

**Cluster:** DigitalOcean Kubernetes (DOKS)
**IP del Load Balancer:** `137.184.240.48`
**Fecha:** 2025-11-13

---

## 📊 Estado General del Cluster

### ✅ Todos los servicios están ACTIVOS y funcionando

**Namespaces activos:**
- `dev` - Ambiente de desarrollo
- `prod` - Ambiente de producción
- `monitoring` - Grafana, Prometheus, Alertmanager

**Pods en ejecución:**
- ✅ Dev: 9/9 pods Running
- ✅ Prod: 10/10 pods Running (incluye PostgreSQL)
- ✅ Monitoring: 3/3 servicios activos

---

## 🌐 URLs de Acceso

### Servicios de Monitoreo (Namespace: monitoring)

**Grafana:**
```
http://137.184.240.48/grafana/
```
- 📊 Dashboard de visualización de métricas
- 🔐 Requiere autenticación
- ✅ Status: **200 OK** (Redirect to login)

**Prometheus:**
```
http://137.184.240.48/prometheus/
```
- 📈 Sistema de métricas y alertas
- 🔍 Query interface para métricas
- ✅ Status: **Accesible**

**Alertmanager:**
```
http://137.184.240.48/alertmanager/
```
- 🚨 Gestión de alertas
- 🔔 Configuración de notificaciones
- ✅ Status: **Accesible**

---

### Servicios E-Commerce - Desarrollo (Namespace: dev)

**Base URL:** `http://137.184.240.48/dev/`

#### API Gateway
```
http://137.184.240.48/dev/app/api/
```

#### Productos (Product Service)
```bash
# Listar productos
curl http://137.184.240.48/dev/app/api/products

# Respuesta ejemplo:
{
  "collection": [
    {
      "productId": 1,
      "productTitle": "asus",
      "imageUrl": "xxx",
      "sku": "dfqejklejrkn",
      "priceUnit": 599.99,
      "quantity": 50,
      "category": {
        "categoryId": 1,
        "categoryTitle": "Computer"
      }
    }
  ]
}
```
✅ Status: **200 OK**

#### Health Checks (Actuator)
```bash
# Order Service Health
curl http://137.184.240.48/dev/order-service/actuator/health

# Response:
{
  "status": "UP",
  "components": {
    "circuitBreakers": {
      "status": "UP",
      "details": {
        "orderService": {
          "status": "UP",
          "state": "CLOSED"
        }
      }
    },
    "db": {
      "status": "UP",
      "details": {
        "database": "H2"
      }
    },
    "discoveryComposite": {
      "status": "UP",
      "details": {
        "services": [
          "favourite-service",
          "proxy-client",
          "payment-service",
          "product-service",
          "shipping-service",
          "order-service",
          "user-service",
          "api-gateway"
        ]
      }
    }
  }
}
```
✅ Status: **200 OK**

#### Otros Servicios Disponibles

**User Service:**
```
http://137.184.240.48/dev/user-service/api/users
```

**Order Service:**
```
http://137.184.240.48/dev/order-service/api/orders
```

**Payment Service:**
```
http://137.184.240.48/dev/payment-service/api/payments
```

**Shipping Service:**
```
http://137.184.240.48/dev/shipping-service/api/shipping
```

**Favourite Service:**
```
http://137.184.240.48/dev/favourite-service/api/favourites
```

**Proxy Client (Frontend):**
```
http://137.184.240.48/dev/app/
```

---

### Servicios E-Commerce - Producción (Namespace: prod)

**Base URL:** `http://137.184.240.48/`

**Nota:** El namespace prod NO tiene el prefijo `/dev/` en las rutas.

```bash
# Ejemplo productos en prod
curl http://137.184.240.48/app/api/products
```

---

## 🔧 Configuración de Ingress

### Dev Environment

```yaml
Path Pattern: /dev(/|$)(.*)
Backend: api-gateway:80
Rewrite Target: /$2
Annotations:
  - CORS enabled (allow all origins)
  - Max body size: 50MB
  - Regex matching enabled
```

### Monitoring

```yaml
Grafana:     /grafana(/|$)(.*)     → grafana:3000
Prometheus:  /prometheus(/|$)(.*)  → prometheus:9090
Alertmanager: /alertmanager(/|$)(.*) → alertmanager:9093
Rewrite Target: /$2
```

---

## 🎯 Comparación: Acceso Similar a Grafana/Prometheus

| Aspecto | Grafana/Prometheus | Servicios E-Commerce Dev |
|---------|-------------------|--------------------------|
| **IP del Load Balancer** | `137.184.240.48` | `137.184.240.48` ✅ |
| **Ingress Controller** | NGINX | NGINX ✅ |
| **Path Rewrite** | `/$2` | `/$2` ✅ |
| **CORS** | No configurado | Habilitado ✅ |
| **Método de Acceso** | HTTP público | HTTP público ✅ |
| **URL Pattern** | `/grafana/...` | `/dev/...` ✅ |
| **Estado** | Activo | Activo ✅ |

**Conclusión:** ✅ **Los servicios de e-commerce son accesibles exactamente de la misma manera que Grafana y Prometheus**

---

## 📝 Ejemplos de Uso con curl

### 1. Verificar Health de Todos los Servicios

```bash
# Order Service
curl http://137.184.240.48/dev/order-service/actuator/health | jq '.status'

# Product Service
curl http://137.184.240.48/dev/product-service/actuator/health | jq '.status'

# User Service
curl http://137.184.240.48/dev/user-service/actuator/health | jq '.status'

# Payment Service
curl http://137.184.240.48/dev/payment-service/actuator/health | jq '.status'
```

### 2. Obtener Datos de Productos

```bash
# Todos los productos
curl http://137.184.240.48/dev/app/api/products | jq '.'

# Producto específico (ID 1)
curl http://137.184.240.48/dev/app/api/products/1 | jq '.'
```

### 3. Verificar Service Discovery

```bash
# Ver servicios registrados en Eureka
curl http://137.184.240.48/dev/order-service/actuator/health | jq '.components.discoveryComposite.components.eureka.details.applications'
```

### 4. Obtener Métricas de Prometheus

```bash
# Métricas de un servicio específico
curl 'http://137.184.240.48/prometheus/api/v1/query?query=up{job="order-service"}'
```

---

## 🔐 Acceso Vía Port-Forward (Alternativo)

Si prefieres acceso directo sin Ingress:

```bash
# API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:80

# Acceder localmente
curl http://localhost:8080/app/api/products

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

---

## 🧪 Testing con Postman/Insomnia

### Collection Base

```json
{
  "base_url": "http://137.184.240.48",
  "dev_prefix": "/dev",
  "endpoints": {
    "products_list": "{{base_url}}{{dev_prefix}}/app/api/products",
    "product_detail": "{{base_url}}{{dev_prefix}}/app/api/products/:id",
    "orders_list": "{{base_url}}{{dev_prefix}}/app/api/orders",
    "health_order": "{{base_url}}{{dev_prefix}}/order-service/actuator/health"
  }
}
```

---

## 🚨 Troubleshooting

### Si un servicio no responde:

1. **Verificar estado del pod:**
```bash
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
```

2. **Ver logs:**
```bash
kubectl logs -f <pod-name> -n dev
```

3. **Verificar Ingress:**
```bash
kubectl describe ingress ecommerce-ingress-dev -n dev
```

4. **Probar acceso interno (desde otro pod):**
```bash
kubectl run test-pod --rm -i --tty --image=busybox -n dev -- sh
wget -O- http://api-gateway/app/api/products
```

### Código HTTP comunes:

- **200 OK** - Servicio funcionando correctamente ✅
- **302 Redirect** - Redirección (normal en Grafana) ✅
- **404 Not Found** - Ruta incorrecta o servicio no existe ❌
- **500 Internal Server Error** - Error en el servicio ❌
- **502 Bad Gateway** - Pod no está listo o caído ❌
- **503 Service Unavailable** - Servicio temporalmente no disponible ❌

---

## 📊 Resumen de Servicios ClusterIP

| Namespace | Servicio | Cluster IP | Puerto | Pods Running |
|-----------|----------|------------|--------|--------------|
| dev | api-gateway | 10.245.199.106 | 80 | 1/1 ✅ |
| dev | service-discovery | 10.245.233.156 | 8761 | 1/1 ✅ |
| dev | user-service | 10.245.140.137 | 8081 | 1/1 ✅ |
| dev | product-service | 10.245.165.180 | 8082 | 1/1 ✅ |
| dev | order-service | 10.245.136.162 | 8083 | 1/1 ✅ |
| dev | payment-service | 10.245.49.100 | 8084 | 1/1 ✅ |
| dev | shipping-service | 10.245.33.21 | 8085 | 1/1 ✅ |
| dev | favourite-service | 10.245.182.25 | 8086 | 1/1 ✅ |
| dev | proxy-client | 10.245.59.130 | 8080 | 1/1 ✅ |
| monitoring | grafana | 10.245.44.150 | 3000 | 1/1 ✅ |
| monitoring | prometheus | 10.245.220.125 | 9090 | 1/1 ✅ |
| monitoring | alertmanager | 10.245.84.179 | 9093 | 1/1 ✅ |

---

## ✅ Conclusión

**RESPUESTA A TU PREGUNTA:**

**SÍ, los servicios del e-commerce están activos y se pueden acceder EXACTAMENTE de la misma forma que Grafana y Prometheus.**

- ✅ Misma IP del Load Balancer: `137.184.240.48`
- ✅ Mismo Ingress Controller: NGINX
- ✅ Mismo patrón de URL con rewrite
- ✅ Todos los pods Running y Health OK
- ✅ Acceso HTTP público funcionando

**Diferencias:**
- Grafana/Prometheus: Ruta `/grafana/`, `/prometheus/`
- E-Commerce Dev: Ruta `/dev/`
- E-Commerce Prod: Ruta `/`

---

**Documento generado:** 2025-11-13
**Última verificación:** 2025-11-13 (Todos los servicios UP)
