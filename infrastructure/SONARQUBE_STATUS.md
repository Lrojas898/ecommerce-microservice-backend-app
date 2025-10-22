# 🔍 Estado de SonarQube - Diagnóstico

**Fecha:** 2025-10-20
**Revisor:** DevOps Team

---

## 📊 Estado Actual

### ✅ Infraestructura AWS

| Componente | Estado | Detalles |
|------------|--------|----------|
| **EC2 Instance** | ✅ Running | i-0711a0acd3c5ae054 |
| **Instance Type** | ✅ t3.small | Adecuado para SonarQube |
| **Public IP** | ✅ 34.202.237.180 | Accesible |
| **Launch Time** | ✅ 2025-10-19 21:35 | Creada recientemente |
| **Security Group** | ✅ Configurado | sg-0e57a69bfb67480c6 |
| **Puerto 9000** | ✅ Abierto | 0.0.0.0/0 |
| **Puerto 22 (SSH)** | ✅ Abierto | 0.0.0.0/0 |

### ❌ Aplicación SonarQube

| Verificación | Estado | Detalle |
|--------------|--------|---------|
| **HTTP Response** | ❌ No responde | curl timeout |
| **Port 9000** | ❌ Cerrado | Connection refused |
| **API Status** | ❌ No disponible | /api/system/status no responde |

### ⚠️ Jenkins Integration

| Componente | Estado | Detalle |
|------------|--------|---------|
| **Jenkins Status** | ✅ Running | http://98.84.96.7:8080 |
| **SonarQube Plugin** | ❌ No instalado | No detectado en plugin list |
| **SonarQube Scanner** | ❓ Desconocido | Requiere verificación manual |

---

## 🔴 Problema Identificado

**SonarQube NO está corriendo dentro de la instancia EC2.**

La instancia está activa pero el servicio SonarQube (puerto 9000) no está respondiendo.

---

## 🛠️ Soluciones

### Opción 1: Instalar SonarQube en la Instancia Existente (Recomendado) ✅

```bash
# 1. Conectarse a la instancia
ssh ec2-user@34.202.237.180

# 2. Instalar Docker (si no está)
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# 3. Ejecutar SonarQube en Docker
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community

# 4. Verificar que está corriendo
docker ps
docker logs -f sonarqube

# Esperar 2-3 minutos para que SonarQube inicie completamente
```

**Tiempo:** ~5 minutos

---

### Opción 2: Aplicar Terraform para Crear SonarQube Correctamente

```bash
cd infrastructure/terraform

# Solo aplicar el módulo de SonarQube
terraform apply -target=module.sonarqube

# Esto creará una NUEVA instancia con SonarQube pre-instalado
```

**⚠️ Advertencia:** Esto creará una nueva instancia, la actual (i-0711a0acd3c5ae054) quedaría huérfana.

---

### Opción 3: Usar SonarQube Cloud (Alternativa)

Si no quieres mantener infraestructura:

1. Crear cuenta en **SonarCloud** (https://sonarcloud.io)
2. Conectar tu repositorio GitHub
3. Configurar en Jenkins con el token de SonarCloud

**Ventajas:**
- ✅ Sin mantenimiento de infraestructura
- ✅ Gratis para proyectos open source
- ✅ Más fácil de configurar

**Desventajas:**
- ❌ Datos en la nube (no on-premise)
- ❌ Límites en proyectos privados

---

## 🚀 Pasos para Configurar (Opción 1 Recomendada)

### 1. Instalar SonarQube en EC2

```bash
# Conectarse a la instancia
ssh ec2-user@34.202.237.180

# Instalar y ejecutar SonarQube
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Salir y volver a entrar para aplicar grupo docker
exit
ssh ec2-user@34.202.237.180

# Ejecutar SonarQube
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community

# Verificar logs
docker logs -f sonarqube
# Esperar hasta ver: "SonarQube is operational"
```

### 2. Acceder a SonarQube

```bash
# En tu navegador
http://34.202.237.180:9000

# Credenciales por defecto:
# Username: admin
# Password: admin

# CAMBIAR la contraseña en el primer login
```

### 3. Generar Token para Jenkins

1. Login en SonarQube
2. Ir a: **My Account → Security → Generate Token**
3. Nombre: `jenkins-integration`
4. Tipo: Global Analysis Token
5. Copiar el token generado (ej: `squ_1a2b3c4d5e6f...`)

### 4. Instalar Plugin en Jenkins

```bash
# Acceder a Jenkins
http://98.84.96.7:8080

# Ir a: Manage Jenkins → Plugins → Available plugins
# Buscar e instalar:
- SonarQube Scanner
- SonarQube Scanner for Maven (si usas Maven)

# Reiniciar Jenkins
```

### 5. Configurar SonarQube en Jenkins

```bash
# En Jenkins, ir a: Manage Jenkins → System

# Buscar sección "SonarQube servers"
# Agregar:
Name: sonarqube
Server URL: http://34.202.237.180:9000
Server authentication token: [el token generado en paso 3]

# Guardar
```

### 6. Configurar Scanner en Jenkins

```bash
# En Jenkins: Manage Jenkins → Tools

# Buscar "SonarQube Scanner"
# Agregar instalación:
Name: SonarScanner
Install automatically: ✓
Version: Latest

# Guardar
```

### 7. Actualizar Jenkinsfiles

Agregar stage de SonarQube en tus pipelines:

```groovy
stage('SonarQube Analysis') {
    steps {
        script {
            def scannerHome = tool 'SonarScanner'
            withSonarQubeEnv('sonarqube') {
                sh """
                    ${scannerHome}/bin/sonar-scanner \
                    -Dsonar.projectKey=ecommerce-${service} \
                    -Dsonar.sources=. \
                    -Dsonar.java.binaries=target/classes
                """
            }
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

---

## 📋 Verificación Post-Instalación

### Checklist:

- [ ] SonarQube responde en http://34.202.237.180:9000
- [ ] Login exitoso con admin/admin
- [ ] Contraseña cambiada
- [ ] Token generado para Jenkins
- [ ] Plugin SonarQube instalado en Jenkins
- [ ] SonarQube server configurado en Jenkins
- [ ] Scanner configurado en Jenkins Tools
- [ ] Prueba de análisis exitosa

### Comandos de Verificación:

```bash
# Verificar que SonarQube está corriendo
curl -s http://34.202.237.180:9000/api/system/status | jq

# Debe devolver:
# {
#   "id": "...",
#   "version": "...",
#   "status": "UP"
# }

# Verificar que Jenkins puede alcanzar SonarQube
# Desde Jenkins, ejecutar un pipeline de prueba
```

---

## 🔧 Troubleshooting

### SonarQube no inicia

```bash
# Ver logs del contenedor
docker logs sonarqube

# Problemas comunes:
# 1. Memoria insuficiente (mínimo 2GB RAM)
# 2. vm.max_map_count muy bajo

# Solución para vm.max_map_count:
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Jenkins no conecta con SonarQube

```bash
# 1. Verificar firewall
curl -v http://34.202.237.180:9000

# 2. Verificar token
# Regenerar token en SonarQube y actualizar en Jenkins

# 3. Verificar logs de Jenkins
# Jenkins → Manage Jenkins → System Log
```

### Contenedor SonarQube se detiene

```bash
# Reiniciar contenedor
docker restart sonarqube

# Ver por qué se detuvo
docker logs sonarqube --tail 100

# Si necesitas más memoria, modificar el comando:
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -e SONAR_JAVA_OPTS="-Xmx2g -Xms512m" \
  sonarqube:lts-community
```

---

## 📊 Próximos Pasos (después de instalación)

1. **Configurar Quality Profiles** en SonarQube
2. **Configurar Quality Gates** (umbrales de calidad)
3. **Integrar en pipelines DEV, STAGE y PROD**
4. **Revisar métricas** después de cada build:
   - Code Coverage
   - Code Smells
   - Bugs
   - Vulnerabilities
   - Security Hotspots
   - Technical Debt

---

## 💰 Costos

**Instancia actual:**
- EC2 t3.small: ~$0.0208/hora = ~$15/mes
- EBS 30GB: ~$3/mes
- **Total:** ~$18/mes

---

## 📞 Contacto

Si necesitas ayuda con la instalación, consulta:
- Documentación SonarQube: https://docs.sonarqube.org/
- Jenkins Plugin: https://plugins.jenkins.io/sonarqube/

---

**Estado:** ⚠️ SonarQube NO configurado
**Acción requerida:** Instalar SonarQube en EC2 existente
**Prioridad:** Media (no bloquea pipelines, pero importante para calidad)
**Tiempo estimado:** 30 minutos
