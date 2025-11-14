# Escaneo de Seguridad con Trivy

## Tabla de Contenidos

1. [¿Qué es Trivy?](#qué-es-trivy)
2. [Implementación en GitHub Actions](#implementación-en-github-actions)
3. [Workflows Disponibles](#workflows-disponibles)
4. [Ver Resultados](#ver-resultados)
5. [Uso Local](#uso-local)
6. [Interpretación de Resultados](#interpretación-de-resultados)
7. [Remediación](#remediación)
8. [Configuración Avanzada](#configuración-avanzada)

---

## ¿Qué es Trivy?

**Trivy** es un escáner de seguridad de código abierto desarrollado por Aqua Security que detecta vulnerabilidades en:
- Imágenes de contenedores
- Sistemas de archivos
- Repositorios Git
- Archivos de configuración
- Dependencias de aplicaciones

### Características Principales

- **Rápido**: Escanea imágenes en segundos
- **Completo**: Detecta vulnerabilidades en OS y dependencias de aplicaciones
- **Fácil de usar**: No requiere configuración compleja
- **Actualizado**: Base de datos de vulnerabilidades actualizada diariamente
- **Integrado**: Compatible con CI/CD pipelines

---

## Implementación en GitHub Actions

### Arquitectura de Integración

```
┌─────────────────────────────────────────────────────────┐
│              GITHUB ACTIONS WORKFLOW                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Build Services (Maven)                               │
│  2. Run Unit Tests                                       │
│  3. Build Docker Images                                  │
│  4. Push to Docker Hub                                   │
│                    ↓                                     │
│  5. 🔒 TRIVY SCAN (Nuevo)                               │
│     ├─ Escanea cada imagen                              │
│     ├─ Genera reporte SARIF                             │
│     ├─ Sube a GitHub Security                           │
│     └─ Genera reporte legible                           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Integración Automática

El escaneo de Trivy se ejecuta **automáticamente** en:
- ✅ Cada push a `master`, `main`, o `develop`
- ✅ Cada Pull Request a `master` o `main`
- ✅ Builds manuales con `workflow_dispatch`

**No requiere configuración adicional** - está integrado en el pipeline existente.

---

## Workflows Disponibles

### 1. Build Workflow (Automático)

**Archivo**: `.github/workflows/build.yml`

**Qué hace**:
- Se ejecuta en cada push o PR
- Construye las imágenes Docker
- **Escanea automáticamente** cada imagen construida
- Sube resultados a GitHub Security tab
- **NO falla el build** por vulnerabilidades (solo reporta)

**Características**:
```yaml
Severidad escaneada: CRITICAL, HIGH, MEDIUM
Formato de salida: SARIF (GitHub Security) + Tabla (artifact)
Exit code: 0 (no bloquea el build)
Retención: 30 días
```

**Ver resultados**:
- GitHub Security tab → Code scanning alerts
- Workflow run → Artifacts → `trivy-report-{service}`

### 2. Security Scan Workflow (Programado/Manual)

**Archivo**: `.github/workflows/security-scan.yml`

**Qué hace**:
- Escaneo programado: **Todos los lunes a las 2 AM**
- Escanea las imágenes `latest` en Docker Hub
- Detecta nuevas vulnerabilidades en imágenes ya desplegadas
- **Crea issues automáticamente** si encuentra vulnerabilidades CRITICAL

**Ejecución manual**:
1. Ve a: Actions → Security Scan with Trivy → Run workflow
2. Configura opciones:
   - **Services**: Lista de servicios (vacío = todos)
   - **Severity**: CRITICAL, CRITICAL+HIGH, etc.
3. Click en "Run workflow"

**Características avanzadas**:
- ✅ Cuenta vulnerabilidades por severidad
- ✅ Crea issues de GitHub automáticamente
- ✅ Genera reportes JSON y tabla
- ✅ Retención: 90 días

---

## Ver Resultados

### Opción 1: GitHub Security Tab (Recomendado)

1. Ve a tu repositorio en GitHub
2. Click en **"Security"** (arriba)
3. Click en **"Code scanning"** (izquierda)
4. Verás todas las alertas de Trivy organizadas por servicio

**Ventajas**:
- Vista consolidada de todas las vulnerabilidades
- Filtros por severidad, estado, servicio
- Historial de vulnerabilidades
- Integración con Dependabot

### Opción 2: Workflow Artifacts

1. Ve a: Actions → Selecciona un workflow run
2. Scroll down hasta **"Artifacts"**
3. Descarga `trivy-report-{service}.txt`

**Ejemplo de reporte**:
```
┌───────────────────┬──────────────┬──────────┬─────────────────┬───────────────┐
│     Library       │ Vulnerability│ Severity │ Installed Vers. │ Fixed Version │
├───────────────────┼──────────────┼──────────┼─────────────────┼───────────────┤
│ spring-web        │ CVE-2023-123 │ HIGH     │ 5.3.10          │ 5.3.23        │
│ jackson-databind  │ CVE-2023-456 │ CRITICAL │ 2.12.3          │ 2.12.7.1      │
└───────────────────┴──────────────┴──────────┴─────────────────┴───────────────┘
```

### Opción 3: Workflow Logs

1. Ve a: Actions → Selecciona un workflow run
2. Click en el job "Trivy Security Scan"
3. Expande el step "Display scan summary"

---

## Uso Local

### Instalación

```bash
# Ubuntu/Debian
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# macOS
brew install aquasecurity/trivy/trivy

# Verificar instalación
trivy --version
```

### Escanear una Imagen Local

```bash
# Escanear imagen latest de un servicio
trivy image luisrojasc/user-service:latest

# Escanear con configuración personalizada
trivy image --config trivy.yaml luisrojasc/user-service:latest

# Solo vulnerabilidades CRITICAL y HIGH
trivy image --severity CRITICAL,HIGH luisrojasc/user-service:latest

# Generar reporte JSON
trivy image --format json --output report.json luisrojasc/user-service:latest

# Escanear todas las imágenes
./scripts/scan-all-services.sh
```

### Script Helper

Crea este script para escanear todos los servicios:

```bash
#!/bin/bash
# scripts/scan-all-services.sh

SERVICES=(
  "service-discovery"
  "proxy-client"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
  "api-gateway"
)

DOCKER_USER="luisrojasc"
TAG="${1:-latest}"

echo "========================================="
echo "  Scanning all services with Trivy"
echo "  Tag: ${TAG}"
echo "========================================="

for service in "${SERVICES[@]}"; do
  echo ""
  echo "📦 Scanning ${service}..."
  trivy image --severity CRITICAL,HIGH "${DOCKER_USER}/${service}:${TAG}"
done

echo ""
echo "✓ Scan completed"
```

---

## Interpretación de Resultados

### Niveles de Severidad

| Nivel    | Prioridad | Acción Recomendada                    | SLA       |
|----------|-----------|---------------------------------------|-----------|
| CRITICAL | 🔴 Alta    | **Remediar inmediatamente**          | 24 horas  |
| HIGH     | 🟠 Alta    | Remediar en próximo sprint           | 1 semana  |
| MEDIUM   | 🟡 Media   | Evaluar y planificar fix             | 1 mes     |
| LOW      | 🟢 Baja    | Monitorear, fix cuando sea posible   | Sin SLA   |

### Campos del Reporte

- **Library/Package**: Componente vulnerable
- **Vulnerability ID**: CVE o identificador de seguridad
- **Severity**: Nivel de criticidad (ver tabla arriba)
- **Installed Version**: Versión actualmente instalada
- **Fixed Version**: Versión que soluciona la vulnerabilidad
- **Title**: Descripción corta de la vulnerabilidad

### Ejemplo de Análisis

```
Library: spring-web
Vulnerability: CVE-2023-20863
Severity: HIGH
Installed: 5.3.10
Fixed: 5.3.27

Análisis:
✅ Fix disponible (5.3.27)
✅ Actualización menor (compatible)
⚠️  Severidad HIGH (prioridad alta)
📝 Acción: Actualizar dependencia en pom.xml
```

---

## Remediación

### Proceso de Remediación

#### 1. Identificar Vulnerabilidades

```bash
# Ver todas las vulnerabilidades CRITICAL
trivy image --severity CRITICAL luisrojasc/user-service:latest
```

#### 2. Actualizar Dependencias (Aplicación)

Para vulnerabilidades en dependencias Java:

```xml
<!-- pom.xml -->
<dependencies>
  <!-- ANTES -->
  <dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-web</artifactId>
    <version>5.3.10</version>  <!-- Vulnerable -->
  </dependency>

  <!-- DESPUÉS -->
  <dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-web</artifactId>
    <version>5.3.27</version>  <!-- Fixed -->
  </dependency>
</dependencies>
```

#### 3. Actualizar Imagen Base (OS)

Para vulnerabilidades en el OS:

```dockerfile
# ANTES - Imagen antigua
FROM eclipse-temurin:11-jre

# DESPUÉS - Imagen actualizada
FROM eclipse-temurin:11-jre-jammy  # Ubuntu 22.04 (más reciente)

# O usar distroless (mínimas vulnerabilidades)
FROM gcr.io/distroless/java11-debian11
```

#### 4. Rebuild y Re-scan

```bash
# 1. Rebuild la imagen
docker build -t luisrojasc/user-service:latest .

# 2. Re-scan
trivy image luisrojasc/user-service:latest

# 3. Si está limpio, push
docker push luisrojasc/user-service:latest
```

#### 5. Verificar en GitHub

Después del push, el workflow automático:
- Construirá la nueva imagen
- La escaneará con Trivy
- Actualizará GitHub Security tab

### Riesgo Aceptado

Si decides **NO remediar** una vulnerabilidad:

1. Evalúa el riesgo (CVSS score, explotabilidad, contexto)
2. Documenta la decisión
3. Agrégala a `.trivyignore`:

```bash
# .trivyignore
CVE-2023-12345  # No aplica: No usamos la funcionalidad vulnerable
CVE-2023-67890  # Mitigado: Firewall bloquea el vector de ataque
```

---

## Configuración Avanzada

### Configurar Escaneo más Estricto

Para **fallar el build** si hay vulnerabilidades CRITICAL:

```yaml
# .github/workflows/build.yml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ secrets.DOCKER_USERNAME }}/${{ steps.service.outputs.name }}:${{ needs.detect-changes.outputs.version_tag }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL'
    exit-code: '1'  # ← Cambiar a 1 para fallar el build
```

### Escanear Secretos en Imágenes

```yaml
- name: Scan for secrets
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    scanners: 'secret'
    format: 'table'
```

### Configurar Umbrales Personalizados

```yaml
# trivy.yaml
severity:
  - CRITICAL

# Solo reportar si hay más de 10 vulnerabilidades
# (requiere scripting adicional)
```

### Integración con Slack/Discord

Agregar notificaciones:

```yaml
- name: Notify on critical vulnerabilities
  if: steps.count.outputs.critical > 0
  uses: slackapi/slack-github-action@v1
  with:
    webhook: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "🚨 Critical vulnerabilities found in ${{ matrix.service }}: ${{ steps.count.outputs.critical }}"
      }
```

---

## Mejores Prácticas

### 1. Escaneo Continuo

✅ **Hacer**:
- Escanear en cada build
- Escanear periódicamente imágenes en producción
- Habilitar escaneo programado semanal

❌ **Evitar**:
- Escanear solo antes de releases
- Ignorar escaneos programados

### 2. Priorización

✅ **Hacer**:
- Priorizar CRITICAL y HIGH
- Remediar vulnerabilidades con exploits públicos primero
- Considerar el contexto de la aplicación

❌ **Evitar**:
- Intentar arreglar todo de una vez
- Ignorar MEDIUM y LOW indefinidamente

### 3. Automatización

✅ **Hacer**:
- Usar workflows automatizados
- Crear issues automáticos para CRITICAL
- Integrar con project boards

❌ **Evitar**:
- Escaneos manuales únicamente
- Revisar resultados ocasionalmente

### 4. Documentación

✅ **Hacer**:
- Documentar riesgos aceptados en `.trivyignore`
- Mantener changelog de remediaciones
- Compartir knowledge base del equipo

❌ **Evitar**:
- Ignorar CVEs sin documentación
- Decisiones de seguridad sin trazabilidad

---

## Troubleshooting

### Error: "database download failed"

```bash
# Solución: Actualizar base de datos manualmente
trivy image --download-db-only
```

### Error: "rate limit exceeded" (Docker Hub)

```bash
# Solución: Login en Docker Hub antes de escanear
docker login
trivy image luisrojasc/user-service:latest
```

### Escaneo muy lento

```bash
# Solución: Usar caché
trivy image --cache-dir /tmp/trivy-cache luisrojasc/user-service:latest
```

### GitHub Security tab no muestra resultados

**Verificar**:
1. ¿El workflow tiene `security-events: write` permission? ✅
2. ¿Se generó el archivo SARIF? (check artifacts)
3. ¿El step de upload-sarif se ejecutó exitosamente?

---

## Recursos Adicionales

### Documentación Oficial

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub Action](https://github.com/aquasecurity/trivy-action)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)

### CVE Databases

- [National Vulnerability Database (NVD)](https://nvd.nist.gov/)
- [GitHub Advisory Database](https://github.com/advisories)
- [Snyk Vulnerability DB](https://snyk.io/vuln/)

### Herramientas Complementarias

- **Dependabot**: Actualización automática de dependencias
- **Grype**: Escáner alternativo de vulnerabilidades
- **Clair**: Escáner de vulnerabilidades para contenedores

---

## FAQ

**P: ¿Trivy reemplaza a SonarQube?**
R: No, son complementarios. SonarQube analiza **calidad de código** (bugs, code smells, security hotspots en el código fuente). Trivy escanea **vulnerabilidades en dependencias e imágenes**.

**P: ¿Cuánto tiempo toma un escaneo?**
R: Típicamente 10-30 segundos por imagen (dependiendo del tamaño y caché).

**P: ¿Puedo escanear antes de push a Docker Hub?**
R: Sí, agrega un step de Trivy antes del `docker push` en el workflow.

**P: ¿Qué hago si una vulnerabilidad no tiene fix disponible?**
R:
1. Evalúa si realmente afecta a tu aplicación
2. Busca mitigaciones (configuración, WAF, network policies)
3. Documenta el riesgo aceptado
4. Monitorea hasta que haya fix

**P: ¿Cómo actualizo la base de datos de vulnerabilidades?**
R: Trivy la actualiza automáticamente en cada escaneo. En GitHub Actions siempre usa la versión más reciente.

---

## Changelog

**v1.0.0** (2025-01-14)
- ✅ Implementación inicial de Trivy
- ✅ Integración con build workflow
- ✅ Workflow de escaneo programado
- ✅ Upload automático a GitHub Security
- ✅ Generación de reportes
- ✅ Creación automática de issues

---

## Soporte

Para problemas o preguntas:
1. Revisa esta documentación
2. Consulta los [Trivy docs](https://aquasecurity.github.io/trivy/)
3. Abre un issue en el repositorio
4. Contacta al equipo de DevSecOps

---

**Happy Scanning! 🔒**
