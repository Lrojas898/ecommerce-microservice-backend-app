# SonarQube Integration

## Overview

SonarQube has been integrated into the CI/CD pipelines to analyze code quality for both E2E tests and Performance tests.

## Access

- **URL**: http://localhost:9000
- **Username**: admin
- **Password**: DevOpsSonnar123!

## Projects Configured

### 1. E-Commerce E2E Tests
- **Project Key**: `ecommerce-e2e-tests`
- **Language**: Java 17
- **Coverage**: JaCoCo
- **Dashboard**: http://localhost:9000/dashboard?id=ecommerce-e2e-tests

**Analyzed in pipelines**:
- `Jenkinsfile.deploy-dev.local` (after E2E tests stage)
- `Jenkinsfile.deploy-prod.local` (after E2E tests stage)

### 2. E-Commerce Performance Tests
- **Project Key**: `ecommerce-performance-tests`
- **Language**: Python 3.13
- **Dashboard**: http://localhost:9000/dashboard?id=ecommerce-performance-tests

**Analyzed in pipeline**:
- `Jenkinsfile.performance-tests` (after test execution)

## Pipeline Integration

### E2E Tests (Java/Maven)

The E2E tests use Maven SonarQube plugin. Analysis runs automatically after tests complete:

```groovy
stage('SonarQube Analysis - E2E Tests') {
    // Runs Maven sonar:sonar goal
    // Uploads test results and JaCoCo coverage
}
```

**What gets analyzed**:
- Test code structure
- Code complexity
- Test coverage from JaCoCo reports
- JUnit test execution results
- Code smells and vulnerabilities

### Performance Tests (Python/Locust)

The performance tests use SonarQube Scanner CLI, which is downloaded automatically:

```groovy
stage('SonarQube Analysis - Performance Tests') {
    // Downloads sonar-scanner if not present
    // Analyzes Python test code
}
```

**What gets analyzed**:
- Python code quality
- Code complexity
- Code smells
- Security vulnerabilities
- Code duplications

## Configuration Files

### E2E Tests
- **POM Configuration**: `/tests/pom.xml`
  - JaCoCo plugin for coverage
  - SonarQube Maven plugin

- **SonarQube Properties**: `/tests/sonar-project.properties`
  ```properties
  sonar.projectKey=ecommerce-e2e-tests
  sonar.sources=src/main/java
  sonar.tests=src/test/java
  sonar.java.binaries=target/classes,target/test-classes
  ```

### Performance Tests
- **SonarQube Properties**: `/tests/performance/sonar-project.properties`
  ```properties
  sonar.projectKey=ecommerce-performance-tests
  sonar.language=py
  sonar.sources=.
  sonar.inclusions=**/*.py
  ```

## How It Works

### Deployment Pipelines (Dev/Prod)

1. Pipeline deploys services to environment
2. E2E tests run against deployed services
3. **SonarQube Analysis stage executes** (non-blocking)
4. Results uploaded to SonarQube
5. Pipeline continues to summary

### Performance Pipeline

1. Pipeline runs Locust performance tests
2. Test results analyzed and published
3. **SonarQube Analysis stage executes** (non-blocking)
4. Python test code analyzed
5. Results uploaded to SonarQube
6. Pipeline continues to summary

## Failure Handling

All SonarQube stages are **non-blocking**:
- If analysis fails, pipeline continues
- Warning is logged in console
- Pipeline status is not affected

This ensures that SonarQube issues don't block deployments or test executions.

## Quality Gates

Quality gates can be configured in SonarQube to enforce quality standards:

1. Navigate to project in SonarQube
2. Go to Project Settings > Quality Gates
3. Set conditions (e.g., coverage %, duplications, vulnerabilities)

## Viewing Results

### From Jenkins Console
After pipeline runs, check the console output for:
```
✓ SonarQube analysis completed
View results at: http://172.17.0.1:9000/dashboard?id=<project-key>
```

### From SonarQube Dashboard
1. Open http://localhost:9000
2. Login with admin credentials
3. View project dashboards
4. Check:
   - Code coverage
   - Code smells
   - Bugs
   - Vulnerabilities
   - Duplications
   - Complexity

## Troubleshooting

### SonarQube Not Accessible
```bash
# Check if containers are running
docker ps | grep sonarqube

# Check SonarQube logs
docker logs sonarqube

# Restart if needed
cd infrastructure/sonarqube
docker-compose restart
```

### Analysis Fails in Pipeline
```bash
# From Jenkins container
docker exec jenkins curl -s http://172.17.0.1:9000/api/system/status

# Should return: {"status":"UP"}
```

### Maven Plugin Issues (E2E Tests)
```bash
# Test manually from tests directory
cd tests
mvn sonar:sonar \
  -Dsonar.host.url=http://172.17.0.1:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=DevOpsSonnar123!
```

### Scanner Issues (Performance Tests)
```bash
# Test manually from performance directory
cd tests/performance
./sonar-scanner/bin/sonar-scanner \
  -Dsonar.host.url=http://172.17.0.1:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=DevOpsSonnar123!
```

## Network Configuration

SonarQube is accessible from Jenkins via Docker Gateway:
- **Jenkins → SonarQube**: `http://172.17.0.1:9000`
- **Host → SonarQube**: `http://localhost:9000`

Both containers are on the default Docker bridge network.

## Best Practices

1. **Review Results Regularly**: Check SonarQube after each pipeline run
2. **Fix Critical Issues**: Address security vulnerabilities and bugs
3. **Monitor Coverage**: Track test coverage trends
4. **Set Quality Gates**: Configure quality gates for critical metrics
5. **Team Awareness**: Share SonarQube dashboard with team

## Future Enhancements

Potential improvements:
- Add code coverage for performance tests
- Configure custom quality profiles
- Set up quality gate enforcement
- Add PR decoration (if using GitHub/GitLab)
- Configure email notifications
- Add security hotspot reviews
