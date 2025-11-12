# Configuración de Backend Remoto para Terraform

Este documento explica cómo configurar y usar el backend remoto de Terraform con DigitalOcean Spaces.

---

## 📋 Tabla de Contenidos

1. [¿Por qué usar un backend remoto?](#por-qué-usar-un-backend-remoto)
2. [Configuración en DigitalOcean](#configuración-en-digitalocean)
3. [Configuración en GitHub](#configuración-en-github)
4. [Migración del Estado Local](#migración-del-estado-local)
5. [Uso Diario](#uso-diario)
6. [Troubleshooting](#troubleshooting)

---

## ¿Por qué usar un backend remoto?

### Problemas con backend local:
- ❌ El estado se pierde si se ejecuta desde diferentes máquinas
- ❌ No hay colaboración en equipo
- ❌ Riesgo de conflictos y corrupción del estado
- ❌ No hay versionado ni backups automáticos
- ❌ GitHub Actions no puede mantener el estado entre ejecuciones

### Ventajas del backend remoto:
- ✅ Estado centralizado y persistente
- ✅ Colaboración en equipo sin conflictos
- ✅ Bloqueo de estado (state locking)
- ✅ Versionado y backups automáticos
- ✅ Seguro y encriptado
- ✅ Funciona perfectamente con CI/CD

---

## Configuración en DigitalOcean

### Paso 1: Crear un Space

1. **Acceder a Spaces**:
   - Ve a: https://cloud.digitalocean.com/spaces
   - Click en: **"Create a Space"**

2. **Configurar el Space**:
   ```
   Región: nyc3
   Nombre: ecommerce-terraform-state
   Enable CDN: No
   File Listing: Restricted (Private)
   ```

3. **Click**: **"Create Space"**

### Paso 2: Generar Access Keys

1. **Acceder a API Keys**:
   - Ve a: https://cloud.digitalocean.com/account/api/spaces
   - Click en: **"Generate New Key"**

2. **Configurar la Key**:
   ```
   Nombre: terraform-backend
   ```

3. **Guardar las credenciales**:
   - ⚠️ **IMPORTANTE**: Copia ambas claves inmediatamente
   - `Access Key ID`: Ejemplo: `DO00ABC123XYZ...`
   - `Secret Access Key`: Ejemplo: `abc123xyz...` (solo se muestra una vez)

---

## Configuración en GitHub

### Paso 3: Agregar Secrets en GitHub

1. **Acceder a Secrets**:
   - Ve a tu repositorio en GitHub
   - Click en: **Settings** → **Secrets and variables** → **Actions**
   - Click en: **"New repository secret"**

2. **Crear el primer secret**:
   ```
   Name: SPACES_ACCESS_KEY
   Value: [Pega tu Access Key ID de DigitalOcean]
   ```
   - Click en: **"Add secret"**

3. **Crear el segundo secret**:
   ```
   Name: SPACES_SECRET_KEY
   Value: [Pega tu Secret Access Key de DigitalOcean]
   ```
   - Click en: **"Add secret"**

### Secrets Finales Requeridos

Deberías tener estos 4 secrets configurados:

| Secret Name | Descripción |
|-------------|-------------|
| `DO_TOKEN` | Token de API de DigitalOcean |
| `LETSENCRYPT_EMAIL` | Email para certificados SSL |
| `SPACES_ACCESS_KEY` | Access Key ID de Spaces |
| `SPACES_SECRET_KEY` | Secret Access Key de Spaces |

---

## Migración del Estado Local

### Caso 1: Primera vez usando Terraform (sin estado local)

Si nunca has ejecutado `terraform apply`, simplemente:

```bash
cd infrastructure/terraform
terraform init
```

Terraform creará el estado directamente en Spaces.

### Caso 2: Ya existe un estado local (terraform.tfstate)

Si ya ejecutaste `terraform apply` localmente y tienes un archivo `terraform.tfstate`:

```bash
cd infrastructure/terraform

# 1. Hacer backup del estado local
cp terraform.tfstate terraform.tfstate.backup

# 2. Configurar las credenciales de Spaces
export AWS_ACCESS_KEY_ID="your_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="your_spaces_secret_key"

# 3. Re-inicializar Terraform con el nuevo backend
terraform init -migrate-state

# Output esperado:
# Terraform will perform the following actions:
#
#   ~ backend "s3"
#       - local → remote (DigitalOcean Spaces)
#
# Do you want to copy existing state to the new backend?
#   Enter a value: yes

# 4. Verificar que el estado se migró correctamente
terraform state list

# 5. (Opcional) Eliminar el estado local
# rm terraform.tfstate
# rm terraform.tfstate.backup
```

⚠️ **IMPORTANTE**: No elimines el estado local hasta verificar que la migración fue exitosa.

---

## Uso Diario

### Desde tu máquina local

Cada vez que uses Terraform localmente:

```bash
# 1. Configurar credenciales (una sola vez por sesión)
export AWS_ACCESS_KEY_ID="your_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="your_spaces_secret_key"

# 2. Usar Terraform normalmente
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

**Tip**: Puedes agregar estas variables a tu `~/.bashrc` o `~/.zshrc`:

```bash
# DigitalOcean Spaces (Terraform Backend)
export AWS_ACCESS_KEY_ID="your_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="your_spaces_secret_key"
```

### Desde GitHub Actions

El workflow ya está configurado para usar los secrets automáticamente:
- Los secrets `SPACES_ACCESS_KEY` y `SPACES_SECRET_KEY` se pasan como variables de entorno
- No necesitas hacer nada adicional

---

## Verificación del Backend

### Verificar que el estado está en Spaces

1. **Desde la consola de DigitalOcean**:
   - Ve a: https://cloud.digitalocean.com/spaces
   - Click en: **ecommerce-terraform-state**
   - Deberías ver el archivo: `terraform.tfstate`

2. **Desde línea de comandos**:
   ```bash
   # Listar el contenido del Space
   aws s3 ls s3://ecommerce-terraform-state/ \
     --endpoint=https://nyc3.digitaloceanspaces.com

   # Output esperado:
   # terraform.tfstate
   ```

3. **Verificar el estado desde Terraform**:
   ```bash
   terraform state list
   ```

---

## Troubleshooting

### Error: "Error loading state"

**Problema**: Terraform no puede conectarse a Spaces

**Solución**:
```bash
# Verificar que las credenciales están configuradas
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# Si están vacías, configurarlas:
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
```

### Error: "Backend initialization required"

**Problema**: El backend no está inicializado

**Solución**:
```bash
terraform init
```

### Error: "Error acquiring state lock"

**Problema**: Otra persona/proceso está usando Terraform

**Solución**:
```bash
# Esperar a que termine la otra ejecución
# O, en caso de emergencia (solo si estás seguro):
terraform force-unlock <lock-id>
```

### Error: "NoSuchBucket"

**Problema**: El Space no existe o el nombre es incorrecto

**Solución**:
1. Verificar que el Space existe en DigitalOcean
2. Verificar que el nombre en `versions.tf` es correcto:
   ```hcl
   bucket = "ecommerce-terraform-state"
   ```

### El workflow de GitHub falla con "AccessDenied"

**Problema**: Los secrets no están configurados correctamente

**Solución**:
1. Verificar que los secrets existen:
   - Ir a: Settings → Secrets and variables → Actions
   - Verificar: `SPACES_ACCESS_KEY` y `SPACES_SECRET_KEY`
2. Regenerar las keys si es necesario en DigitalOcean

---

## Costos

### DigitalOcean Spaces Pricing

- **Almacenamiento**: $5/mes por 250 GB
- **Transferencia**: 1 TB incluido, luego $0.01/GB

### Costo del archivo terraform.tfstate

- **Tamaño típico**: < 1 MB
- **Costo real**: ~$0.00002/mes (prácticamente gratis)
- **Costo total de Spaces**: $5/mes (mínimo)

⚠️ **Nota**: Spaces tiene un cargo mínimo de $5/mes, incluso si solo usas unos pocos MB.

---

## Seguridad

### Mejores Prácticas

1. ✅ **Nunca commitear credenciales** al repositorio
2. ✅ **Usar secrets de GitHub** para CI/CD
3. ✅ **Rotar las keys periódicamente**
4. ✅ **Mantener el Space como privado**
5. ✅ **Hacer backups** del estado periódicamente

### Backup Manual del Estado

```bash
# Descargar el estado actual
terraform state pull > terraform.tfstate.backup-$(date +%Y%m%d)

# O usando AWS CLI
aws s3 cp s3://ecommerce-terraform-state/terraform.tfstate \
  terraform.tfstate.backup-$(date +%Y%m%d) \
  --endpoint=https://nyc3.digitaloceanspaces.com
```

---

## Referencias

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [DigitalOcean Spaces](https://docs.digitalocean.com/products/spaces/)
- [DigitalOcean Spaces API](https://docs.digitalocean.com/reference/api/spaces-api/)

---

## Resumen de Comandos

```bash
# Configurar credenciales (local)
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"

# Inicializar backend
cd infrastructure/terraform
terraform init

# Migrar estado existente
terraform init -migrate-state

# Verificar estado
terraform state list

# Ver backend configurado
terraform version

# Backup del estado
terraform state pull > backup.tfstate
```

---

**✅ Configuración completada!**

El estado de Terraform ahora está seguro en DigitalOcean Spaces y se mantendrá persistente entre ejecuciones de GitHub Actions.
