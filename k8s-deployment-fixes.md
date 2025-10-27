# Kubernetes Deployment Port Fixes

## Payment Service Port Configuration Fix

### Issue
Payment service was experiencing CrashLoopBackOff due to port mismatch between:
- Liveness probe configured for port 8084
- Service actually running on port 8400 (dev profile)

### Solution Applied
Updated payment-service deployment configuration:

```yaml
# Liveness probe port correction
livenessProbe:
  httpGet:
    port: 8400  # Changed from 8084 to 8400

# Container port specification
ports:
- containerPort: 8400  # Changed from 8084 to 8400
  protocol: TCP

# Service target port update
spec:
  ports:
  - name: http
    port: 8084
    protocol: TCP
    targetPort: 8400  # Changed from 8084 to 8400
```

### Commands Used
```bash
# Update liveness probe port
kubectl patch deployment -n production payment-service -p '{"spec":{"template":{"spec":{"containers":[{"name":"payment-service","livenessProbe":{"httpGet":{"port":8400}}}]}}}}'

# Update container port
kubectl patch deployment -n production payment-service -p '{"spec":{"template":{"spec":{"containers":[{"name":"payment-service","ports":[{"containerPort":8400,"protocol":"TCP"}]}]}}}}'

# Update service target port
kubectl patch service -n production payment-service -p '{"spec":{"ports":[{"name":"http","port":8084,"protocol":"TCP","targetPort":8400}]}}'
```

### Result
- Payment service now running successfully
- All microservices operational in Kubernetes
- Service properly registered with Eureka
- Liveness probes passing

Date: 2025-10-27
Status: RESOLVED
