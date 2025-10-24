#!/bin/bash
# Script para probar los microservicios en DEV

API_GATEWAY="http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com"

echo "=========================================="
echo "Testing E-commerce Microservices - DEV"
echo "=========================================="
echo ""

echo "1. Testing API Gateway Health..."
curl -s "$API_GATEWAY/actuator/health" | grep -o '"status":"[^"]*"' | head -1
echo ""
echo ""

echo "2. Testing User Service..."
echo "GET /api/users"
curl -s -X GET "$API_GATEWAY/api/users" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "3. Testing Product Service..."
echo "GET /api/products"
curl -s -X GET "$API_GATEWAY/api/products" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "4. Testing Order Service..."
echo "GET /api/orders"
curl -s -X GET "$API_GATEWAY/api/orders" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "5. Testing Payment Service..."
echo "GET /api/payments"
curl -s -X GET "$API_GATEWAY/api/payments" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "6. Testing Shipping Service..."
echo "GET /api/shipping"
curl -s -X GET "$API_GATEWAY/api/shipping" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "7. Testing Favourite Service..."
echo "GET /api/favourites"
curl -s -X GET "$API_GATEWAY/api/favourites" -H "Content-Type: application/json" || echo "Endpoint may not exist yet"
echo ""
echo ""

echo "=========================================="
echo "Testing Complete!"
echo "=========================================="
echo ""
echo "API Gateway URL: $API_GATEWAY"
echo ""
echo "To access Eureka Dashboard:"
echo "  kubectl port-forward -n dev svc/service-discovery 8761:8761"
echo "  Then open: http://localhost:8761"
echo ""
