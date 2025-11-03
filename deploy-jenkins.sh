#!/bin/bash

# Script para deployar Jenkins en Minikube en namespace separado
# No afecta el deployment de microservicios en namespace 'dev'

set -e

# Variables
DOCKER_USERNAME="luisrojasc"
VERSION="latest"
JENKINS_NAMESPACE="jenkins"
KUBECTL_TIMEOUT="300s"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🏗️  Desplegando Jenkins CI/CD en Minikube..."
echo "📦 Usando imagen: $DOCKER_USERNAME/jenkins:$VERSION"
echo "🔒 En namespace separado: $JENKINS_NAMESPACE"

# Verificar que Minikube esté corriendo
if ! minikube status >/dev/null 2>&1; then
    echo_error "Minikube no está corriendo."
    exit 1
fi

# Crear namespace de Jenkins si no existe
echo_info "Configurando namespace $JENKINS_NAMESPACE..."
kubectl create namespace $JENKINS_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Limpiar deployment anterior de Jenkins si existe
echo_warning "Limpiando deployment anterior de Jenkins..."
kubectl delete deployment jenkins -n $JENKINS_NAMESPACE --ignore-not-found=true
kubectl delete service jenkins -n $JENKINS_NAMESPACE --ignore-not-found=true
kubectl delete pvc jenkins-pvc -n $JENKINS_NAMESPACE --ignore-not-found=true

echo_info "Esperando que los recursos se limpien..."
sleep 10

# Crear PersistentVolumeClaim para Jenkins
echo_info "Creando almacenamiento persistente para Jenkins..."
cat > /tmp/jenkins-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: $JENKINS_NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

kubectl apply -f /tmp/jenkins-pvc.yaml

# Crear deployment de Jenkins
echo_info "Creando deployment de Jenkins..."
cat > /tmp/jenkins-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: $JENKINS_NAMESPACE
  labels:
    app: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      containers:
      - name: jenkins
        image: $DOCKER_USERNAME/jenkins:$VERSION
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 50000 
          name: agent
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false -Djava.awt.headless=true -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true"
        - name: JENKINS_OPTS
          value: "--httpPort=8080"
        - name: DOCKER_HOST
          value: "unix:///var/run/docker.sock"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: docker-sock
          mountPath: /var/run/docker.sock
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 5
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 120
          periodSeconds: 20
          timeoutSeconds: 5
          failureThreshold: 5
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
          type: Socket
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: $JENKINS_NAMESPACE
  labels:
    app: jenkins
spec:
  selector:
    app: jenkins
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
    nodePort: 30080
  - name: agent
    port: 50000
    targetPort: 50000
    protocol: TCP
    nodePort: 30050
  type: NodePort
EOF

kubectl apply -f /tmp/jenkins-deployment.yaml

# Limpiar archivos temporales
rm /tmp/jenkins-pvc.yaml /tmp/jenkins-deployment.yaml

# Esperar que Jenkins esté listo
echo_info "Esperando que Jenkins esté listo..."
if kubectl wait --for=condition=available --timeout=$KUBECTL_TIMEOUT deployment/jenkins -n $JENKINS_NAMESPACE > /dev/null 2>&1; then
    echo_success "Jenkins está listo"
else
    echo_error "Jenkins no está listo después de $KUBECTL_TIMEOUT"
    exit 1
fi

# Verificar estado
echo ""
echo_info "Estado del deployment de Jenkins:"
kubectl get pods -n $JENKINS_NAMESPACE -o wide

echo ""
echo_info "Estado del servicio de Jenkins:"
kubectl get services -n $JENKINS_NAMESPACE

# Obtener URL de acceso
MINIKUBE_IP=$(minikube ip)
JENKINS_URL="http://$MINIKUBE_IP:30080"

echo ""
echo "🎉 ¡Jenkins desplegado exitosamente!"
echo ""
echo "📋 Información del despliegue:"
echo "   - Namespace: $JENKINS_NAMESPACE"
echo "   - Imagen: $DOCKER_USERNAME/jenkins:$VERSION"
echo "   - Almacenamiento: 10Gi (Persistente)"
echo ""
echo "🔗 Acceso a Jenkins:"
echo "   - URL: $JENKINS_URL"
echo "   - Usuario por defecto: admin"
echo "   - Password: Ver logs del contenedor"
echo ""
echo "💡 Comandos útiles:"
echo "   - Ver logs: kubectl logs -n $JENKINS_NAMESPACE deployment/jenkins"
echo "   - Acceder al pod: kubectl exec -it -n $JENKINS_NAMESPACE deployment/jenkins -- /bin/bash"
echo "   - Port forward: kubectl port-forward -n $JENKINS_NAMESPACE svc/jenkins 8080:8080"
echo "   - Ver password inicial: kubectl logs -n $JENKINS_NAMESPACE deployment/jenkins | grep -A 10 -B 10 'password'"
echo ""
echo "🔒 Obtener password inicial de Jenkins:"
kubectl logs -n $JENKINS_NAMESPACE deployment/jenkins --tail=50 | grep -E "(password|Password)" || echo "   Ejecute: kubectl logs -n $JENKINS_NAMESPACE deployment/jenkins | grep -A 5 -B 5 password"

echo ""
echo "🚀 Jenkins está corriendo en paralelo con los microservicios sin conflictos"
echo "   - Microservicios: namespace 'dev'"
echo "   - Jenkins: namespace '$JENKINS_NAMESPACE'"