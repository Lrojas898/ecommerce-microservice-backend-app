#!/usr/bin/env groovy

import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def instance = Jenkins.getInstance()

println "=== CREANDO PIPELINE JOBS ==="

// ===== PIPELINE PRINCIPAL DE MICROSERVICIOS =====
def mainPipelineScript = '''
pipeline {
    agent any
    
    environment {
        DOCKER_HUB_REPO = 'luisrojasc'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        JAVA_HOME = '/opt/java/openjdk'
        PATH = "${env.PATH}:${env.JAVA_HOME}/bin:/usr/local/bin"
    }
    
    parameters {
        choice(
            name: 'SERVICE',
            choices: [
                'user-service', 
                'order-service', 
                'product-service', 
                'payment-service', 
                'shipping-service', 
                'favourite-service', 
                'api-gateway', 
                'service-discovery', 
                'cloud-config', 
                'proxy-client'
            ],
            description: 'Microservicio a desplegar'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'prod'],
            description: 'Entorno de despliegue'
        )
        choice(
            name: 'ACTION',
            choices: ['build-only', 'deploy-only', 'build-and-deploy'],
            description: 'Acción a ejecutar'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Saltar pruebas unitarias'
        )
        booleanParam(
            name: 'RUN_E2E_TESTS',
            defaultValue: false,
            description: 'Ejecutar pruebas E2E después del despliegue'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Tag de la imagen Docker (opcional)'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    // Checkout del repositorio principal
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Lrojas898/ecommerce-microservice-backend-app.git',
                            credentialsId: 'github-credentials'
                        ]]
                    ])
                }
            }
        }
        
        stage('Build Service') {
            when {
                anyOf {
                    expression { params.ACTION == 'build-only' }
                    expression { params.ACTION == 'build-and-deploy' }
                }
            }
            steps {
                script {
                    dir("${params.SERVICE}") {
                        sh """
                            echo "🏗️ Building ${params.SERVICE}..."
                            chmod +x mvnw
                            ./mvnw clean compile -DskipTests=${params.SKIP_TESTS}
                            
                            if [ "${params.SKIP_TESTS}" = "false" ]; then
                                echo "🧪 Running unit tests..."
                                ./mvnw test
                            fi
                            
                            echo "📦 Packaging application..."
                            ./mvnw package -DskipTests=true
                        """
                    }
                }
            }
            post {
                always {
                    // Publicar resultados de tests si existen
                    script {
                        def testResultsPath = "${params.SERVICE}/target/surefire-reports/*.xml"
                        if (fileExists(testResultsPath)) {
                            junit testResults: testResultsPath, allowEmptyResults: true
                        }
                    }
                }
            }
        }
        
        stage('Docker Build & Push') {
            when {
                anyOf {
                    expression { params.ACTION == 'build-only' }
                    expression { params.ACTION == 'build-and-deploy' }
                }
            }
            steps {
                script {
                    def imageTag = params.IMAGE_TAG == 'latest' ? 
                        "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}" : 
                        params.IMAGE_TAG
                    
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo "🐳 Building Docker image for ${params.SERVICE}..."
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            
                            # Build estrategia según servicio
                            if [ "${params.SERVICE}" == "favourite-service" ]; then
                                docker build -f ${params.SERVICE}/Dockerfile -t ${DOCKER_HUB_REPO}/${params.SERVICE}:${imageTag} .
                            else
                                docker build -t ${DOCKER_HUB_REPO}/${params.SERVICE}:${imageTag} ${params.SERVICE}
                            fi
                            
                            # Tag como latest
                            docker tag ${DOCKER_HUB_REPO}/${params.SERVICE}:${imageTag} ${DOCKER_HUB_REPO}/${params.SERVICE}:latest
                            
                            # Push a Docker Hub
                            echo "📤 Pushing images to Docker Hub..."
                            docker push ${DOCKER_HUB_REPO}/${params.SERVICE}:${imageTag}
                            docker push ${DOCKER_HUB_REPO}/${params.SERVICE}:latest
                            
                            # Limpiar imágenes locales
                            docker rmi ${DOCKER_HUB_REPO}/${params.SERVICE}:${imageTag} || true
                            docker rmi ${DOCKER_HUB_REPO}/${params.SERVICE}:latest || true
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                anyOf {
                    expression { params.ACTION == 'deploy-only' }
                    expression { params.ACTION == 'build-and-deploy' }
                }
            }
            steps {
                script {
                    sh """
                        echo "🚀 Deploying ${params.SERVICE} to ${params.ENVIRONMENT}..."
                        
                        # Verificar que kubectl está configurado
                        kubectl cluster-info
                        
                        # Crear namespace si no existe
                        kubectl create namespace ${params.ENVIRONMENT} --dry-run=client -o yaml | kubectl apply -f -
                        
                        # Verificar si existe el deployment
                        if kubectl get deployment ${params.SERVICE} -n ${params.ENVIRONMENT} >/dev/null 2>&1; then
                            echo "♻️ Updating existing deployment..."
                            kubectl set image deployment/${params.SERVICE} ${params.SERVICE}=${DOCKER_HUB_REPO}/${params.SERVICE}:latest -n ${params.ENVIRONMENT}
                        else
                            echo "🆕 Creating new deployment..."
                            # Aquí podrías aplicar manifiestos K8s si los tienes
                            echo "⚠️ No K8s manifests found. Please deploy manually or add manifest files."
                        fi
                        
                        # Esperar rollout (solo si existe el deployment)
                        if kubectl get deployment ${params.SERVICE} -n ${params.ENVIRONMENT} >/dev/null 2>&1; then
                            kubectl rollout status deployment/${params.SERVICE} -n ${params.ENVIRONMENT} --timeout=300s
                            
                            # Mostrar estado final
                            echo "📊 Final deployment status:"
                            kubectl get pods -n ${params.ENVIRONMENT} -l app=${params.SERVICE}
                        fi
                    """
                }
            }
        }
        
        stage('Health Check') {
            when {
                anyOf {
                    expression { params.ACTION == 'deploy-only' }
                    expression { params.ACTION == 'build-and-deploy' }
                }
            }
            steps {
                script {
                    sh """
                        echo "🏥 Performing health check..."
                        
                        # Esperar un poco para que el servicio se estabilice
                        sleep 15
                        
                        # Verificar pods running
                        kubectl get pods -n ${params.ENVIRONMENT} -l app=${params.SERVICE}
                        
                        # Intentar health check si es posible
                        if kubectl get service ${params.SERVICE} -n ${params.ENVIRONMENT} >/dev/null 2>&1; then
                            echo "✅ Service ${params.SERVICE} is accessible"
                        else
                            echo "⚠️ Service ${params.SERVICE} not found"
                        fi
                    """
                }
            }
        }
        
        stage('Run E2E Tests') {
            when {
                allOf {
                    expression { params.RUN_E2E_TESTS }
                    expression { params.SERVICE == 'api-gateway' }
                    anyOf {
                        expression { params.ACTION == 'deploy-only' }
                        expression { params.ACTION == 'build-and-deploy' }
                    }
                }
            }
            steps {
                dir('tests') {
                    sh '''
                        echo "🧪 Running E2E tests..."
                        
                        # Esperar que todos los servicios estén listos
                        sleep 30
                        
                        # Ejecutar pruebas E2E
                        if [ -f "pom.xml" ]; then
                            mvn clean verify -Pe2e-tests -Dtest.base.url=http://localhost:8080
                        else
                            echo "⚠️ No E2E tests configuration found"
                        fi
                    '''
                }
            }
            post {
                always {
                    script {
                        if (fileExists('tests/target/site/index.html')) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'tests/target/site',
                                reportFiles: 'index.html',
                                reportName: 'E2E Test Report'
                            ])
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Limpiar workspace parcialmente
                sh 'docker system prune -f || true'
            }
        }
        success {
            echo "✅ Pipeline completed successfully for ${params.SERVICE} (${params.ACTION})"
            script {
                // Notificación opcional
                if (env.SLACK_WEBHOOK) {
                    // Enviar notificación a Slack si está configurado
                }
            }
        }
        failure {
            echo "❌ Pipeline failed for ${params.SERVICE}"
            script {
                // Log adicional para debugging
                sh """
                    echo "=== DEBUG INFO ==="
                    kubectl get pods -A || true
                    docker ps -a || true
                    df -h || true
                """
            }
        }
        cleanup {
            cleanWs(patterns: [[pattern: 'target/', type: 'INCLUDE']])
        }
    }
}
'''

// Crear job principal
def mainJobName = "ecommerce-microservice-pipeline"
def mainJob = instance.getItem(mainJobName)

if (mainJob != null) {
    mainJob.delete()
}

def newMainJob = instance.createProject(WorkflowJob, mainJobName)
newMainJob.setDefinition(new CpsFlowDefinition(mainPipelineScript, true))
newMainJob.setDescription("🏗️ Pipeline principal para build y deploy de microservicios de e-commerce")

// Guardar todos los jobs
newMainJob.save()

println "✅ Pipeline job creado exitosamente:"
println "  - ${mainJobName}"

// Crear vista para organizar los jobs
def listView = new hudson.model.ListView("Ecommerce Pipelines")
listView.setIncludeRegex("ecommerce-.*")
instance.addView(listView)

instance.save()

println "✅ Vista 'Ecommerce Pipelines' creada"
println "=== PIPELINE JOBS SETUP COMPLETO ==="