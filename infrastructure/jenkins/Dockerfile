# Jenkins Docker Image - Ecommerce Microservices
# Imagen completamente configurada con plugins, jobs y credenciales
# Usando la última versión LTS de Jenkins

FROM jenkins/jenkins:2.528.1-lts

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar Docker CLI, kubectl, AWS CLI y otras herramientas
RUN apt-get update && \
    apt-get install -y \
    docker.io \
    curl \
    wget \
    git \
    maven \
    python3 \
    python3-pip \
    unzip \
    jq \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Instalar Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Cambiar de vuelta a usuario jenkins
USER jenkins

# Copiar lista de plugins a instalar
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copiar configuración de Jenkins (opcional - solo si existe)
# COPY jenkins-config/ /usr/share/jenkins/ref/

# Copiar jobs preconfigurados (opcional - solo si existe)
# COPY jobs/ /usr/share/jenkins/ref/jobs/

# Copiar scripts de inicialización
COPY init-scripts/ /usr/share/jenkins/ref/init.groovy.d/

# Variables de entorno optimizadas
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djava.awt.headless=true -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true"
ENV JENKINS_OPTS="--httpPort=8080"
ENV JENKINS_UC_EXPERIMENTAL="https://updates.jenkins.io/experimental"

# Exponer puerto
EXPOSE 8080

# Salud del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/login || exit 1