#!/usr/bin/env groovy

import jenkins.model.*
import hudson.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule
import hudson.security.csrf.DefaultCrumbIssuer
import hudson.markup.RawHtmlMarkupFormatter
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*

def instance = Jenkins.getInstance()

println "=== CONFIGURANDO JENKINS INICIAL ==="

// Deshabilitar setup inicial
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Configurar estrategia de autorización
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Habilitar CSRF Protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Configurar markup formatter (permitir HTML básico)
instance.setMarkupFormatter(new RawHtmlMarkupFormatter(false))

// Configurar agentes
instance.setSlaveAgentPort(50000)
instance.getDescriptor("jenkins.security.s2m.AdminWhitelistRule").setMasterKillSwitch(false)

// Configurar número de ejecutores
instance.setNumExecutors(4)

println "✅ Configuración básica de seguridad completada"

// Crear credenciales por defecto
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Docker Hub credentials
def dockerHubCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "dockerhub-credentials",
    "Docker Hub Registry Credentials",
    "luisrojasc",
    "dckr_pat_your_token_here"  // Reemplazar con token real
)

// AWS credentials
def awsCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "aws-credentials",
    "AWS Credentials for EKS",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY"  // Reemplazar con credenciales reales
)

// GitHub credentials
def githubCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-credentials",
    "GitHub Repository Access",
    "Lrojas898",
    "github_pat_your_token_here"  // Reemplazar con token de GitHub
)

// SSH Key para Kubernetes
def sshKeyCredentials = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    "kubernetes-ssh-key",
    "jenkins",
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource("""-----BEGIN OPENSSH PRIVATE KEY-----
# Reemplazar con clave SSH real para acceso a Kubernetes
-----END OPENSSH PRIVATE KEY-----"""),
    "",
    "SSH Key for Kubernetes access"
)

// Agregar credenciales
store.addCredentials(domain, dockerHubCredentials)
store.addCredentials(domain, awsCredentials)
store.addCredentials(domain, githubCredentials)
store.addCredentials(domain, sshKeyCredentials)

println "✅ Credenciales por defecto creadas"

// Configurar variables de entorno globales
def globalProps = instance.getGlobalNodeProperties()
def envVarsNodePropertyList = globalProps.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)

def newEnvVarsNodeProperty = null
def envVars = null

if (envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0) {
    newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty()
    globalProps.add(newEnvVarsNodeProperty)
    envVars = newEnvVarsNodeProperty.getEnvVars()
} else {
    envVars = envVarsNodePropertyList.get(0).getEnvVars()
}

// Variables de entorno por defecto
envVars.put("DOCKER_HUB_REPO", "luisrojasc")
envVars.put("KUBECONFIG", "/var/jenkins_home/.kube/config")
envVars.put("JAVA_HOME", "/opt/java/openjdk")
envVars.put("MAVEN_HOME", "/usr/share/maven")
envVars.put("PATH+MAVEN", "/usr/share/maven/bin")
envVars.put("PATH+KUBECTL", "/usr/local/bin")
envVars.put("PATH+DOCKER", "/usr/bin")

println "✅ Variables de entorno globales configuradas"

// Configurar herramientas JDK
def jdkInstallations = instance.getDescriptorByType(hudson.model.JDK.DescriptorImpl.class)
jdkInstallations.setInstallations(
    new hudson.model.JDK("JDK-17", "/opt/java/openjdk")
)

// Configurar Maven
def mavenInstallations = instance.getDescriptorByType(hudson.tasks.Maven.DescriptorImpl.class)
mavenInstallations.setInstallations(
    new hudson.tasks.Maven.MavenInstallation("Maven-3.9", "/usr/share/maven")
)

println "✅ Herramientas configuradas (JDK, Maven)"

// Configurar webhook GitHub (opcional)
def githubPluginConfig = instance.getDescriptorByType(org.jenkinsci.plugins.github.config.GitHubPluginConfig.class)
if (githubPluginConfig != null) {
    // Configurar hook URL
    githubPluginConfig.setHookUrl("http://localhost:8080/github-webhook/")
}

// Guardar configuración
instance.save()

println "=== ✅ JENKINS CONFIGURADO EXITOSAMENTE ==="
println "Usuario: admin"
println "Contraseña: admin123"
println "Acceso: http://localhost:8080"
println ""
println "Credenciales configuradas:"
println "- dockerhub-credentials (Docker Hub)"
println "- aws-credentials (AWS)"
println "- github-credentials (GitHub)"
println "- kubernetes-ssh-key (SSH para K8s)"
println ""
println "¡Recuerda actualizar las credenciales con valores reales!"