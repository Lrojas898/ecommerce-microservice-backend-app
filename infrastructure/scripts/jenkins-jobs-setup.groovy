/*
 * Jenkins Jobs Auto-Configuration Script
 *
 * Go to: Manage Jenkins > Script Console
 * Paste this script and click "Run"
 *
 * This creates all pipeline jobs for the ecommerce project
 */

import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec

def jenkins = Jenkins.getInstance()

// Configuration
def gitUrl = "https://github.com/Lrojas898/ecommerce-microservice-backend-app.git"
def credentialsId = ""  // Leave empty if public repo, otherwise add credential ID

// Define pipeline jobs
def jobs = [
    [
        name: "Ecommerce-DEV-Pipeline",
        description: "Development pipeline - builds and tests on develop branch",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.dev",
        branch: "develop"
    ],
    [
        name: "Ecommerce-STAGE-Pipeline",
        description: "Staging pipeline - integration tests on release branches",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.stage",
        branch: "release/*"
    ],
    [
        name: "Ecommerce-PROD-Pipeline",
        description: "Production pipeline - deploys to production from master",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.prod",
        branch: "master"
    ],
    [
        name: "Ecommerce-Build-Pipeline",
        description: "Build all services and push to ECR",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.build",
        branch: "*/master"
    ],
    [
        name: "Ecommerce-Deploy-DEV",
        description: "Deploy services to DEV environment",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.deploy-dev",
        branch: "develop"
    ],
    [
        name: "Ecommerce-Deploy-PROD",
        description: "Deploy services to PROD environment",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.deploy-prod",
        branch: "master"
    ],
    [
        name: "Ecommerce-Infrastructure",
        description: "Terraform infrastructure management",
        scriptPath: "infrastructure/jenkins/Jenkinsfile.infrastructure",
        branch: "*/master"
    ]
]

// Create jobs
jobs.each { jobConfig ->
    def jobName = jobConfig.name

    println "Creating job: ${jobName}"

    // Delete if exists
    def existingJob = jenkins.getItem(jobName)
    if (existingJob) {
        println "  Deleting existing job: ${jobName}"
        existingJob.delete()
    }

    // Create new job
    def job = jenkins.createProject(WorkflowJob.class, jobName)
    job.setDescription(jobConfig.description)

    // Configure Git SCM
    def scm = new GitSCM(gitUrl)
    scm.branches = [new BranchSpec(jobConfig.branch)]

    // Configure pipeline from SCM
    def flowDefinition = new CpsScmFlowDefinition(scm, jobConfig.scriptPath)
    flowDefinition.setLightweight(true)
    job.setDefinition(flowDefinition)

    // Save job
    job.save()

    println "  ✓ Created: ${jobName}"
}

println ""
println "=========================================="
println "Job creation complete!"
println "=========================================="
println ""
println "Created ${jobs.size()} pipeline jobs:"
jobs.each { job ->
    println "  - ${job.name}"
}
println ""
println "NEXT STEPS:"
println "1. Configure GitHub webhook (if using private repo)"
println "2. Add AWS credentials in Jenkins (Manage Jenkins > Credentials)"
println "3. Trigger first build manually to test"
println ""
println "=========================================="

return "Success! ${jobs.size()} jobs created."
