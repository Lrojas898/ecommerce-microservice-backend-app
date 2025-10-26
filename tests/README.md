# E2E Tests - Ecommerce Microservices

Este directorio contiene las pruebas End-to-End (E2E) para validar el funcionamiento completo de la arquitectura de microservicios.

## Estructura del Proyecto

```
tests/
├── pom.xml                           # Configuración Maven
├── src/
│   └── test/
│       └── java/
│           └── com/selimhorri/app/e2e/
│               ├── UserRegistrationE2ETest.java       # Tests de registro y login
│               ├── ProductBrowsingE2ETest.java        # Tests de catálogo de productos
│               ├── OrderCreationE2ETest.java          # Tests de creación de órdenes
│               ├── PaymentProcessingE2ETest.java      # Tests de procesamiento de pagos
│               └── ShippingFulfillmentE2ETest.java    # Tests de envío y fulfillment
└── README.md                         # Este archivo
```

## Configuración

### Prerrequisitos

- Java 11+
- Maven 3.6+
- kubectl configurado (para obtener automáticamente la URL del API Gateway)
- Servicios desplegados en Kubernetes (namespace `dev`)

### Variables de Entorno

Los tests usan la siguiente variable de entorno:

- `API_URL`: URL del API Gateway (default: `http://localhost:8080`)

Si estás ejecutando contra el cluster de Kubernetes en AWS:
```bash
export API_URL="http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com"
```

## Ejecución de Tests

### Opción 1: Script Automático (Recomendado)

Desde el directorio raíz del proyecto:

```bash
./run-e2e-tests.sh
```

Este script:
- Obtiene automáticamente la URL del API Gateway desde Kubernetes
- Verifica la conectividad con el API Gateway
- Verifica que los servicios estén registrados en Eureka
- Ejecuta todos los tests E2E con Maven

### Opción 2: Ejecución Manual con Maven

Desde el directorio `tests/`:

```bash
# Con variable de entorno
export API_URL="http://<tu-api-gateway-url>"
mvn clean test

# O directamente en el comando
mvn clean test -DAPI_URL="http://<tu-api-gateway-url>"
```

### Opción 3: Ejecutar Tests Individuales

```bash
# Un test específico
mvn test -Dtest=UserRegistrationE2ETest

# Un método específico
mvn test -Dtest=UserRegistrationE2ETest#completeUserRegistrationFlow_shouldSucceed
```

## Tests Disponibles

### 1. UserRegistrationE2ETest
Prueba el flujo completo de registro y autenticación de usuarios:
- ✓ Registro de nuevo usuario
- ✓ Login con credenciales
- ✓ Obtención de perfil de usuario autenticado

**Servicios involucrados:** `user-service`

### 2. ProductBrowsingE2ETest
Prueba la navegación y búsqueda de productos:
- ✓ Lista de todos los productos
- ✓ Detalles de producto individual
- ✓ Búsqueda por categoría
- ✓ Agregar productos a favoritos
- ✓ Obtener favoritos del usuario

**Servicios involucrados:** `product-service`, `favourite-service`

### 3. OrderCreationE2ETest
Prueba la creación y gestión de órdenes:
- ✓ Creación de carrito
- ✓ Creación de orden desde carrito
- ✓ Obtención de detalles de orden
- ✓ Lista de todas las órdenes

**Servicios involucrados:** `order-service`

### 4. PaymentProcessingE2ETest
Prueba el procesamiento de pagos:
- ✓ Creación de pago para una orden
- ✓ Actualización del estado de pago
- ✓ Obtención de detalles de pago con información de orden
- ✓ Lista de todos los pagos

**Servicios involucrados:** `order-service`, `payment-service`

### 5. ShippingFulfillmentE2ETest
Prueba el flujo completo de fulfillment:
- ✓ Creación de items de envío después de pago confirmado
- ✓ Obtención de items por orden
- ✓ Flujo completo: Orden → Pago → Envío
- ✓ Lista de todos los items de envío

**Servicios involucrados:** `order-service`, `payment-service`, `shipping-service`

## Rutas de API Configuradas

Los tests están configurados para usar las siguientes rutas a través del API Gateway:

| Servicio | Ruta Base |
|----------|-----------|
| User Service | `/user-service/api/*` |
| Product Service | `/product-service/api/*` |
| Order Service | `/order-service/api/*` |
| Payment Service | `/payment-service/api/*` |
| Shipping Service | `/shipping-service/api/*` |
| Favourite Service | `/favourite-service/api/*` |

## Troubleshooting

### Error: Connection refused

Si obtienes errores de conexión:

1. Verifica que los servicios estén corriendo:
   ```bash
   kubectl get pods -n dev
   ```

2. Verifica que el API Gateway tenga un LoadBalancer:
   ```bash
   kubectl get svc api-gateway -n dev
   ```

3. Verifica la conectividad:
   ```bash
   curl http://<api-gateway-url>/actuator/health
   ```

### Error 500 en los endpoints

Si los servicios devuelven error 500:

1. Revisa los logs del servicio:
   ```bash
   kubectl logs -n dev deployment/<service-name> --tail=100
   ```

2. Verifica que el profile sea correcto:
   ```bash
   kubectl describe deployment <service-name> -n dev | grep SPRING_PROFILES_ACTIVE
   ```

3. Verifica que los servicios estén registrados en Eureka:
   ```bash
   curl http://<api-gateway-url>/actuator/health | jq .components.discoveryComposite
   ```

### Error 404 - Not Found

Si obtienes 404, verifica que las rutas en el API Gateway estén correctamente configuradas:
```bash
kubectl get configmap -n dev
kubectl describe configmap <api-gateway-config> -n dev
```

## Reportes de Tests

Los reportes de Maven se generan en:
```
tests/target/surefire-reports/
```

Para ver un resumen:
```bash
cat tests/target/surefire-reports/*.txt
```

## Integración con CI/CD

Para integrar con Jenkins u otro sistema de CI/CD:

```bash
# Ejecutar y generar reporte XML
mvn clean test -DAPI_URL="${API_GATEWAY_URL}"

# El código de salida será 0 si todos los tests pasan, ≠0 si alguno falla
echo $?
```

## Notas Importantes

- Los tests crean datos de prueba en las bases de datos H2 en memoria
- Los tests son independientes entre sí y pueden ejecutarse en paralelo
- Algunos tests esperan códigos de estado flexibles (200 o 201) para acomodar diferentes implementaciones
- Los tests usan RestAssured para realizar las peticiones HTTP
- Los tests validan tanto el éxito de las operaciones como la estructura de las respuestas

## Contacto y Soporte

Para reportar problemas o sugerencias sobre los tests E2E, por favor crea un issue en el repositorio del proyecto.
