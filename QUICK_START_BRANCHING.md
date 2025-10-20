# 🚀 Quick Start - Branching Strategy

## TL;DR

```
develop  → DEV environment   (auto deploy)
release  → STAGE environment (auto deploy + tests)
master   → PROD environment  (manual approval)
```

---

## 🎯 Setup Inicial (UNA VEZ)

```bash
# 1. Crear branch develop
./git-flow.sh init

# 2. Configurar Jenkins
# - Crear 3 pipelines multibranch en Jenkins
# - Cada uno apunta a infrastructure/jenkins/Jenkinsfile.{dev,stage,prod}
```

---

## 📝 Workflow Diario

### Desarrollar Feature

```bash
# 1. Crear feature
./git-flow.sh feature start mi-nueva-feature

# 2. Desarrollar
git add .
git commit -m "feat: mi nueva funcionalidad"

# 3. Push
git push -u origin feature/mi-nueva-feature

# 4. Finalizar (merge a develop)
./git-flow.sh feature finish mi-nueva-feature
```

**Resultado:** Automáticamente se despliega en **DEV** namespace

---

### Deploy a Staging

```bash
# 1. Crear release
./git-flow.sh release start 1.2.0

# → Pipeline STAGE se ejecuta automáticamente
# → Deploy a staging namespace
# → Todas las pruebas se ejecutan

# 2. QA valida en staging...

# 3. Si todo OK, finalizar release
./git-flow.sh release finish 1.2.0
```

**Resultado:** Mergeado a **master** listo para producción

---

### Deploy a Producción

Después de `release finish`:

```bash
# Jenkins detecta push a master
# → Pipeline PROD se ejecuta
# → ⚠️ REQUIERE APROBACIÓN MANUAL en Jenkins
# → Después de aprobar: Deploy a production
# → Release Notes generados
```

**Manual en Jenkins:**
1. Ve a Jenkins → Pipeline PROD
2. Espera input de aprobación
3. Click "Proceed"
4. Deploy a production completo

---

## 🔥 Hotfix de Emergencia

```bash
# 1. Crear hotfix desde master
./git-flow.sh hotfix start critical-bug

# 2. Fix rápido
git add .
git commit -m "fix: resolver bug crítico"

# 3. Finalizar (merge a master Y develop)
./git-flow.sh hotfix finish critical-bug 1.2.1
```

**Resultado:** Fix en **producción** en minutos

---

## 🎨 Visualización

```
FEATURE → DEVELOP → RELEASE → MASTER
  ↓          ↓         ↓         ↓
Local      DEV     STAGING   PRODUCTION
          (auto)   (auto)   (manual approval)
```

---

## 🛠️ Comandos Git Flow Helper

```bash
./git-flow.sh init                          # Setup inicial
./git-flow.sh feature start <nombre>        # Crear feature
./git-flow.sh feature finish <nombre>       # Finalizar feature
./git-flow.sh release start <version>       # Crear release
./git-flow.sh release finish <version>      # Finalizar release
./git-flow.sh hotfix start <nombre>         # Crear hotfix
./git-flow.sh hotfix finish <nombre> <ver>  # Finalizar hotfix
./git-flow.sh status                        # Ver estado
./git-flow.sh sync                          # Sincronizar todo
```

---

## ⚡ Comandos Más Usados

```bash
# Ver estado actual
./git-flow.sh status

# Crear y trabajar en feature
./git-flow.sh feature start user-auth
# ... desarrollar ...
git add . && git commit -m "feat: add authentication"
./git-flow.sh feature finish user-auth

# Preparar release
./git-flow.sh release start 1.3.0
# QA valida...
./git-flow.sh release finish 1.3.0

# Sincronizar todo
./git-flow.sh sync
```

---

## 📊 Mapeo Branch → Ambiente

| Branch | Jenkinsfile | Namespace | Aprobación | Tags |
|--------|-------------|-----------|------------|------|
| `develop` | Jenkinsfile.dev | `dev` | No | `dev-123` |
| `release/v*` | Jenkinsfile.stage | `staging` | No | `stage-45` |
| `master` | Jenkinsfile.prod | `production` | **Sí** | `v1.2.0`, `prod-12` |

---

## ✅ Checklist Rápido

### Antes de Crear Feature:
- [ ] `./git-flow.sh sync` (actualizar todo)
- [ ] Nombre descriptivo

### Antes de Finish Feature:
- [ ] Tests locales OK
- [ ] Código commiteado

### Antes de Release:
- [ ] Todos features en develop
- [ ] Incrementar versión correctamente

### Antes de Aprobar PROD:
- [ ] QA aprobó staging
- [ ] Performance tests OK
- [ ] Rollback plan listo

---

## 🔴 Reglas de Oro

1. **NUNCA** trabajar directamente en `master`
2. **NUNCA** hacer force push a `master` o `develop`
3. **SIEMPRE** usar el script `git-flow.sh`
4. **SIEMPRE** aprobar manualmente en producción
5. Features pequeños y frecuentes mejor que grandes

---

## 🆘 Ayuda Rápida

**¿En qué branch estoy?**
```bash
git branch --show-current
```

**¿Qué cambios tengo?**
```bash
git status
```

**¿Cómo volver atrás?**
```bash
git checkout develop  # cambiar a develop
git stash            # guardar cambios sin commit
```

**Ver documentación completa:**
```bash
cat BRANCHING_STRATEGY.md
```

---

## 📞 Contacto

¿Dudas? Revisa:
1. `BRANCHING_STRATEGY.md` - Documentación completa
2. `./git-flow.sh help` - Ayuda del script
3. Jenkins UI - Estado de pipelines

---

**Versión:** 1.0
**Última actualización:** 2025-10-20
