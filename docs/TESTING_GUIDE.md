# Testing Guide - E-Commerce Microservices

## Descripción General

Este documento describe la estrategia de pruebas implementada en el proyecto de microservicios de e-commerce.

## Tipos de Pruebas

### 1. Pruebas Unitarias
- **Ubicación**: `{service}/src/test/java/**/*Test.java`
- **Framework**: JUnit 5
- **Propósito**: Validar componentes individuales aislados
- **Ejecución**: `mvn test`

### 2. Pruebas de Integración
- **Ubicación**: `{service}/src/test/java/**/*IT.java`
- **Framework**: JUnit 5 + Testcontainers
- **Propósito**: Validar comunicación entre servicios
- **Ejecución**: `mvn verify`

### 3. Pruebas E2E
- **Ubicación**: `tests/src/test/java/**/*E2ETest.java`
- **Framework**: REST Assured + JUnit 5
- **Propósito**: Validar flujos completos de usuario
- **Ejecución**: `mvn verify -Pe2e-tests`

### 4. Pruebas de Performance
- **Ubicación**: `tests/performance/`
- **Framework**: Locust (Python)
- **Propósito**: Validar rendimiento y escalabilidad
- **Ejecución**: `locust -f locustfile.py`

## Microservicios con Pruebas

### User Service
- Pruebas unitarias de servicios
- Pruebas de integración de repositorios
- E2E de autenticación y registro

### Product Service
- Pruebas unitarias de lógica de negocio
- Pruebas de integración con base de datos
- E2E de catálogo de productos

### Order Service
- Pruebas unitarias de carrito
- Pruebas de integración de órdenes
- E2E de creación de órdenes

### Payment Service
- Pruebas unitarias de procesamiento
- Pruebas de integración con órdenes
- E2E de flujo de pagos

### Shipping Service
- Pruebas unitarias de envíos
- Pruebas de integración con órdenes
- E2E de seguimiento de envíos

### Favourite Service
- Pruebas unitarias de favoritos
- E2E de gestión de favoritos

## Ejecución de Pruebas por Ambiente

### Development (DEV)
```bash
mvn clean test
```

### Staging (STAGE)
```bash
mvn clean verify
cd tests && mvn verify -Pe2e-tests
```

### Production (PROD)
```bash
# Smoke tests post-deployment
curl http://api-gateway/actuator/health
```

## Cobertura de Código

Se utiliza JaCoCo para medir la cobertura de código.

**Objetivo**: Mínimo 70% de cobertura

**Reporte**:
```bash
mvn jacoco:report
# Ver en: target/site/jacoco/index.html
```

## SonarQube

Análisis de calidad de código:

```bash
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=YOUR_TOKEN
```

## Buenas Prácticas

1. **Escribir pruebas antes de hacer merge**: Toda nueva funcionalidad debe tener pruebas
2. **Nomenclatura clara**: Nombres descriptivos para los tests
3. **Aislamiento**: Las pruebas no deben depender unas de otras
4. **Datos de prueba**: Usar datos realistas pero no sensibles
5. **Limpieza**: Limpiar datos de prueba después de ejecutar

## Próximos Pasos

- [ ] Aumentar cobertura de pruebas unitarias a 80%
- [ ] Agregar más pruebas de integración entre servicios
- [ ] Implementar pruebas de contrato (Contract Testing)
- [ ] Agregar pruebas de seguridad automatizadas

---

**Última actualización**: 2025-11-03
**Versión**: 1.0
