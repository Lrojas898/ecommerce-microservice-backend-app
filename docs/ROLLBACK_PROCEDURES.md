# Procedimientos de Rollback – Plataforma E‑Commerce Microservicios

## 1. Objetivo y Alcance

Este documento describe los procedimientos formales de rollback para la plataforma de e‑commerce basada en microservicios desplegada en Kubernetes (DigitalOcean Kubernetes – DOKS). El objetivo es restaurar el servicio a un estado estable conocido minimizando el impacto en los usuarios y el negocio.

Los procedimientos cubren:

- Rollback de despliegues individuales de microservicios.
- Rollback del API Gateway.
- Rollback de cambios en base de datos (PostgreSQL en `prod`).
- Rollback de configuración (ConfigMaps, Secrets, Ingress, Config Server).
- Rollback completo del sistema a un tag anterior.

## 2. Criterios para Ejecutar un Rollback

Se considera ejecutar un rollback cuando se cumple al menos uno de los siguientes criterios:

- **Indisponibilidad** del API Gateway o de servicios críticos (pedidos, pagos, usuarios).
- **Tasa de errores 5xx** por encima del umbral definido (por ejemplo, > 5 % en los últimos 5–10 minutos en entorno `prod`).
- **E2E tests fallan de forma masiva** después de un despliegue en `prod`.
- Degradación severa de performance (p95/p99 muy por encima de los objetivos) atribuible claramente al último despliegue.
- Cambios de esquema de base de datos que introducen errores en cascada o corrupción de datos.

Antes de ejecutar un rollback se debe:

- Identificar el **último estado estable conocido** (tag de release, commit o conjunto de versiones por servicio).
- Confirmar con el responsable técnico / product owner que se acepta volver al estado anterior.

## 3. Información y Herramientas Necesarias

### 3.1 Entorno y Accesos

- Acceso al cluster de Kubernetes de producción (`ecommerce-microservices-prod-cluster`) mediante `doctl` y `kubectl`.
- Permisos suficientes para:
  - Listar y modificar `deployments`, `services`, `ingresses`, `configmaps` y `secrets` en los namespaces `prod`, `dev`, `monitoring`, `tracing` y `logging` (según aplique).
  - Gestionar el despliegue de `postgresql` en `prod`.
- Acceso de solo lectura a:
  - Prometheus / Grafana para observar métricas.
  - Jaeger para analizar trazas.

### 3.2 Repositorios y Pipelines

- Repositorio `ecommerce-microservice-backend-app` con:
  - Workflows de GitHub Actions (`build.yml`, `deploy-dev.yml`, `deploy-prod.yml`).
  - Manifests de Kubernetes: `infrastructure/kubernetes/...`.
- Acceso a Docker Hub con las imágenes `luisrojasc/*` etiquetadas por versión (tags semánticos `vX.Y.Z`).

### 3.3 Comandos Base

Configuración del contexto de Kubernetes (ejemplo):

```bash
# Configurar acceso al cluster (ejemplo con DigitalOcean)
doctl kubernetes cluster kubeconfig save ecommerce-microservices-prod-cluster

# Verificar namespaces y despliegues clave
kubectl get ns
kubectl get deploy -n prod
```

## 4. Rollback de Despliegue Individual

Este procedimiento aplica cuando un único microservicio presenta problemas después de un despliegue, pero el resto del sistema se mantiene estable.

### 4.1 Identificar la Versión a Revertir

1. Determinar el **último tag estable** del servicio afectado (por ejemplo `v1.2.3`).
2. Confirmar en Docker Hub que existe la imagen `luisrojasc/<service>:v1.2.3`.
3. Verificar en el historial de `kubectl rollout` si hay revisiones previas almacenadas:

```bash
kubectl rollout history deployment/<service> -n prod
```

### 4.2 Rollback vía `kubectl rollout undo`

Si el problema se introdujo en el último despliegue y Kubernetes aún conserva la revisión anterior, se puede usar:

```bash
# Ver historial de revisiones
kubectl rollout history deployment/<service> -n prod

# Revertir a la revisión anterior inmediata
kubectl rollout undo deployment/<service> -n prod

# O revertir a una revisión concreta
kubectl rollout undo deployment/<service> -n prod --to-revision=<REVISION_ID>
```

### 4.3 Rollback fijando un Tag de Imagen

Si se requiere fijar explícitamente una versión concreta:

```bash
kubectl set image deployment/<service> \
  <container_name>=luisrojasc/<service>:v1.2.3 \
  -n prod

kubectl rollout status deployment/<service> -n prod
```

Donde `<container_name>` corresponde al nombre del contenedor en el manifest del deployment.

### 4.4 Validación Post‑Rollback

- Verificar que los pods del servicio están en estado `Running`:

```bash
kubectl get pods -n prod -l app=<service>
```

- Consultar el health check del servicio:

```bash
curl -f http://137.184.240.48/app/<service>/actuator/health
```

- Revisar métricas en Grafana (errores 5xx, latencias, circuit breakers) antes y después del rollback.
- Ejecutar, si procede, los tests E2E específicos relacionados con ese servicio.

## 5. Rollback del API Gateway

El API Gateway es un componente crítico. Cualquier fallo severo a este nivel afecta a todos los flujos, por lo que su rollback tiene prioridad.

### 5.1 Condiciones Típicas

- Errores 5xx generalizados en todas las rutas expuestas.
- Cambios en rutas, filtros o políticas que rompen el enrutamiento o la autenticación.

### 5.2 Procedimiento

1. Identificar el tag estable anterior del gateway (por ejemplo `v1.5.0`).
2. Confirmar que la imagen existe en Docker Hub.
3. Cambiar la imagen del deployment de `api-gateway`:

```bash
kubectl set image deployment/api-gateway \
  api-gateway=luisrojasc/api-gateway:v1.5.0 \
  -n prod

kubectl rollout status deployment/api-gateway -n prod
```

4. Validar:
   - Acceso a `http://137.184.240.48/app/api/actuator/health`.
   - Flujos E2E críticos (login, catálogo, creación de orden, pago, envío).
   - Estado de registros en Eureka (todos los servicios registrados de nuevo tras el rollback).

## 6. Rollback de Base de Datos (PostgreSQL)

Los cambios de base de datos son especialmente sensibles. Este procedimiento debe ejecutarse con extrema precaución y siempre documentando los pasos.

### 6.1 Consideraciones Previas

- Identificar si el problema es de **schema** (migraciones Flyway) o de **datos**.
- Determinar si se dispone de **backups recientes** (snapshots del volumen o dumps `pg_dump`).
- Asegurar que se puede asumir la pérdida de datos generados después del despliegue problemático (si se restaura un backup).

### 6.2 Rollback de Migraciones Flyway

Si el problema es una migración reciente y Flyway está configurado con scripts reversibles o se han definido scripts manuales de reparación:

1. Conectar a la base de datos de `prod`.
2. Identificar la versión de migración que introdujo el problema en la tabla `flyway_schema_history`.
3. Ejecutar el script de reversión correspondiente (si existe).

En caso de no contar con scripts reversibles, se recomienda:

- Crear una migración de corrección (`Vx__fix_problem.sql`) que lleve el esquema a un estado consistente.

### 6.3 Restauración desde Backup

Si es necesario restaurar completamente la base de datos:

1. Acordar con negocio la ventana de mantenimiento y la posible pérdida de datos recientes.
2. Escalar a 0 réplicas los servicios que escriben en la base de datos (por ejemplo: `order-service`, `payment-service`, `shipping-service`, etc.).

```bash
kubectl scale deployment/order-service --replicas=0 -n prod
kubectl scale deployment/payment-service --replicas=0 -n prod
# ... otros servicios que escriben en BD
```

3. Restaurar el backup (según la estrategia configurada: snapshot de volumen, `pg_restore`, etc.).
4. Verificar la integridad de la base de datos (consultas clave, integridad referencial).
5. Levantar de nuevo los deployments:

```bash
kubectl scale deployment/order-service --replicas=1 -n prod
kubectl scale deployment/payment-service --replicas=1 -n prod
```

6. Ejecutar E2E críticos antes de devolver el sistema a los usuarios finales.

## 7. Rollback de Configuración

Incluye cambios en ConfigMaps, Secrets, Ingress y configuración en el Config Server.

### 7.1 ConfigMaps y Secrets

1. Inspeccionar el historial de cambios en Git del directorio `infrastructure/kubernetes/base/` o el repositorio de configuración usado por `cloud-config`.
2. Identificar la versión estable anterior de los manifests (`configmap.yaml`, `secret.yaml`, etc.).
3. Aplicar de nuevo la configuración estable:

```bash
kubectl apply -f infrastructure/kubernetes/base/<componente>/configmap.yaml -n prod
kubectl apply -f infrastructure/kubernetes/base/<componente>/secret.yaml -n prod
```

4. Reiniciar los pods afectados para que recojan la nueva configuración (o usar `rollout restart`):

```bash
kubectl rollout restart deployment/<service> -n prod
```

### 7.2 Ingress

Si una modificación de Ingress ha roto el acceso externo:

1. Recuperar el manifiesto de Ingress estable desde Git.
2. Aplicarlo de nuevo sobre el cluster:

```bash
kubectl apply -f infrastructure/kubernetes/base/ingress/ingress-prod.yaml
```

3. Verificar:
   - Resolución DNS/IP.
   - Acceso a `http://137.184.240.48/app/` y otras rutas clave.

### 7.3 Config Server (Spring Cloud Config)

1. Identificar el commit previo estable en el repositorio Git usado por `cloud-config`.
2. Hacer rollback del repositorio de configuración a dicho commit.
3. Forzar a los servicios a recargar la configuración (si se ha habilitado `actuator/refresh`) o reiniciar los deployments.

## 8. Rollback Completo del Sistema

Este procedimiento se utiliza cuando el despliegue afecta a múltiples servicios/ componentes y el sistema en su conjunto se considera inestable.

### 8.1 Descripción General

La idea es alinear **todos los servicios** y componentes críticos al mismo tag estable previo (por ejemplo `v1.4.0`) utilizando imágenes Docker etiquetadas y/o revisiones conocidas en Kubernetes.

### 8.2 Procedimiento Alta‑Nivel

1. Determinar el tag de release estable anterior (por ejemplo `v1.4.0`).
2. Preparar un archivo JSON `service_versions` con las versiones deseadas por servicio, por ejemplo:

```json
{
  "service-discovery": "v1.4.0",
  "api-gateway": "v1.4.0",
  "user-service": "v1.4.0",
  "product-service": "v1.4.0",
  "order-service": "v1.4.0",
  "payment-service": "v1.4.0",
  "shipping-service": "v1.4.0",
  "favourite-service": "v1.4.0",
  "proxy-client": "v1.4.0"
}
```

3. Ejecutar el workflow de despliegue de producción (`deploy-prod.yml`) apuntando a `service_versions` con los tags estables.
4. Verificar el estado de los deployments en Kubernetes y el registro en Eureka.
5. Ejecutar pruebas E2E completas.

### 8.3 Uso de Scripts de Ayuda

Se recomienda disponer (y mantener) scripts como:

- `quick-rollback.sh`: rollback rápido de un solo servicio fijando una imagen previa.
- `rollback-to-tag.sh`: dado un tag, actualizar automáticamente todos los deployments a `luisrojasc/<service>:<TAG>`.

Ejemplo esquemático de script para un servicio:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="$1"
TAG="$2"
NAMESPACE="prod"

kubectl set image deployment/${SERVICE_NAME} \
  ${SERVICE_NAME}=luisrojasc/${SERVICE_NAME}:${TAG} \
  -n ${NAMESPACE}

kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE}
```

> Nota: los scripts reales deben almacenarse y versionarse en el repositorio (`scripts/rollback/`) y probarse en `dev` antes de usarlos en `prod`.

## 9. Validación Post‑Rollback

Independientemente del tipo de rollback, siempre se deben seguir los siguientes pasos de validación:

1. **Estado de pods**:

   ```bash
   kubectl get pods -n prod
   ```

   Verificar que no haya pods en estado `CrashLoopBackOff`, `Error` o `ImagePullBackOff`.

2. **Health checks**:

   - `http://137.184.240.48/app/api/actuator/health` (API Gateway).
   - `.../app/<service>/actuator/health` para servicios clave.

3. **Eureka**:

   - Comprobar en el dashboard de Eureka que todos los servicios esperados están registrados y `UP`.

4. **Pruebas E2E**:

   - Ejecutar el conjunto básico de pruebas E2E (login, navegación de productos, creación de orden, pago, envío) contra el entorno `prod`.

5. **Métricas y trazas**:

   - Revisar paneles de Grafana (tasa de errores, latencias, saturación).
   - Revisar, si es necesario, trazas en Jaeger para confirmar que los flujos end‑to‑end funcionan como antes del despliegue problemático.

6. **Comunicación**:

   - Informar al equipo y a los stakeholders del resultado del rollback, incluyendo:
     - Causa principal (si se conoce).
     - Impacto sobre usuarios/datos.
     - Siguiente paso (arreglar y volver a desplegar, mantener versión previa, etc.).

## 10. Tiempos Objetivo de Recuperación (RTO)

Los siguientes tiempos son estimaciones orientativas para la ejecución de los procedimientos de rollback:

- Rollback de un servicio individual: **≈ 5 minutos**.
- Rollback del API Gateway: **≈ 3 minutos** (alta prioridad).
- Rollback completo del sistema (todos los servicios a un tag anterior): **15–20 minutos**.
- Rollback de base de datos (restauración completa de backup): **30–60 minutos**, dependiendo del tamaño de los datos y del tipo de backup.

Estos tiempos deben revisarse periódicamente en función de la experiencia real de operación.

---

**Última actualización**: 25 de Noviembre de 2025
