# Jenkins Agent Setup Guide

## Overview

This guide explains how to configure a Jenkins agent node to distribute build workload.

## Infrastructure Created

Terraform creates:
- **1 EC2 instance** (t3.small) - Jenkins Agent
- **1 Elastic IP** - Fixed IP for the agent
- **Security Group** - Shared with Jenkins master

## Agent Configuration

### Software Installed (via user-data.sh):
- Java 11 (Amazon Corretto)
- Docker
- AWS CLI v2
- kubectl
- Maven 3.9.5
- jenkins user (member of docker group)

### Instance Details:
- **Type:** t3.small
- **OS:** Amazon Linux 2023
- **Storage:** 20GB gp3
- **User:** jenkins

---

## Step 1: Deploy with Terraform

```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

**Outputs:**
```
jenkins_agent_public_ip = "X.X.X.X"
jenkins_agent_ssh_command = "ssh ec2-user@X.X.X.X"
```

---

## Step 2: Configure Agent in Jenkins

### Option A: Manual Configuration (Web UI)

1. Go to Jenkins: **Manage Jenkins** → **Nodes**
2. Click **"New Node"**
3. Configure:
   - **Node name:** `jenkins-agent-1`
   - **Type:** Permanent Agent
   - Click **Create**

4. **Node Configuration:**
   ```
   Name: jenkins-agent-1
   Description: AWS EC2 Jenkins Agent
   # of executors: 2
   Remote root directory: /home/jenkins
   Labels: docker maven aws
   Usage: Use this node as much as possible
   Launch method: Launch agents via SSH
   ```

5. **Launch Method Details:**
   ```
   Host: <jenkins_agent_public_ip>
   Credentials: Add → SSH Username with private key
     - ID: jenkins-agent-key
     - Username: ec2-user
     - Private Key: <your-aws-key.pem content>
   Host Key Verification Strategy: Non verifying Verification Strategy
   ```

6. Click **Save**
7. Agent should connect automatically

---

### Option B: Using Jenkins Configuration as Code (JCasC)

Create file: `/var/jenkins_home/jenkins.yaml`

```yaml
jenkins:
  numExecutors: 2  # Built-in node executors
  nodes:
    - permanent:
        name: "jenkins-agent-1"
        numExecutors: 2
        remoteFS: "/home/jenkins"
        labelString: "docker maven aws"
        launcher:
          ssh:
            host: "<jenkins_agent_public_ip>"
            port: 22
            credentialsId: "jenkins-agent-key"
            launchTimeoutSeconds: 60
            maxNumRetries: 3
            retryWaitTime: 15
            sshHostKeyVerificationStrategy:
              nonVerifyingKeyVerificationStrategy: {}
```

Reload configuration:
```bash
curl -X POST http://localhost:8080/reload-configuration-as-code
```

---

## Step 3: Verify Connection

1. Go to **Manage Jenkins** → **Nodes**
2. Click on **jenkins-agent-1**
3. Check **Status:** Should show green with "Agent is connected"
4. Check **Log:** Should show successful connection messages

---

## Step 4: Test the Agent

Create a test pipeline:

```groovy
pipeline {
    agent {
        label 'docker'  // Runs on agent with 'docker' label
    }
    stages {
        stage('Test Agent') {
            steps {
                sh 'hostname'
                sh 'docker --version'
                sh 'mvn --version'
                sh 'kubectl version --client'
            }
        }
    }
}
```

---

## Executor Distribution

After setup, you'll have:

**Built-In Node (Jenkins Master):**
- Executors: 2
- Runs: Lightweight tasks, pipeline orchestration

**jenkins-agent-1 (Agent Node):**
- Executors: 2
- Runs: Heavy builds, Docker operations, tests

**Total Concurrent Builds:** 4

---

## Pipeline Configuration

### To use specific node:

```groovy
pipeline {
    agent {
        label 'docker'  // Runs on agent
    }
    // ...
}
```

### To use built-in node:

```groovy
pipeline {
    agent {
        label 'master'  // Runs on Jenkins master
    }
    // ...
}
```

### To use any available:

```groovy
pipeline {
    agent any  // Jenkins decides
    // ...
}
```

---

## Cost Estimation

**Jenkins Agent (t3.small):**
- Instance: ~$15/month (730 hours × $0.0208/hour)
- EIP: ~$3.60/month (if unused)
- Storage (20GB): ~$2/month

**Total Additional Cost:** ~$20/month

---

## Troubleshooting

### Agent won't connect:

1. **Check Security Group:**
   ```bash
   # Should allow SSH (22) from Jenkins master IP
   ```

2. **Verify SSH access:**
   ```bash
   ssh -i your-key.pem ec2-user@<agent-ip>
   ```

3. **Check Java:**
   ```bash
   ssh ec2-user@<agent-ip> 'java -version'
   ```

4. **Check Jenkins logs:**
   - Go to agent page in Jenkins
   - Click "Log"
   - Look for connection errors

### Docker permission denied:

```bash
# SSH to agent
ssh ec2-user@<agent-ip>

# Add jenkins user to docker group (should be done by user-data)
sudo usermod -aG docker jenkins

# Restart Docker
sudo systemctl restart docker
```

---

## Scaling

To add more agents:

1. Update `agent.tf`:
   ```hcl
   count = 2  # Add to aws_instance.jenkins_agent
   ```

2. Apply:
   ```bash
   terraform apply
   ```

3. Configure each agent in Jenkins (repeat Step 2)

---

## Cleanup

To remove the agent:

```bash
# 1. In Jenkins UI, delete the node
# 2. In Terraform
cd infrastructure/terraform
terraform destroy -target=module.jenkins.aws_instance.jenkins_agent
```

---

## Benefits

✅ **Parallel Builds:** 4 concurrent builds (2 master + 2 agent)
✅ **Isolation:** Heavy builds don't affect Jenkins master
✅ **Scalability:** Easy to add more agents
✅ **Cost Efficient:** Only ~$20/month for double capacity
✅ **Docker Ready:** Agent has Docker pre-installed

---

## Next Steps

1. Deploy agent with Terraform
2. Configure in Jenkins UI
3. Update pipelines to use labels
4. Monitor build distribution
5. Scale up if needed

---

**Created:** 2025-10-24
**Last Updated:** 2025-10-24
