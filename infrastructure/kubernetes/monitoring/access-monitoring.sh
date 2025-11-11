#!/bin/bash

# ============================================================
# Quick Access Script for Prometheus and Grafana
# ============================================================
# Use this script to easily access monitoring UIs from Windows
# ============================================================

echo "========================================="
echo "  E-Commerce Monitoring - Quick Access  "
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo "❌ Monitoring namespace not found. Please deploy monitoring stack first."
    echo "   Run: ./deploy-monitoring.sh"
    exit 1
fi

echo "Select access method:"
echo ""
echo "1) Port-Forward (Recommended for WSL2 → Windows access)"
echo "2) Show Minikube URLs (for direct access from WSL2)"
echo "3) Status Check"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting port-forwards..."
        echo ""
        echo "📊 Prometheus will be available at: http://localhost:9090"
        echo "📈 Grafana will be available at:    http://localhost:3000"
        echo ""
        echo "   Grafana credentials:"
        echo "   Username: admin"
        echo "   Password: admin123"
        echo ""
        echo "⚠️  Keep this terminal open. Press Ctrl+C to stop."
        echo ""
        echo "========================================="
        echo ""

        # Run both port-forwards in background
        kubectl port-forward -n monitoring svc/prometheus 9090:9090 &
        PROM_PID=$!

        kubectl port-forward -n monitoring svc/grafana 3000:3000 &
        GRAF_PID=$!

        # Function to cleanup on exit
        cleanup() {
            echo ""
            echo "🛑 Stopping port-forwards..."
            kill $PROM_PID 2>/dev/null
            kill $GRAF_PID 2>/dev/null
            echo "✅ Done"
            exit 0
        }

        trap cleanup SIGINT SIGTERM

        # Wait for both processes
        wait
        ;;

    2)
        echo ""
        MINIKUBE_IP=$(minikube ip 2>/dev/null)

        if [ -z "$MINIKUBE_IP" ]; then
            echo "❌ Cannot get Minikube IP. Is Minikube running?"
            echo "   Run: minikube status"
            exit 1
        fi

        echo "📊 Prometheus: http://${MINIKUBE_IP}:30090"
        echo "📈 Grafana:    http://${MINIKUBE_IP}:30030"
        echo ""
        echo "   Grafana credentials:"
        echo "   Username: admin"
        echo "   Password: admin123"
        echo ""
        echo "⚠️  Note: These URLs only work from within WSL2"
        echo "   For Windows access, use option 1 (Port-Forward)"
        echo ""
        ;;

    3)
        echo ""
        echo "🔍 Checking monitoring stack status..."
        echo ""

        echo "Pods:"
        kubectl get pods -n monitoring
        echo ""

        echo "Services:"
        kubectl get svc -n monitoring
        echo ""

        echo "PVCs:"
        kubectl get pvc -n monitoring
        echo ""

        # Check if pods are ready
        PROM_READY=$(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
        GRAF_READY=$(kubectl get pod -n monitoring -l app=grafana -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)

        if [ "$PROM_READY" = "true" ]; then
            echo "✅ Prometheus is ready"
        else
            echo "❌ Prometheus is NOT ready"
        fi

        if [ "$GRAF_READY" = "true" ]; then
            echo "✅ Grafana is ready"
        else
            echo "❌ Grafana is NOT ready"
        fi
        echo ""
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
