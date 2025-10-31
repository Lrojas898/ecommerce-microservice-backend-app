# Instrucciones para Importar Recursos de EBS CSI Driver a Terraform

Los recursos del EBS CSI Driver fueron creados manualmente y ahora están definidos en Terraform. Para sincronizar el estado de Terraform con los recursos existentes, sigue estos pasos:

## Recursos Creados Manualmente

1. **OIDC Provider**: `arn:aws:iam::020951019497:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/862E07CA11B9C356289BAD82F20ECB4E`
2. **IAM Role**: `AmazonEKS_EBS_CSI_DriverRole`
3. **EBS CSI Driver Addon**: `aws-ebs-csi-driver` en cluster `ecommerce-microservices-cluster`

## Opción 1: Importar Recursos Existentes (Recomendado para Producción)

Si quieres mantener los recursos existentes y solo actualizar Terraform state:

```bash
cd infrastructure/terraform/eks

# 1. Importar OIDC Provider
terraform import aws_iam_openid_connect_provider.eks \
  arn:aws:iam::020951019497:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/862E07CA11B9C356289BAD82F20ECB4E

# 2. Importar IAM Role
terraform import aws_iam_role.ebs_csi_driver AmazonEKS_EBS_CSI_DriverRole

# 3. Importar IAM Role Policy Attachment
terraform import aws_iam_role_policy_attachment.ebs_csi_driver \
  AmazonEKS_EBS_CSI_DriverRole/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

# 4. Importar EBS CSI Driver Addon
terraform import aws_eks_addon.ebs_csi_driver \
  ecommerce-microservices-cluster:aws-ebs-csi-driver
```

Después de importar, verifica que todo está correcto:

```bash
terraform plan
```

**Importante**: El plan puede mostrar que necesita actualizar el nombre del role de `AmazonEKS_EBS_CSI_DriverRole` a `ecommerce-microservices-ebs-csi-driver-role`. Si esto sucede, tienes dos opciones:

### Opción A: Mantener el nombre actual
Edita `ebs-csi-driver.tf` y cambia el nombre del role:
```hcl
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "AmazonEKS_EBS_CSI_DriverRole"  # Mantener nombre existente
  # ...
}
```

### Opción B: Recrear con el nuevo nombre
Simplemente ejecuta `terraform apply` y Terraform recreará el role con el nuevo nombre.

## Opción 2: Recrear Todo desde Terraform (Desarrollo/Testing)

Si estás en un ambiente de desarrollo, puedes eliminar los recursos manuales y dejar que Terraform los recree:

```bash
# 1. Eliminar recursos manuales
aws eks delete-addon --cluster-name ecommerce-microservices-cluster \
  --addon-name aws-ebs-csi-driver --region us-east-2

aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole

aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::020951019497:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/862E07CA11B9C356289BAD82F20ECB4E

# 2. Crear todo con Terraform
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

**Advertencia**: Eliminar y recrear causará downtime temporal en los PVCs que usen EBS.

## Verificación Final

Después de importar o recrear, verifica que todo funciona:

```bash
# Ver addons instalados
aws eks list-addons --cluster-name ecommerce-microservices-cluster --region us-east-2

# Ver pods del CSI driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Ver CSI drivers registrados
kubectl get csidriver

# Verificar que PostgreSQL puede crear PVCs
kubectl get pvc -n dev postgres-pvc
```

## Notas

- Los archivos de Terraform modificados están en `infrastructure/terraform/eks/ebs-csi-driver.tf`
- Los outputs adicionales están en `infrastructure/terraform/eks/outputs.tf`
- PostgreSQL deployment fue actualizado para usar `PGDATA=/var/lib/postgresql/data/pgdata` en `infrastructure/kubernetes/postgres-deployment.yaml`
