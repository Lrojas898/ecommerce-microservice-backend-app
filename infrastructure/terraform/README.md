# Terraform Infrastructure for Ecommerce Microservices

Este directorio contiene la configuración de Terraform para desplegar toda la infraestructura necesaria en AWS.

## Componentes

- **Jenkins Server**: EC2 instance con Jenkins, Docker, AWS CLI, kubectl, Maven
- **EKS Cluster**: Kubernetes cluster con 2-4 nodes
- **IAM Roles**: Roles necesarios para Jenkins y EKS
- **Security Groups**: Firewall rules para Jenkins

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

### 1. Acceder a Jenkins

```bash
# Obtener la URL de Jenkins
terraform output jenkins_url

# Obtener la contraseña inicial
terraform output -raw get_jenkins_password | bash
```

### 2. Configurar kubectl

```bash
# Configurar kubectl para conectarse a EKS
terraform output -raw configure_kubectl | bash

# Verificar conexión
kubectl get nodes

# Crear namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
```

### 3. Configurar Jenkins

1. Acceder a Jenkins UI
2. Instalar plugins sugeridos
3. Crear usuario admin
4. Configurar AWS credentials
5. Configurar kubectl en Jenkins

## Destruir Infraestructura

⚠️ **IMPORTANTE**: Esto eliminará TODOS los recursos

```bash
terraform destroy
```

## Costos Estimados

- Jenkins EC2 (t3.medium): ~$0.0416/hora = ~$30/mes
- EKS Control Plane: $0.10/hora = ~$72/mes
- EKS Nodes (2x t3.medium): ~$0.0832/hora = ~$60/mes
- **Total**: ~$162/mes

## Archivos

```
terraform/
├── provider.tf           # Provider AWS configuration
├── variables.tf          # Variables globales
├── main.tf              # Módulos principales
├── outputs.tf           # Outputs principales
├── terraform.tfvars     # Valores de variables
├── jenkins/
│   ├── main.tf          # Jenkins EC2 configuration
│   ├── outputs.tf       # Jenkins outputs
│   ├── variables.tf     # Jenkins variables
│   └── user-data.sh     # Script de instalación
└── eks/
    ├── main.tf          # EKS cluster configuration
    ├── outputs.tf       # EKS outputs
    └── variables.tf     # EKS variables
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
