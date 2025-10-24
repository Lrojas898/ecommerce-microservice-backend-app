# GitHub Webhook Configuration con Generic Webhook Trigger

**Fecha:** 2025-10-24
**Plugin:** Generic Webhook Trigger
**Jenkins:** http://3.12.227.83:8080

---

## ✅ Cambios Realizados

### Jenkinsfiles Actualizados

Se actualizaron **3 Jenkinsfiles** para usar Generic Webhook Trigger en lugar de `githubPush()`:

1. ✅ **Jenkinsfile.dev** - Token: `ecommerce-dev-webhook-token`
2. ✅ **Jenkinsfile.stage** - Token: `ecommerce-stage-webhook-token`
3. ✅ **Jenkinsfile.prod** - Token: `ecommerce-prod-webhook-token`

---

## 🔧 Configuración de GitHub Webhook

### Opción 1: Un Solo Webhook para Todos los Pipelines (Recomendado)

**URL del Webhook:**
```
http://3.12.227.83:8080/generic-webhook-trigger/invoke
```

#### Configuración en GitHub:

1. Ve a: https://github.com/Lrojas898/ecommerce-microservice-backend-app/settings/hooks
2. **Edita el webhook existente** (o crea uno nuevo)
3. Configura:
   - **Payload URL:** `http://3.12.227.83:8080/generic-webhook-trigger/invoke`
   - **Content type:** `application/json`
   - **Secret:** *(dejar vacío)*
   - **SSL verification:** Enable SSL verification (o disable si es HTTP)
   - **Events:**
     - ✅ Push events
     - ✅ Pull requests
4. **Save webhook**

**¿Cómo funciona?**
- Este webhook **NO tiene token** en la URL
- Cuando GitHub hace push, el Generic Webhook Trigger plugin:
  - Recibe el payload
  - Lee el campo `$.ref` (ej: `refs/heads/develop`)
  - Compara con los `regexpFilterExpression` de CADA pipeline
  - Activa **solo los pipelines que coincidan** con el branch

**Ejemplo:**
- Push a `develop` → Solo activa `Jenkinsfile.dev`
- Push a `release/v1.1.0` → Solo activa `Jenkinsfile.stage`
- Push a `master` → Solo activa `Jenkinsfile.prod`

---

### Opción 2: Webhooks Separados por Pipeline (Más Control)

Si prefieres tener webhooks separados con tokens específicos:

#### Webhook 1: DEV Pipeline
```
http://3.12.227.83:8080/generic-webhook-trigger/invoke?token=ecommerce-dev-webhook-token
```

#### Webhook 2: STAGE Pipeline
```
http://3.12.227.83:8080/generic-webhook-trigger/invoke?token=ecommerce-stage-webhook-token
```

#### Webhook 3: PROD Pipeline
```
http://3.12.227.83:8080/generic-webhook-trigger/invoke?token=ecommerce-prod-webhook-token
```

**Ventaja:** Más control granular sobre qué pipeline se activa
**Desventaja:** 3 webhooks en GitHub (más difícil de mantener)

---

## 🎯 Configuración Actual de Triggers

### Jenkinsfile.dev
```groovy
triggers {
    GenericTrigger(
        genericVariables: [
            [key: 'ref', value: '$.ref'],
            [key: 'repository_name', value: '$.repository.name'],
            [key: 'pusher_name', value: '$.pusher.name']
        ],
        causeString: 'Triggered by GitHub push to $ref by $pusher_name',
        token: 'ecommerce-dev-webhook-token',
        regexpFilterText: '$ref',
        regexpFilterExpression: '^refs/heads/develop$'  // Solo branch develop
    )
}
```

### Jenkinsfile.stage
```groovy
triggers {
    GenericTrigger(
        token: 'ecommerce-stage-webhook-token',
        regexpFilterText: '$ref',
        regexpFilterExpression: '^refs/heads/release/.*$'  // Cualquier release/*
    )
}
```

### Jenkinsfile.prod
```groovy
triggers {
    GenericTrigger(
        token: 'ecommerce-prod-webhook-token',
        regexpFilterText: '$ref',
        regexpFilterExpression: '^refs/heads/(master|main)$'  // master o main
    )
}
```

---

## 📝 Pasos para Activar

### 1. Pushear los Jenkinsfiles Actualizados

```bash
git checkout master  # O la branch donde tengas los Jenkinsfiles
git add infrastructure/jenkins/Jenkinsfile.*
git commit -m "feat(ci): configure Generic Webhook Trigger for all pipelines

- Add Generic Webhook Trigger to Jenkinsfile.dev
- Add Generic Webhook Trigger to Jenkinsfile.stage
- Add Generic Webhook Trigger to Jenkinsfile.prod
- Configure branch filtering with regex expressions
- Use unique tokens for each environment"

git push origin master
```

### 2. Actualizar Pipelines en Jenkins

**Opción A: Via Jenkins UI (si los pipelines ya existen)**

Para cada pipeline:
1. Ve a Jenkins: http://3.12.227.83:8080
2. Click en el pipeline (ej: `Ecommerce-DEV-Pipeline`)
3. Click "Configure"
4. En "Pipeline" section, asegúrate que "Definition" sea "Pipeline script from SCM"
5. SCM: Git
6. Repository URL: `https://github.com/Lrojas898/ecommerce-microservice-backend-app.git`
7. Script Path: `infrastructure/jenkins/Jenkinsfile.dev` (ajusta según el pipeline)
8. Click "Save"
9. Click "Build Now" (para que Jenkins lea el nuevo Jenkinsfile)

**Opción B: Via Jenkins Script Console**

```groovy
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec

def jenkins = Jenkins.instance

// Pipeline DEV
def jobDev = jenkins.getItem('Ecommerce-DEV-Pipeline')
if (!jobDev) {
    jobDev = jenkins.createProject(WorkflowJob, 'Ecommerce-DEV-Pipeline')
}
def scmDev = new GitSCM('https://github.com/Lrojas898/ecommerce-microservice-backend-app.git')
scmDev.branches = [new BranchSpec('*/develop')]
jobDev.definition = new CpsScmFlowDefinition(scmDev, 'infrastructure/jenkins/Jenkinsfile.dev')
jobDev.save()

// Pipeline STAGE
def jobStage = jenkins.getItem('Ecommerce-STAGE-Pipeline')
if (!jobStage) {
    jobStage = jenkins.createProject(WorkflowJob, 'Ecommerce-STAGE-Pipeline')
}
def scmStage = new GitSCM('https://github.com/Lrojas898/ecommerce-microservice-backend-app.git')
scmStage.branches = [new BranchSpec('*/release/*')]
jobStage.definition = new CpsScmFlowDefinition(scmStage, 'infrastructure/jenkins/Jenkinsfile.stage')
jobStage.save()

// Pipeline PROD
def jobProd = jenkins.getItem('Ecommerce-PROD-Pipeline')
if (!jobProd) {
    jobProd = jenkins.createProject(WorkflowJob, 'Ecommerce-PROD-Pipeline')
}
def scmProd = new GitSCM('https://github.com/Lrojas898/ecommerce-microservice-backend-app.git')
scmProd.branches = [new BranchSpec('*/master')]
jobProd.definition = new CpsScmFlowDefinition(scmProd, 'infrastructure/jenkins/Jenkinsfile.prod')
jobProd.save()

println "✅ All pipelines configured successfully!"
```

### 3. Configurar el Webhook en GitHub

**Usando Opción 1 (recomendado):**

1. Ve a: https://github.com/Lrojas898/ecommerce-microservice-backend-app/settings/hooks
2. Edita el webhook existente
3. **Payload URL:** `http://3.12.227.83:8080/generic-webhook-trigger/invoke`
4. **Content type:** `application/json`
5. **Events:** Pushes + Pull requests
6. Save

---

## 🧪 Probar la Configuración

### Test 1: Verificar que Jenkins puede recibir webhooks

```bash
# Test manual sin token (activa TODOS los pipelines que coincidan)
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/develop",
    "repository": {"name": "ecommerce-microservice-backend-app"},
    "pusher": {"name": "test-user"}
  }' \
  http://3.12.227.83:8080/generic-webhook-trigger/invoke
```

**Resultado esperado:** Solo `Ecommerce-DEV-Pipeline` debe activarse.

### Test 2: Verificar STAGE pipeline

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/release/v1.1.0",
    "repository": {"name": "ecommerce-microservice-backend-app"},
    "pusher": {"name": "test-user"}
  }' \
  http://3.12.227.83:8080/generic-webhook-trigger/invoke
```

**Resultado esperado:** Solo `Ecommerce-STAGE-Pipeline` debe activarse.

### Test 3: Verificar PROD pipeline

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/master",
    "repository": {"name": "ecommerce-microservice-backend-app"},
    "pusher": {"name": "test-user"}
  }' \
  http://3.12.227.83:8080/generic-webhook-trigger/invoke
```

**Resultado esperado:** Solo `Ecommerce-PROD-Pipeline` debe activarse.

### Test 4: Push real desde Git

```bash
# En tu branch release/v1.1.0
git commit --allow-empty -m "test: trigger staging pipeline via webhook"
git push origin release/v1.1.0
```

1. Ve a GitHub webhook deliveries
2. Verifica que devuelva **200 OK**
3. Ve a Jenkins y verifica que `Ecommerce-STAGE-Pipeline` se activó
4. Verifica en los logs del build que muestra: "Triggered by GitHub push to refs/heads/release/v1.1.0 by Lrojas898"

---

## 🔍 Verificar en Jenkins

### Via UI:

1. http://3.12.227.83:8080/job/Ecommerce-STAGE-Pipeline/
2. Debería haber un nuevo build en "Build History"
3. Click en el build
4. Click "Console Output"
5. Busca líneas como:
   ```
   GenericWebhook: Contributing variables:
     ref = refs/heads/release/v1.1.0
     repository_name = ecommerce-microservice-backend-app
     pusher_name = Lrojas898
   ```

---

## 📊 Mapeo Final

| Branch Push | Regex Match | Pipeline Activado | Namespace | Tag |
|-------------|-------------|-------------------|-----------|-----|
| `develop` | `^refs/heads/develop$` | Ecommerce-DEV-Pipeline | dev | dev-BUILD_NUMBER |
| `release/v1.1.0` | `^refs/heads/release/.*$` | Ecommerce-STAGE-Pipeline | staging | stage-BUILD_NUMBER |
| `master` | `^refs/heads/(master\|main)$` | Ecommerce-PROD-Pipeline | production | prod-BUILD_NUMBER |
| `feature/*` | - | *(ninguno)* | - | - |

---

## ⚠️ Notas Importantes

1. **CSRF Protection:** Generic Webhook Trigger **NO requiere CSRF token**, por lo que evita el error 403.

2. **Tokens únicos:** Cada pipeline tiene su propio token por seguridad:
   - `ecommerce-dev-webhook-token`
   - `ecommerce-stage-webhook-token`
   - `ecommerce-prod-webhook-token`

3. **Regex filtering:** El plugin filtra automáticamente por branch usando las expresiones regulares.

4. **Sin autenticación:** El endpoint `/generic-webhook-trigger/invoke` **no requiere autenticación**, pero puedes agregar tokens para más seguridad.

5. **Múltiples pipelines:** Un solo webhook de GitHub puede activar múltiples pipelines si sus regex coinciden.

---

## 🔒 Seguridad (Opcional)

### Agregar Restricción de IP

En Jenkins Security:
1. Manage Jenkins → Security → Configure Global Security
2. En "Authorization", puedes restringir quién puede invocar webhooks
3. Whitelist de IPs de GitHub: https://api.github.com/meta

```bash
curl https://api.github.com/meta | jq '.hooks'
```

---

## 🆘 Troubleshooting

### Webhook devuelve 200 pero pipeline no se activa

1. Verifica que el pipeline existe en Jenkins
2. Verifica que el Jenkinsfile tiene el `GenericTrigger` configurado
3. Verifica que el regex coincide con el branch:
   ```bash
   echo "refs/heads/release/v1.1.0" | grep -E '^refs/heads/release/.*$'
   ```

### Pipeline se activa pero falla

1. Revisa los logs del build en Jenkins
2. Verifica que las variables `$ref`, `$repository_name`, etc. se están extrayendo correctamente
3. Asegúrate que el pipeline tiene acceso a Git y AWS

### Webhook devuelve 404

1. Verifica que el plugin Generic Webhook Trigger está instalado
2. Verifica la URL: debe ser exactamente `/generic-webhook-trigger/invoke`

---

## ✅ Checklist de Configuración

- [ ] Plugin Generic Webhook Trigger instalado en Jenkins
- [ ] Jenkinsfile.dev actualizado con GenericTrigger
- [ ] Jenkinsfile.stage actualizado con GenericTrigger
- [ ] Jenkinsfile.prod actualizado con GenericTrigger
- [ ] Jenkinsfiles pusheados a GitHub
- [ ] Pipelines actualizados en Jenkins (build manual para leer nuevo Jenkinsfile)
- [ ] Webhook de GitHub configurado con URL correcta
- [ ] Test manual con curl devuelve 200 OK
- [ ] Push real activa el pipeline correspondiente
- [ ] Build logs muestran "Triggered by GitHub push"

---

## 📚 Recursos

- Plugin Documentation: https://plugins.jenkins.io/generic-webhook-trigger/
- GitHub Webhooks: https://docs.github.com/en/developers/webhooks-and-events/webhooks
- Ejemplo de otro proyecto: `http://68.211.125.173/generic-webhook-trigger/invoke?token=terraform-webhook-token`

---

**¡Listo!** Tu configuración de webhooks debería estar funcionando perfectamente sin problemas de CSRF 403.
