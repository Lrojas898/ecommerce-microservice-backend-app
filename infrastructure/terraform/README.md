# Terraform Infrastructure for Ecommerce Microservices

Este directorio contiene la configuración de Terraform para desplegar toda la infraestructura necesaria en AWS para el **Taller 2: Pruebas y Lanzamiento**.

## Componentes

- **ECR Repositories**: 9 repositorios para los microservicios e infraestructura
  - service-discovery, cloud-config, api-gateway
  - user-service, product-service, order-service, payment-service, shipping-service, favourite-service
- **Jenkins Server**: EC2 instance (m7i-flex.large) con Jenkins, Docker, AWS CLI, kubectl, Maven
- **SonarQube Server**: EC2 instance (t3.small) para análisis de calidad de código
- **EKS Cluster**: Kubernetes cluster v1.28 con node group configurable (1-4 nodes t3.small)
- **IAM Roles**: Roles necesarios para Jenkins, EKS cluster y EKS nodes
- **Security Groups**: Firewall rules para Jenkins y SonarQube
- **Elastic IPs**: IPs públicas fijas para Jenkins y SonarQube

## Requisitos Previos

1. AWS CLI configurado
2. Terraform instalado (v1.0+)
3. Credenciales AWS con permisos suficientes

## Despliegue

```bash
# 1. Ir al directorio de terraform
cd infrastructure/terraform

# 2. Inicializar Terraform
terraform init

# 3. Ver el plan de ejecución
terraform plan

# 4. Aplicar cambios
terraform apply

# 5. Guardar los outputs
terraform output > outputs.txt
```

## Después del Despliegue

### 1. Ver toda la información de la infraestructura

```bash
# Ver resumen completo con todos los outputs
terraform output next_steps

# O ver outputs individuales
terraform output jenkins_url
terraform output sonarqube_url
terraform output eks_cluster_name
```

### 2. Acceder a Jenkins

```bash
# Obtener la URL de Jenkins
terraform output jenkins_url

# Obtener la contraseña inicial
terraform output -raw get_jenkins_password
```

### 3. Acceder a SonarQube

```bash
# Obtener la URL de SonarQube
terraform output sonarqube_url

# Credenciales por defecto: admin / admin (cambiar en primer login)
```

### 4. Configurar kubectl

```bash
# Configurar kubectl para conectarse a EKS
terraform output -raw eks_kubectl_config

# O ejecutar directamente:
aws eks update-kubeconfig --region us-east-1 --name ecommerce-microservices-cluster

# Verificar conexión
kubectl get nodes

# Verificar namespaces (deben existir: dev, staging, production)
kubectl get namespaces
```

### 5. Configurar Jenkins

1. Acceder a Jenkins UI (http://JENKINS_IP:8080)
2. Usar contraseña inicial obtenida en paso 2
3. Instalar plugins recomendados:
   - Docker Pipeline
   - Kubernetes CLI
   - AWS Steps
   - Pipeline
   - Git
4. Crear usuario admin personalizado
5. Configurar credenciales:
   - AWS credentials (Access Key ID + Secret Access Key)
   - GitHub credentials (si usas repo privado)
   - Configurar kubectl access a EKS

### 6. Crear Pipelines en Jenkins

```bash
# Los Jenkinsfiles están en:
infrastructure/jenkins/Jenkinsfile.dev      # Build y push a ECR
infrastructure/jenkins/Jenkinsfile.stage    # Deploy + Tests en Staging
infrastructure/jenkins/Jenkinsfile.prod     # Deploy a Production con Release Notes
```

## Destruir Infraestructura

⚠️ **IMPORTANTE**: Esto eliminará TODOS los recursos

```bash
terraform destroy
```

## Costos Estimados (US East 1)

- Jenkins EC2 (m7i-flex.large): ~$0.17/hora = ~$123/mes
- SonarQube EC2 (t3.small): ~$0.0208/hora = ~$15/mes
- EKS Control Plane: $0.10/hora = ~$72/mes
- EKS Nodes (2x t3.small): ~$0.0416/hora = ~$30/mes
- ECR Storage: ~$0.10/GB/mes (minimal para imágenes)
- **Total**: ~$240/mes

### Tips para Reducir Costos:

```bash
# Escalar node group a 0 cuando no uses el cluster
kubectl scale deployment --all --replicas=0 -n dev
kubectl scale deployment --all --replicas=0 -n staging
kubectl scale deployment --all --replicas=0 -n production

# O reducir el node group completamente (requiere acceso AWS)
aws eks update-nodegroup-config \
  --cluster-name ecommerce-microservices-cluster \
  --nodegroup-name standard-workers \
  --scaling-config minSize=0,maxSize=4,desiredSize=0

# Detener instancias EC2 cuando no uses (no eliminar)
aws ec2 stop-instances --instance-ids <jenkins-instance-id> <sonarqube-instance-id>
```

## Estructura de Archivos

```
terraform/
├── provider.tf           # AWS provider configuration
├── variables.tf          # Variables globales
├── main.tf              # Módulos principales (ECR, Jenkins, SonarQube, EKS)
├── outputs.tf           # Outputs de todos los módulos
├── terraform.tfvars     # Valores de variables (editable)
├── ecr/
│   ├── main.tf          # 9 ECR repositories
│   ├── outputs.tf       # URLs y comandos ECR
│   └── variables.tf     # Variables ECR
├── jenkins/
│   ├── main.tf          # Jenkins EC2 + Security Group
│   ├── outputs.tf       # Jenkins URL, IP, SSH
│   ├── variables.tf     # Variables Jenkins
│   └── user-data.sh     # Script instalación Jenkins
├── sonarqube/
│   ├── main.tf          # SonarQube EC2 + Security Group
│   ├── outputs.tf       # SonarQube URL, IP, credenciales
│   └── variables.tf     # Variables SonarQube
└── eks/
    ├── main.tf          # EKS cluster + node group + IAM roles
    ├── outputs.tf       # EKS endpoint, kubectl config
    └── variables.tf     # Variables EKS
```

## Troubleshooting

### Error: "No valid credential sources found"
```bash
aws configure
```

### Error: "Insufficient permissions"
Asegúrate de tener permisos para:
- EC2 (crear instancias, security groups)
- IAM (crear roles, policies)
- EKS (crear clusters)
- VPC (acceder a default VPC)

### Jenkins no inicia
```bash
# SSH a la instancia
ssh ec2-user@<jenkins-ip>

# Ver logs
sudo systemctl status jenkins
sudo journalctl -u jenkins -f
```
