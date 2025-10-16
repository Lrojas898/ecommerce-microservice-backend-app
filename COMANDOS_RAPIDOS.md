# Comandos Rápidos para Gestión de Infraestructura

## 🛑 Detener TODO (ahorra créditos AWS)
```bash
cd infrastructure/scripts
./stop-all-infrastructure.sh
```

**Qué hace:**
- Detiene instancia Jenkins (deja de cobrar)
- Escala EKS a 0 nodos (solo cobra control plane)
- **NO BORRA NADA** - toda tu configuración se mantiene

**Ahorro:** ~$2.88/día

---

## ▶️ Iniciar TODO (cuando vuelvas a trabajar)
```bash
cd infrastructure/scripts
./start-all-infrastructure.sh
```

**Qué hace:**
- Inicia instancia Jenkins
- Escala EKS a 2 nodos
- Configura kubectl automáticamente
- Te muestra la URL de Jenkins

---

## 🔍 Ver estado actual
```bash
# Ver instancias EC2
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ecommerce-microservices-jenkins-server" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# Ver EKS cluster
aws eks describe-cluster --name ecommerce-eks-cluster --query 'cluster.status'

# Ver EKS nodes
kubectl get nodes
```

---

## 🌐 Acceder a Jenkins

**URL:** http://[IP_PUBLICA]:8080

**Obtener contraseña inicial:**
```bash
# Opción 1: Desde tu máquina (recomendado)
aws ssm start-session --target i-0af2fd5aff9ff71e8 --document-name AWS-StartInteractiveCommand --parameters command="cat /home/ec2-user/jenkins-password.txt"

# Opción 2: SSH tradicional
ssh -i ~/.ssh/tu-key.pem ec2-user@[IP_PUBLICA]
cat /home/ec2-user/jenkins-password.txt
```

---

## 🧪 Ejecutar pruebas localmente

```bash
# Todas las pruebas
./mvnw clean test

# Solo un servicio
cd order-service
../mvnw test

# Solo pruebas de integración
./mvnw test -Dtest="*IT"

# Solo pruebas unitarias
./mvnw test -Dtest="*Test"
```

---

## 🐳 Build y Push a ECR

```bash
# Un servicio específico
cd infrastructure/scripts
./build-and-push.sh order-service

# Todos los servicios
./build-all.sh
```

---

## ☸️ Desplegar a Kubernetes

```bash
# Configurar kubectl (si EKS está corriendo)
aws eks update-kubeconfig --region us-east-1 --name ecommerce-eks-cluster

# Crear namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# Desplegar un servicio
kubectl apply -f infrastructure/kubernetes/base/order-service.yaml -n dev

# Ver deployments
kubectl get deployments -n dev
kubectl get pods -n dev
kubectl get services -n dev
```

---

## 🗑️ Destruir TODO (al final del proyecto)

```bash
cd infrastructure/terraform
terraform destroy -auto-approve
```

**⚠️ ADVERTENCIA:** Esto BORRA TODA la infraestructura. Úsalo solo cuando termines el proyecto.

---

## 💰 Costos Estimados

| Recurso | Estado Running | Estado Stopped | Ahorro |
|---------|---------------|----------------|--------|
| Jenkins EC2 (t3.medium) | $0.042/hora | $0.00/hora | $1.01/día |
| EKS Control Plane | $0.10/hora | $0.10/hora | $0.00 |
| EKS Nodes (2x t3.medium) | $0.084/hora | $0.00/hora | $2.02/día |
| **TOTAL** | **$5.42/día** | **$2.40/día** | **$3.02/día** |

**Recomendación:** Usa `stop-all-infrastructure.sh` al final de cada sesión de trabajo.

---

## 🎯 Workflow Diario Recomendado

**Inicio del día:**
```bash
cd infrastructure/scripts
./start-all-infrastructure.sh
# Espera 2-3 minutos a que todo arranque
```

**Trabajo normal:**
- Desarrollar pruebas localmente
- Hacer commits
- Probar pipelines en Jenkins cuando sea necesario

**Final del día:**
```bash
cd infrastructure/scripts
./stop-all-infrastructure.sh
```

---

## 📞 Contactos de Ayuda

- **Terraform docs:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Jenkins docs:** https://www.jenkins.io/doc/
- **Kubernetes docs:** https://kubernetes.io/docs/
- **AWS EKS docs:** https://docs.aws.amazon.com/eks/
