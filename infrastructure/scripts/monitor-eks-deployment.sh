#!/bin/bash
# Script para monitorear el despliegue de EKS

CLUSTER_NAME="ecommerce-microservices-cluster"
NODEGROUP_NAME="standard-workers"

echo "=========================================="
echo "📊 Monitoreando despliegue de EKS"
echo "=========================================="
echo ""

while true; do
    clear
    echo "🕐 $(date '+%H:%M:%S')"
    echo "=========================================="

    # Estado del cluster
    echo "🏗️  Cluster EKS:"
    CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.status' --output text 2>/dev/null || echo "NO ENCONTRADO")
    echo "   Status: $CLUSTER_STATUS"

    # Estado del node group
    echo ""
    echo "🖥️  Node Group:"
    NODEGROUP_STATUS=$(aws eks describe-nodegroup \
        --cluster-name $CLUSTER_NAME \
        --nodegroup-name $NODEGROUP_NAME \
        --query 'nodegroup.status' \
        --output text 2>/dev/null || echo "NO ENCONTRADO")
    echo "   Status: $NODEGROUP_STATUS"

    if [ "$NODEGROUP_STATUS" != "NO ENCONTRADO" ]; then
        DESIRED=$(aws eks describe-nodegroup \
            --cluster-name $CLUSTER_NAME \
            --nodegroup-name $NODEGROUP_NAME \
            --query 'nodegroup.scalingConfig.desiredSize' \
            --output text)
        echo "   Desired nodes: $DESIRED"

        # Nodos activos
        echo ""
        echo "☸️  Nodos de Kubernetes:"
        kubectl get nodes 2>/dev/null || echo "   kubectl no configurado aún"
    fi

    # Si está activo, salir
    if [ "$NODEGROUP_STATUS" == "ACTIVE" ]; then
        echo ""
        echo "=========================================="
        echo "✅ EKS node group está ACTIVO!"
        echo "=========================================="
        break
    fi

    # Si falló, salir
    if [ "$NODEGROUP_STATUS" == "CREATE_FAILED" ]; then
        echo ""
        echo "=========================================="
        echo "❌ EKS node group FALLÓ al crear"
        echo "=========================================="
        aws eks describe-nodegroup \
            --cluster-name $CLUSTER_NAME \
            --nodegroup-name $NODEGROUP_NAME \
            --query 'nodegroup.health.issues' \
            --output json
        break
    fi

    echo ""
    echo "⏳ Esperando... (Ctrl+C para salir)"
    sleep 30
done

echo ""
echo "🎉 Configurando kubectl..."
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME

echo ""
echo "📋 Nodos disponibles:"
kubectl get nodes

echo ""
echo "✅ Listo para desplegar aplicaciones!"
