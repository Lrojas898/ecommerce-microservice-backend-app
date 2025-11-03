#!/bin/bash
#
# Start socat proxy for Jenkins to access Minikube API Gateway
# 
# ⚠️ NOTE: This script is NO LONGER NEEDED for Jenkins pipelines!
# The Jenkinsfiles now use kubectl port-forward automatically.
#
# This script is kept as an alternative if you need to:
# - Test connectivity manually outside Jenkins
# - Use a persistent port-forward
#
# This script creates a port-forward from Docker gateway (172.17.0.1:18080)
# to Minikube API Gateway (192.168.49.2:32118)
#
# Usage: ./start-jenkins-proxy.sh

set -e

echo "========================================="
echo "  Jenkins to Minikube Proxy Setup"
echo "========================================="
echo ""
echo "⚠️  NOTE: This is now automated in Jenkins!"
echo "The pipeline uses kubectl port-forward automatically."
echo ""
read -p "Continue anyway? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
echo "Minikube IP: $MINIKUBE_IP"

# Get API Gateway NodePort for dev namespace
NODE_PORT=$(kubectl get svc api-gateway -n dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "32118")
echo "API Gateway NodePort: $NODE_PORT"

# Define proxy port
PROXY_PORT=18080
echo "Proxy Port: $PROXY_PORT"

# Check if socat is already running
if ps aux | grep -v grep | grep "socat.*TCP-LISTEN:$PROXY_PORT" > /dev/null; then
    echo ""
    echo "⚠️  socat proxy is already running"
    echo "Current processes:"
    ps aux | grep -v grep | grep "socat.*TCP-LISTEN:$PROXY_PORT"
    echo ""
    read -p "Kill existing process and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Killing existing socat processes..."
        sudo pkill -f "socat.*TCP-LISTEN:$PROXY_PORT" || true
        sleep 1
    else
        echo "Keeping existing process. Exiting."
        exit 0
    fi
fi

# Start socat proxy
echo ""
echo "Starting socat proxy..."
sudo socat TCP-LISTEN:$PROXY_PORT,fork,reuseaddr,bind=0.0.0.0 TCP:$MINIKUBE_IP:$NODE_PORT &
SOCAT_PID=$!

sleep 2

# Verify it's running
if ps -p $SOCAT_PID > /dev/null 2>&1; then
    echo "✓ socat proxy started successfully (PID: $SOCAT_PID)"
else
    echo "❌ Failed to start socat proxy"
    exit 1
fi

# Test connectivity
echo ""
echo "Testing connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:$PROXY_PORT/app/api/products --max-time 5 || echo "000")

if [ "$HTTP_CODE" = "000" ]; then
    echo "❌ Cannot reach API Gateway through proxy"
    echo "HTTP Code: $HTTP_CODE"
    exit 1
else
    echo "✓ Proxy is working! (HTTP $HTTP_CODE)"
fi

echo ""
echo "========================================="
echo "✓ Jenkins Proxy Setup Complete"
echo "========================================="
echo ""
echo "Jenkins can now access Minikube at:"
echo "  http://172.17.0.1:$PROXY_PORT"
echo ""
echo "This maps to:"
echo "  http://$MINIKUBE_IP:$NODE_PORT"
echo ""
echo "To stop the proxy:"
echo "  sudo pkill -f 'socat.*TCP-LISTEN:$PROXY_PORT'"
echo ""
echo "To check if running:"
echo "  ps aux | grep 'socat.*TCP-LISTEN:$PROXY_PORT' | grep -v grep"
echo "========================================="
