# Fix GitHub Webhook - Guía de Solución

**Problema Detectado:** El webhook de GitHub está recibiendo **403 Forbidden** de Jenkins.

---

## 🔴 Problemas Identificados:

### 1. URL Duplicada ❌
**Actual:**
```
http://3.12.227.83:8080/:8080/github-webhook/
                          ^^^^^ DUPLICADO
```

**Correcto:**
```
http://3.12.227.83:8080/github-webhook/
```

### 2. CSRF Protection (403 Forbidden) ❌
Jenkins tiene CSRF protection habilitada, lo que causa el 403.

---

## ✅ Soluciones:

### **Opción 1: Arreglar URL y Deshabilitar CSRF para GitHub Webhook (Recomendado)**

#### Paso 1: Arreglar la URL en GitHub

1. Ve a GitHub: https://github.com/Lrojas898/ecommerce-microservice-backend-app/settings/hooks
2. Edita el webhook
3. Cambia la URL de:
   ```
   http://3.12.227.83:8080/:8080/github-webhook/
   ```
   A:
   ```
   http://3.12.227.83:8080/github-webhook/
   ```
4. Guarda los cambios

#### Paso 2: Configurar Jenkins para Aceptar Webhooks de GitHub

**Método A: Deshabilitar CSRF solo para GitHub webhook (más seguro)**

Conectarse a Jenkins via SSH:
```bash
ssh -i <tu-key.pem> ec2-user@3.12.227.83
```

Editar configuración de Jenkins:
```bash
# Editar el archivo de configuración de Jenkins
sudo docker exec -it jenkins bash

# Dentro del container de Jenkins
cat >> /var/jenkins_home/hudson.plugins.git.GitSCM.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<hudson.plugins.git.GitSCM_-DescriptorImpl plugin="git@5.7.0">
  <generation>2</generation>
  <globalConfigName>jenkins</globalConfigName>
  <globalConfigEmail>jenkins@localhost</globalConfigEmail>
  <createAccountBasedOnEmail>false</createAccountBasedOnEmail>
  <useExistingAccountWithSameEmail>false</useExistingAccountWithSameEmail>
  <allowSecondFetch>false</allowSecondFetch>
  <disableGitToolChooser>false</disableGitToolChooser>
  <hideCredentials>false</hideCredentials>
  <showEntireCommitSummaryInChanges>false</showEntireCommitSummaryInChanges>
  <addGitTagAction>false</addGitTagAction>
</hudson.plugins.git.GitSCM_-DescriptorImpl>
EOF
```

Luego, en Jenkins UI:
1. Ve a: `Manage Jenkins` → `Security` → `Configure Global Security`
2. En "CSRF Protection" section, encuentra "Crumb Issuer"
3. Agrega exclusión para `/github-webhook/`

O bien, agrega a la whitelist usando Script Console:

```groovy
import jenkins.model.Jenkins
import hudson.security.csrf.DefaultCrumbIssuer

def jenkins = Jenkins.instance
def crumbIssuer = jenkins.getCrumbIssuer()

if (crumbIssuer instanceof DefaultCrumbIssuer) {
    crumbIssuer.setExcludedClientIPAddresses('0.0.0.0/0')  // GitHub IPs
}

jenkins.save()
```

**Método B: Usar plugin GitHub (recomendado - ya lo tienes instalado)**

El plugin de GitHub maneja automáticamente la CSRF protection. Solo necesitas:

1. Ir a: `Manage Jenkins` → `System` → `GitHub` section
2. Verificar que la configuración de "Override Hook URL" esté vacía o correcta
3. El plugin debe manejar los webhooks sin problemas

---

### **Opción 2: Usar GitHub Plugin con Token (Más Seguro)**

#### Paso 1: Generar Token en GitHub

1. Ve a GitHub: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Nombre: `Jenkins Webhook Token`
4. Scopes necesarios:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `admin:repo_hook` (Full control of repository hooks)
5. Genera y **copia el token**

#### Paso 2: Configurar en Jenkins

1. `Manage Jenkins` → `Credentials` → `System` → `Global credentials`
2. Click `Add Credentials`
3. Tipo: `Secret text`
4. Secret: `<tu-token-de-github>`
5. ID: `github-webhook-token`
6. Description: `GitHub Webhook Token`
7. Save

#### Paso 3: Configurar GitHub Server en Jenkins

1. `Manage Jenkins` → `System`
2. Busca sección "GitHub"
3. Click "Add GitHub Server" → "GitHub Server"
4. Name: `github`
5. API URL: `https://api.github.com`
6. Credentials: Selecciona `github-webhook-token`
7. Click "Test connection"
8. Save

---

### **Opción 3: Usar Secret en el Webhook (Más Simple)**

#### Paso 1: Generar un Secret Token

```bash
# Generar token aleatorio
openssl rand -hex 20
# Copia el resultado, ej: a7f3e2c1d9b8f6e4a3c2d1e0f9b8a7c6d5e4f3c2
```

#### Paso 2: Configurar el Secret en GitHub Webhook

1. Ve al webhook: https://github.com/Lrojas898/ecommerce-microservice-backend-app/settings/hooks
2. En "Secret", pega el token generado
3. Save

#### Paso 3: Configurar Jenkins para Validar el Secret

Crear/editar el archivo de configuración:

```bash
# SSH a Jenkins
ssh -i <tu-key.pem> ec2-user@3.12.227.83

# Editar docker-compose.yml para agregar variable de entorno
sudo nano /home/ec2-user/docker-compose.yml
```

Agregar bajo `environment` de Jenkins:
```yaml
- GITHUB_WEBHOOK_SECRET=a7f3e2c1d9b8f6e4a3c2d1e0f9b8a7c6d5e4f3c2
```

Reiniciar Jenkins:
```bash
sudo docker-compose restart jenkins
```

---

## 🚀 Solución Rápida (Recomendada para Testing):

### **Solo arreglar la URL - Método más simple**

1. **En GitHub Webhook Settings:**
   - URL: `http://3.12.227.83:8080/github-webhook/` (quitar el `:8080` duplicado)
   - Content type: `application/json`
   - Secret: *(dejar vacío por ahora)*
   - SSL verification: Enable SSL verification
   - Events: Solo "Push events" y "Pull requests"

2. **En Jenkins - Deshabilitar temporalmente CSRF (SOLO PARA TESTING):**

   Via Jenkins Script Console (`Manage Jenkins` → `Script Console`):
   ```groovy
   import jenkins.model.Jenkins

   def jenkins = Jenkins.instance
   jenkins.setCrumbIssuer(null)
   jenkins.save()

   println "CSRF Protection disabled - ONLY FOR TESTING!"
   ```

   **⚠️ IMPORTANTE:** Esto deshabilita CSRF completamente. Úsalo solo para testing.

3. **Volver a habilitar CSRF después del test:**
   ```groovy
   import jenkins.model.Jenkins
   import hudson.security.csrf.DefaultCrumbIssuer

   def jenkins = Jenkins.instance
   jenkins.setCrumbIssuer(new DefaultCrumbIssuer(false))
   jenkins.save()

   println "CSRF Protection re-enabled"
   ```

---

## 🧪 Probar el Webhook:

### Desde GitHub:

1. Ve al webhook: https://github.com/Lrojas898/ecommerce-microservice-backend-app/settings/hooks
2. Click en el webhook
3. Tab "Recent Deliveries"
4. Click en la última delivery
5. Click "Redeliver"
6. Verifica que la respuesta sea **200 OK** en lugar de **403 Forbidden**

### Desde Terminal:

```bash
# Test manual del webhook
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/release/v1.1.0","repository":{"name":"ecommerce-microservice-backend-app"}}' \
  http://3.12.227.83:8080/github-webhook/
```

**Respuesta esperada:** Debería devolver algo relacionado con Jenkins procesando el webhook.

---

## 🔍 Verificar que el Pipeline se Activó:

### Via Jenkins UI:

1. Abre Jenkins: http://3.12.227.83:8080
2. Ve a "Ecommerce-STAGE-Pipeline" (o el pipeline correspondiente)
3. Verifica en "Build History" si hay un nuevo build
4. Si hay build, click en él para ver los logs

### Via Jenkins CLI:

```bash
# Ver últimos builds
curl -s http://3.12.227.83:8080/job/Ecommerce-STAGE-Pipeline/api/json | jq '.builds[0]'
```

---

## 📊 IPs de GitHub para Whitelist (Opcional):

Si quieres permitir solo IPs de GitHub en tu Security Group o firewall:

```bash
# Obtener IPs de GitHub
curl https://api.github.com/meta | jq '.hooks'
```

Agregar estas IPs a:
- AWS Security Group del Jenkins EC2
- O en Jenkins CSRF exclusion list

---

## ✅ Checklist de Verificación:

- [ ] URL del webhook corregida (sin `:8080` duplicado)
- [ ] Webhook configurado para eventos "Push" y "Pull request"
- [ ] Content-type: `application/json`
- [ ] CSRF protection manejada (deshabilitada temporalmente o configurada correctamente)
- [ ] Test delivery devuelve 200 OK
- [ ] Pipeline se activa automáticamente en Jenkins
- [ ] Build logs muestran que fue triggered por GitHub webhook

---

## 🔒 Mejores Prácticas (Para Producción):

1. **Usar Secret Token** en el webhook
2. **Mantener CSRF habilitado** con exclusión para GitHub IPs
3. **Usar HTTPS** en lugar de HTTP (requiere certificado SSL)
4. **Limitar IPs** en Security Group a solo GitHub hook IPs
5. **Monitorear webhook deliveries** regularmente

---

## 🆘 Troubleshooting:

### Si sigue devolviendo 403:

1. Verifica logs de Jenkins:
   ```bash
   ssh ec2-user@3.12.227.83
   sudo docker logs jenkins --tail 100 -f
   ```

2. Busca mensajes relacionados con CSRF o webhooks

### Si el pipeline no se activa:

1. Verifica que el branch name en el webhook match el trigger del Jenkinsfile
2. Revisa "Scan Organization Folder Log" si estás usando GitHub Organization
3. Verifica que el Jenkinsfile tenga el `when { branch 'release/*' }` correcto

---

**Fecha:** 2025-10-24
**Autor:** DevOps Team
**Jenkins URL:** http://3.12.227.83:8080
**GitHub Repo:** https://github.com/Lrojas898/ecommerce-microservice-backend-app
