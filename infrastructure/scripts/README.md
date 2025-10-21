# Jenkins Setup Scripts

Scripts para configurar Jenkins automáticamente después de aplicar Terraform.

## 📋 Orden de Ejecución

### 1. Configurar el servidor Jenkins (vía SSH)

Después de `terraform apply`, conéctate a la instancia de Jenkins:

```bash
# Obtener la IP pública de Jenkins desde Terraform output
JENKINS_IP=$(cd infrastructure/terraform && terraform output -raw jenkins_public_ip)

# Conectarse vía SSH
ssh -i ~/.ssh/your-key.pem ubuntu@$JENKINS_IP
```

Ejecuta el script de configuración del sistema:

```bash
# Descarga el script
wget https://raw.githubusercontent.com/Lrojas898/ecommerce-microservice-backend-app/release/v1.0.0/infrastructure/scripts/jenkins-setup.sh

# O si ya clonaste el repo:
git clone https://github.com/Lrojas898/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-backend-app/infrastructure/scripts

# Dar permisos de ejecución
chmod +x jenkins-setup.sh

# Ejecutar como root
sudo ./jenkins-setup.sh
```

### 2. Configurar AWS Credentials

```bash
sudo su - jenkins
aws configure
# Ingresa:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-2
# - Default output format: json
```

### 3. Acceder a Jenkins UI

```bash
# Obtener la contraseña inicial de Jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Abre en tu navegador: `http://<JENKINS_IP>:8080`

### 4. Instalar Plugins (vía Script Console)

En Jenkins UI:
1. Ve a **Manage Jenkins** > **Script Console**
2. Copia y pega el contenido de `jenkins-plugins-install.groovy`
3. Click en **Run**
4. Espera a que Jenkins se reinicie automáticamente

### 5. Crear Jobs Automáticamente (vía Script Console)

Después del reinicio:
1. Ve nuevamente a **Manage Jenkins** > **Script Console**
2. Copia y pega el contenido de `jenkins-jobs-setup.groovy`
3. Click en **Run**
4. Los 7 pipelines se crearán automáticamente

## 📁 Archivos Incluidos

| Archivo | Propósito | Dónde ejecutar |
|---------|-----------|----------------|
| `jenkins-setup.sh` | Instala Docker, AWS CLI, kubectl, Maven, Java | SSH en servidor Jenkins |
| `jenkins-plugins-install.groovy` | Instala todos los plugins necesarios | Jenkins Script Console |
| `jenkins-jobs-setup.groovy` | Crea los 7 pipelines del proyecto | Jenkins Script Console |

## ✅ Verificación

Después de ejecutar todos los scripts, deberías tener:

### Herramientas instaladas:
- ✓ Docker
- ✓ AWS CLI v2
- ✓ kubectl
- ✓ Maven 3.x
- ✓ Java 17

### Plugins instalados:
- ✓ Pipeline
- ✓ Git / GitHub
- ✓ Docker Workflow
- ✓ Kubernetes
- ✓ AWS Steps
- ✓ Maven
- ✓ JUnit / JaCoCo
- ✓ SonarQube Scanner

### Jobs creados:
- ✓ Ecommerce-DEV-Pipeline
- ✓ Ecommerce-STAGE-Pipeline
- ✓ Ecommerce-PROD-Pipeline
- ✓ Ecommerce-Build-Pipeline
- ✓ Ecommerce-Deploy-DEV
- ✓ Ecommerce-Deploy-PROD
- ✓ Ecommerce-Infrastructure

## 🔧 Configuración Manual Adicional

### Credenciales en Jenkins

Ve a **Manage Jenkins** > **Credentials** > **System** > **Global credentials**:

1. **AWS Credentials**:
   - Kind: `AWS Credentials`
   - ID: `aws-credentials`
   - Access Key ID: `<tu-access-key>`
   - Secret Access Key: `<tu-secret-key>`

2. **GitHub Token** (opcional, si el repo es privado):
   - Kind: `Secret text`
   - ID: `github-token`
   - Secret: `<tu-github-pat>`

3. **Docker Registry** (si usas registry privado):
   - Kind: `Username with password`
   - ID: `docker-registry`
   - Username: `AWS`
   - Password: `<token-de-ecr>`

### Configurar kubectl para EKS

```bash
sudo su - jenkins
aws eks update-kubeconfig --name ecommerce-microservices-cluster --region us-east-2
kubectl get nodes  # Verificar conexión
```

## 🚀 Primer Build

1. Ve a **Ecommerce-Build-Pipeline**
2. Click en **Build Now**
3. Espera a que se construyan todas las imágenes Docker
4. Ve a **Ecommerce-Deploy-DEV**
5. Click en **Build Now**
6. Verifica los pods: `kubectl get pods -n dev`

## 🐛 Troubleshooting

### Error: Docker permission denied
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Error: kubectl command not found
```bash
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
```

### Error: AWS credentials not configured
```bash
sudo su - jenkins
aws configure
```

### Error: Cannot connect to EKS cluster
```bash
aws eks update-kubeconfig --name ecommerce-microservices-cluster --region us-east-2
```

## 📞 Soporte

Si encuentras problemas, verifica:
1. Security groups permiten acceso a Jenkins (puerto 8080)
2. IAM role de Jenkins tiene permisos necesarios
3. Logs de Jenkins: `/var/log/jenkins/jenkins.log`
