# 🌿 Branching Strategy - Ecommerce Microservices

## Estrategia: **GitFlow Simplificado para CI/CD**

Esta estrategia está optimizada para desarrollo continuo con despliegues automatizados a múltiples ambientes.

---

## 📊 Arquitectura de Branches

```
master (production)
    ↑
    │ merge + tag
    │
release/v1.x.x (staging)
    ↑
    │ merge
    │
develop (development)
    ↑
    │ merge
    │
feature/nueva-funcionalidad (local)
hotfix/arreglo-critico (emergency)
```

---

## 🎯 Branches Principales

### 1. **`master`** - Producción 🔴
- **Propósito:** Código en producción
- **Ambiente:** Production (K8s namespace: `production`)
- **Pipeline:** `Jenkinsfile.prod`
- **Tags:** Cada merge crea un tag de versión (ej: `v1.0.0`)
- **Protección:** ⚠️ Branch protegido, requiere aprobación manual
- **Deploy:** Automático después de aprobación manual en Jenkins

**Reglas:**
- ✅ Solo acepta merges desde `release/*` branches
- ✅ Cada commit debe tener un tag
- ✅ Genera Release Notes automáticamente
- ❌ NO se trabaja directamente en este branch
- ❌ NO se aceptan commits directos

### 2. **`develop`** - Desarrollo 🟢
- **Propósito:** Integración de features
- **Ambiente:** Development (K8s namespace: `dev`)
- **Pipeline:** `Jenkinsfile.dev`
- **Tags:** `dev-<BUILD_NUMBER>`
- **Protección:** Branch semi-protegido
- **Deploy:** Automático en cada push

**Reglas:**
- ✅ Acepta merges desde `feature/*` branches
- ✅ Build y tests automáticos
- ✅ Deploy automático a dev namespace
- ⚠️ Debe pasar tests antes de crear release
- ❌ NO se trabaja directamente (excepto fixes menores)

---

## 🔀 Branches de Soporte

### 3. **`release/v*`** - Pre-producción 🟡
- **Propósito:** Preparación para producción
- **Ambiente:** Staging (K8s namespace: `staging`)
- **Pipeline:** `Jenkinsfile.stage`
- **Tags:** `stage-<BUILD_NUMBER>`
- **Duración:** Temporal (se elimina después del merge a master)

**Ejemplo:** `release/v1.2.0`

**Workflow:**
```bash
# Crear desde develop cuando esté listo para release
git checkout develop
git pull
git checkout -b release/v1.2.0
git push -u origin release/v1.2.0

# El pipeline STAGE se ejecuta automáticamente:
# - Build + Unit Tests + Integration Tests + E2E Tests
# - Deploy a staging namespace
# - Performance tests con Locust
```

**Reglas:**
- ✅ Solo bugfixes y ajustes menores
- ✅ Ejecuta TODAS las pruebas
- ✅ Deploy a staging para QA
- ⚠️ NO agregar features nuevas
- ➡️ Se mergea a `master` cuando QA aprueba

### 4. **`feature/*`** - Nuevas Funcionalidades 🔵
- **Propósito:** Desarrollo de features
- **Ambiente:** Local o dev personal
- **Pipeline:** No ejecuta pipelines automáticamente
- **Duración:** Temporal (se elimina después del merge)

**Ejemplo:** `feature/user-authentication`, `feature/payment-gateway`

**Workflow:**
```bash
# Crear desde develop
git checkout develop
git pull
git checkout -b feature/user-authentication

# Desarrollar...
git add .
git commit -m "Add user authentication logic"
git push -u origin feature/user-authentication

# Crear Pull Request a develop
# Después del merge, eliminar branch
git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

**Reglas:**
- ✅ Siempre parte de `develop`
- ✅ Commits frecuentes
- ✅ Pull Request para merge a develop
- ✅ Code review antes de merge
- ❌ NO mergear sin review

### 5. **`hotfix/*`** - Arreglos de Emergencia 🔥
- **Propósito:** Fixes críticos en producción
- **Ambiente:** Staging → Production
- **Pipeline:** `Jenkinsfile.stage` → `Jenkinsfile.prod`
- **Duración:** Temporal (muy corta)

**Ejemplo:** `hotfix/payment-service-crash`

**Workflow:**
```bash
# Crear desde master (no develop!)
git checkout master
git pull
git checkout -b hotfix/payment-service-crash

# Fix crítico...
git add .
git commit -m "Fix payment service null pointer exception"
git push -u origin hotfix/payment-service-crash

# Mergear a master (producción)
# Mergear a develop (para mantener sincronizado)
```

**Reglas:**
- ✅ Solo para bugs críticos en producción
- ✅ Parte de `master`
- ✅ Se mergea a `master` Y `develop`
- ⚠️ Usar SOLO en emergencias

---

## 🚀 Flujo de Trabajo Completo

### Desarrollo Normal (Feature → Dev → Staging → Production)

```bash
# 1. Crear feature desde develop
git checkout develop
git pull origin develop
git checkout -b feature/add-favorites

# 2. Desarrollar y commitear
git add .
git commit -m "feat: Add favorites service implementation"
git push -u origin feature/add-favorites

# 3. Pull Request a develop → Merge
# Jenkins ejecuta pipeline DEV automáticamente
# ✅ Build → Test → Push to ECR (tag: dev-123)

# 4. Cuando develop esté estable, crear release
git checkout develop
git pull
git checkout -b release/v1.3.0
git push -u origin release/v1.3.0

# Jenkins ejecuta pipeline STAGE automáticamente
# ✅ Build → Unit Tests → Integration Tests → E2E Tests
# ✅ Deploy to staging → Performance Tests
# ✅ QA valida en staging

# 5. Si QA aprueba, mergear a master
git checkout master
git pull
git merge --no-ff release/v1.3.0 -m "Release v1.3.0"
git tag -a v1.3.0 -m "Version 1.3.0 - Add favorites service"
git push origin master --tags

# Jenkins ejecuta pipeline PROD
# ⚠️ Aprobación manual requerida
# ✅ Deploy to production
# ✅ Release Notes generados

# 6. Sincronizar develop con master
git checkout develop
git merge master
git push origin develop

# 7. Limpiar branch release
git branch -d release/v1.3.0
git push origin --delete release/v1.3.0
```

---

## 🔧 Mapeo de Branches → Pipelines

| Branch | Pipeline | Ambiente | Namespace | Trigger | Aprobación |
|--------|----------|----------|-----------|---------|------------|
| `develop` | Jenkinsfile.dev | Development | `dev` | Automático | No |
| `release/*` | Jenkinsfile.stage | Staging | `staging` | Automático | No |
| `master` | Jenkinsfile.prod | Production | `production` | Automático | **Sí** |
| `feature/*` | Ninguno | Local | - | - | - |
| `hotfix/*` | Jenkinsfile.stage + prod | Staging + Prod | `staging` + `production` | Automático | **Sí** en prod |

---

## 📋 Convenciones de Commits

Usa **Conventional Commits** para generar Release Notes automáticamente:

```bash
feat:     Nueva funcionalidad
fix:      Corrección de bug
docs:     Documentación
style:    Formato (no afecta código)
refactor: Refactorización
test:     Agregar tests
chore:    Tareas de mantenimiento
perf:     Mejoras de rendimiento
ci:       Cambios en CI/CD
```

**Ejemplos:**
```bash
git commit -m "feat(user-service): add password reset functionality"
git commit -m "fix(payment-service): resolve null pointer in transaction"
git commit -m "test(order-service): add integration tests for order creation"
git commit -m "docs: update API documentation for shipping service"
```

---

## 🏷️ Convenciones de Tags

### Semantic Versioning (SemVer)

Formato: `v<MAJOR>.<MINOR>.<PATCH>`

- **MAJOR:** Cambios incompatibles en API
- **MINOR:** Nueva funcionalidad compatible
- **PATCH:** Bugfixes compatibles

**Ejemplos:**
- `v1.0.0` - Primera versión en producción
- `v1.1.0` - Agregar favorites service
- `v1.1.1` - Fix bug en favorites
- `v2.0.0` - Cambio incompatible en API

**Tags automáticos en ECR:**
- `dev-123` (pipeline dev)
- `stage-45` (pipeline stage)
- `prod-12`, `v1.2.0`, `latest` (pipeline prod)

---

## 🛡️ Protección de Branches

### Reglas Recomendadas en GitHub/GitLab:

#### `master` (Production):
- ✅ Require pull request reviews (al menos 1)
- ✅ Require status checks (tests deben pasar)
- ✅ Require branches to be up to date
- ✅ Include administrators
- ❌ Allow force pushes (NUNCA)
- ❌ Allow deletions (NUNCA)

#### `develop`:
- ✅ Require pull request reviews (al menos 1)
- ✅ Require status checks (tests deben pasar)
- ⚠️ Allow force pushes (solo con permisos)
- ❌ Allow deletions

#### `release/*`:
- ✅ Require pull request reviews para merge a master
- ✅ Require status checks
- ⚠️ Temporal (eliminar después del merge)

---

## 🔄 Casos de Uso Comunes

### Caso 1: Desarrollar Nueva Feature

```bash
git checkout develop
git pull
git checkout -b feature/add-reviews
# ... desarrollar ...
git push -u origin feature/add-reviews
# Crear PR a develop
```

**Resultado:** Deploy automático a `dev` namespace

---

### Caso 2: Preparar Release

```bash
git checkout develop
git pull
git checkout -b release/v1.4.0
git push -u origin release/v1.4.0
# Pipeline STAGE se ejecuta automáticamente
# QA valida en staging
```

**Resultado:**
- Deploy a `staging` namespace
- Todas las pruebas ejecutadas
- Listo para producción

---

### Caso 3: Deploy a Producción

```bash
# Después de que QA aprueba en staging
git checkout master
git pull
git merge --no-ff release/v1.4.0
git tag -a v1.4.0 -m "Release 1.4.0"
git push origin master --tags

# Sincronizar develop
git checkout develop
git merge master
git push origin develop
```

**Resultado:**
- Aprobación manual en Jenkins requerida
- Deploy a `production` namespace
- Release Notes generados
- Tag v1.4.0 creado

---

### Caso 4: Hotfix de Emergencia

```bash
git checkout master
git pull
git checkout -b hotfix/critical-bug
# ... fix ...
git push -u origin hotfix/critical-bug

# Merge a master
git checkout master
git merge hotfix/critical-bug
git tag -a v1.4.1 -m "Hotfix: Critical bug"
git push origin master --tags

# Merge a develop
git checkout develop
git merge hotfix/critical-bug
git push origin develop
```

**Resultado:** Fix en producción en minutos

---

## 📈 Visualización del Flujo

```
Time →

feature/A ─────┐
                ├─→ develop ─────┐
feature/B ─────┘                 │
                                  ├─→ release/v1.2 ─→ master (v1.2.0)
                                 │                        ↓
                                 │                    production
                                 │
                develop ←────────┴───── merge back

hotfix/critical ─→ master (v1.2.1) ─→ production
                      │
                      └─→ develop
```

---

## 🎯 Checklist para el Equipo

### Antes de Crear Feature:
- [ ] Asegurarte que `develop` está actualizado
- [ ] Nombrar branch correctamente: `feature/nombre-descriptivo`
- [ ] Un feature = un objetivo claro

### Antes de Merge a Develop:
- [ ] Código revisado (PR)
- [ ] Tests locales pasando
- [ ] Conflictos resueltos
- [ ] Documentación actualizada

### Antes de Crear Release:
- [ ] Todos los features necesarios mergeados a develop
- [ ] Tests de integración pasando
- [ ] Actualizar versión en pom.xml (si aplica)
- [ ] Crear CHANGELOG entry

### Antes de Deploy a Production:
- [ ] QA aprobó en staging
- [ ] Performance tests OK
- [ ] Rollback plan definido
- [ ] Release Notes preparados
- [ ] Notificar al equipo

---

## 🚨 Troubleshooting

### "Merge conflict en develop"
```bash
git checkout develop
git pull
git checkout feature/mi-feature
git merge develop
# Resolver conflictos
git commit
git push
```

### "Olvidé crear feature branch"
```bash
# Si aún no hiciste push
git stash
git checkout develop
git pull
git checkout -b feature/mi-feature
git stash pop
```

### "Necesito revertir producción"
```bash
# Opción 1: Revert commit
git checkout master
git revert <commit-sha>
git push

# Opción 2: Rollback en K8s
kubectl rollout undo deployment/service-name -n production
```

---

## 📚 Referencias

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

## 📞 Comandos Rápidos

```bash
# Setup inicial
git checkout -b develop
git push -u origin develop

# Crear feature
git checkout develop && git pull && git checkout -b feature/nombre

# Crear release
git checkout develop && git pull && git checkout -b release/v1.x.0

# Deploy a prod
git checkout master && git merge --no-ff release/v1.x.0 && git tag v1.x.0 && git push --tags

# Sync develop
git checkout develop && git merge master && git push
```

---

**Fecha:** 2025-10-20
**Versión:** 1.0
**Mantenido por:** DevOps Team
