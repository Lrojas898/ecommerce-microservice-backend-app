# GitHub Actions Workflows

This directory contains GitHub Actions workflows that automate the CI/CD pipeline for the E-Commerce Microservices application.

## 📋 Available Workflows

### 1. Build and Push Docker Images (`build.yml`)

**Trigger:** Automatic on push to `master`, `main`, or `develop` branches; Manual via workflow dispatch

**Purpose:** Builds and pushes Docker images for all microservices to Docker Hub

**Features:**
- Detects changed services automatically
- Builds all services with Maven in parallel
- Runs unit tests for changed services
- SonarQube code quality analysis
- Builds and pushes Docker images with multiple tags (version, timestamp, latest)
- Caches Maven and Docker layers for faster builds

**Outputs:**
- Docker images: `<username>/<service>:latest`, `<username>/<service>:v<version>`, `<username>/<service>:v<version>-<timestamp>`
- Test results published as GitHub checks
- SonarQube analysis reports

### 2. Deploy to Development (`deploy-dev.yml`)

**Trigger:** Manual via workflow dispatch

**Purpose:** Deploys services to the `dev` Kubernetes namespace

**Features:**
- Detects services to deploy based on version map
- Deploys in correct order (infrastructure → microservices → api-gateway)
- Runs E2E tests after deployment (optional)
- SonarQube analysis on E2E test code
- Verifies deployment health

**Parameters:**
- `service_versions`: JSON map of service versions to deploy
- `docker_user`: Docker Hub username (default: luisrojasc)
- `skip_e2e_tests`: Skip E2E tests (default: false)
- `force_deploy_all`: Deploy all services (default: false)

### 3. Deploy to Production (`deploy-prod.yml`)

**Trigger:** Manual via workflow dispatch

**Purpose:** Deploys services to the `prod` Kubernetes namespace with manual approval

**Features:**
- **Manual approval required** before deployment (using GitHub Environments)
- Same deployment strategy as dev
- Stricter health checks
- E2E tests in production
- SonarQube analysis on E2E test code

**Parameters:** Same as deploy-dev

**Important:** Configure the `production` environment in GitHub repository settings to require approvals.

### 4. Performance Tests (`performance-tests.yml`)

**Trigger:** Manual via workflow dispatch; Scheduled weekly on Sunday at 2 AM UTC

**Purpose:** Runs Locust performance tests against the deployed application

**Features:**
- Multiple test types (Mixed Workload, Product Service Load, Order Stress, etc.)
- Configurable user count, spawn rate, and duration
- Generates HTML and CSV reports
- Analyzes error rates (fails if > 5%)
- SonarQube analysis on performance test code

**Parameters:**
- `environment`: Target environment (dev or prod)
- `test_type`: Type of performance test
- `users`: Number of concurrent users (default: 100)
- `spawn_rate`: Users per second (default: 10)
- `run_time`: Test duration (default: 5m)
- `headless`: Run without UI (default: true)

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

### Docker Hub Credentials

| Secret Name | Description | Example |
|------------|-------------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `luisrojasc` |
| `DOCKER_PASSWORD` | Docker Hub password or access token | `dckr_pat_xxxxx` |

**How to get:**
1. Go to [Docker Hub](https://hub.docker.com)
2. Click on your username → Account Settings → Security
3. Click "New Access Token"
4. Copy the token and add it as `DOCKER_PASSWORD`

### Kubernetes Configuration

| Secret Name | Description | Example |
|------------|-------------|---------|
| `KUBECONFIG` | Complete kubeconfig file content | See below |

**How to get:**
```bash
# For Digital Ocean Kubernetes
doctl kubernetes cluster kubeconfig save <cluster-name>
cat ~/.kube/config

# For Minikube
kubectl config view --flatten --minify

# For AWS EKS
aws eks update-kubeconfig --name <cluster-name> --region <region>
cat ~/.kube/config
```

Copy the entire content of the kubeconfig file and paste it as the secret value.

### SonarQube Configuration

| Secret Name | Description | Example |
|------------|-------------|---------|
| `SONAR_TOKEN` | SonarQube authentication token | `squ_xxxxxxxxxx` |
| `SONAR_HOST_URL` | SonarQube server URL | `http://172.17.0.1:9000` or `https://sonarqube.example.com` |

**How to get:**
1. Log in to your SonarQube instance
2. Click on your avatar → My Account → Security
3. Generate a new token with name "GitHub Actions"
4. Copy the token and add it as `SONAR_TOKEN`
5. Copy your SonarQube URL and add it as `SONAR_HOST_URL`

## 🌍 GitHub Environments

For production deployments, configure a GitHub Environment to require manual approval:

1. Go to `Settings` → `Environments`
2. Click "New environment"
3. Name it `production`
4. Check "Required reviewers" and add yourself or team members
5. Set deployment branches to `main` or `master` only
6. Click "Save protection rules"

Now all production deployments will require manual approval before proceeding.

## 📊 Workflow Execution Order

Typical CI/CD flow:

```
1. Developer pushes code to branch
   ↓
2. build.yml automatically triggers
   - Builds changed services
   - Runs unit tests
   - Pushes Docker images
   - SonarQube analysis
   ↓
3. Manual: Trigger deploy-dev.yml
   - Deploys to dev namespace
   - Runs E2E tests
   - Verifies deployment
   ↓
4. Manual: Trigger performance-tests.yml (optional)
   - Tests performance in dev
   - Generates reports
   ↓
5. Manual: Trigger deploy-prod.yml
   - Requires approval
   - Deploys to prod namespace
   - Runs E2E tests in prod
   - Verifies production health
   ↓
6. Manual: Trigger performance-tests.yml on prod (optional)
   - Tests production performance
   - Monitors error rates
```

## 🚀 How to Use

### Building and Pushing Images

**Automatic (on push):**
```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

**Manual:**
1. Go to Actions tab
2. Select "Build and Push Docker Images"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

### Deploying to Dev

1. Go to Actions tab
2. Select "Deploy to Development"
3. Click "Run workflow"
4. Configure parameters:
   - Leave `service_versions` as `{}` to deploy all services with latest images
   - Or provide specific versions: `{"user-service":"v0.1.0-20240101-120000","product-service":"v0.1.0-20240101-120000"}`
5. Click "Run workflow"

### Deploying to Production

1. Go to Actions tab
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Configure parameters (same as dev)
5. Click "Run workflow"
6. **Wait for approval notification**
7. Review deployment plan and approve/reject

### Running Performance Tests

1. Go to Actions tab
2. Select "Performance Tests"
3. Click "Run workflow"
4. Configure parameters:
   - Environment: `prod` or `dev`
   - Test type: Choose from dropdown
   - Users: e.g., `100`
   - Spawn rate: e.g., `10`
   - Run time: e.g., `5m`
5. Click "Run workflow"
6. Download HTML report from artifacts

## 📈 Monitoring and Troubleshooting

### Viewing Workflow Runs

1. Go to Actions tab
2. Click on a workflow run to see details
3. Click on a job to see logs
4. Download artifacts (test reports, performance reports)

### Common Issues

#### Build fails with "Docker login failed"

**Solution:** Check that `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets are correctly configured.

#### Deploy fails with "Unable to connect to the server"

**Solution:** Check that `KUBECONFIG` secret is correctly formatted and contains valid credentials.

#### SonarQube analysis fails

**Solution:** Check that `SONAR_TOKEN` and `SONAR_HOST_URL` are correctly configured and SonarQube is accessible.

#### E2E tests timeout

**Solution:** Increase the timeout values or check that services are healthy in Kubernetes.

#### Performance tests show high error rates

**Solution:** Check service logs, increase resources, or reduce concurrent users.

## 🔄 Comparison with Jenkins Pipelines

| Feature | Jenkins | GitHub Actions |
|---------|---------|----------------|
| **Cost** | Self-hosted (~$25/month) | Included with GitHub (2000 min/month free) |
| **Maintenance** | Requires server management | Fully managed by GitHub |
| **Configuration** | Jenkinsfile (Groovy) | YAML workflows |
| **Secrets** | Jenkins credentials | GitHub Secrets |
| **Manual approval** | Input step | GitHub Environments |
| **Parallel jobs** | `parallel` block | `strategy.matrix` |
| **Triggers** | Webhooks, cron | `on:` events, schedule |
| **Artifacts** | Jenkins plugins | `actions/upload-artifact` |
| **Test results** | JUnit plugin | Third-party actions |

## 📝 Customization

### Adding a New Service

1. Update `SERVICES` environment variable in `build.yml`:
   ```yaml
   SERVICES: service-discovery,...,your-new-service
   ```

2. Update `ALL_SERVICES` in deployment workflows:
   ```yaml
   ALL_SERVICES: service-discovery,...,your-new-service
   ```

3. Add service port mapping in `build.yml` if needed:
   ```yaml
   your-new-service) PORT=8090 ;;
   ```

### Changing SonarQube Projects

Edit the SonarQube analysis steps in each workflow:
```yaml
-Dsonar.projectKey=your-project-key \
-Dsonar.projectName="Your Project Name" \
```

### Adjusting Timeouts

Edit the timeout values in deployment workflows:
```yaml
env:
  SERVICE_READINESS_TIMEOUT: 600  # 10 minutes
  POD_READY_TIMEOUT: 300          # 5 minutes
```

## 🎯 Best Practices

1. **Use semantic versioning** for Docker image tags
2. **Always test in dev** before deploying to prod
3. **Review SonarQube reports** for code quality issues
4. **Monitor performance tests** regularly
5. **Set up GitHub Environments** for production approval
6. **Use branch protection rules** to require CI checks
7. **Keep secrets up to date** (rotate Docker tokens, kubeconfig)
8. **Archive performance reports** for historical comparison

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Hub](https://hub.docker.com)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Locust Documentation](https://docs.locust.io/)

## 🤝 Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review this README
3. Check SonarQube dashboard for code quality issues
4. Review Kubernetes pod logs: `kubectl logs -f <pod-name> -n <namespace>`
