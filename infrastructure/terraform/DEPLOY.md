# Guía de Despliegue Simplificada - AWS Academy

## Paso 1: Desplegar Jenkins con Terraform

```bash
cd infrastructure/terraform

# Inicializar
terraform init

# Ver plan
terraform plan

# Aplicar (tarda ~3 minutos)
terraform apply -auto-approve

# Guardar outputs
terraform output > ../../TERRAFORM_OUTPUTS.txt
```

## Paso 2: Esperar a que Jenkins esté listo

```bash
# Ver la URL de Jenkins
terraform output jenkins_url

# Esperar ~3 minutos mientras Jenkins se instala
# Verificar: ssh a la instancia y revisar logs
terraform output -raw jenkins_ssh_command | bash

# Dentro de la instancia:
sudo systemctl status jenkins
```

## Paso 3: Configurar Jenkins

```bash
# Obtener contraseña inicial
terraform output -raw get_jenkins_password | bash

# Acceder a Jenkins en el navegador
# URL en: terraform output jenkins_url

# Seguir wizard de configuración
```

## Paso 4: Crear cluster EKS (OPCIONAL - si tienes tiempo)

```bash
# Desde tu máquina local (NO desde Jenkins)
eksctl create cluster \
  --name ecommerce-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --managed

# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name ecommerce-cluster

# Crear namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
```

## Alternativa SIN EKS (Para enfocarse en pipelines)

Si no quieres gastar en EKS, puedes:

1. Usar Minikube local
2. O simplificar: solo documentar que el pipeline "desplegaría" a K8s
3. Enfocarte en los Jenkinsfiles y las pruebas

## Destruir todo

```bash
# Eliminar Jenkins
cd infrastructure/terraform
terraform destroy -auto-approve

# Eliminar EKS (si lo creaste)
eksctl delete cluster --name ecommerce-cluster --region us-east-1
```

## Costos

- Jenkins EC2 (t3.medium): ~$0.04/hora = ~$1/día
- EKS Cluster: ~$0.10/hora control plane + $0.08/hora nodes = ~$4.32/día

**Total: ~$5.32/día si usas EKS**
**Total: ~$1/día si SOLO usas Jenkins**

**Recomendación:** Destruir al final del día con `terraform destroy`
