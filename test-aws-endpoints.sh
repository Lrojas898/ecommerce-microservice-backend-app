#!/bin/bash

# Test script for AWS deployed microservices
# Updated to use correct API Gateway URLs and routes

API_GATEWAY_URL="http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com"

echo "🚀 Testing AWS Deployed Microservices"
echo "API Gateway URL: $API_GATEWAY_URL"
echo "=================================="

# Test API Gateway health
echo "1. Testing API Gateway connectivity..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/actuator/health" || echo "❌ API Gateway not responding"

# Test Service Discovery
echo "2. Testing Service Discovery..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/app/api/eureka/apps" || echo "❌ Service Discovery not accessible"

# Test Product Service
echo "3. Testing Product Service..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/app/api/products" || echo "❌ Product Service not accessible"

# Test User Service
echo "4. Testing User Service..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/app/api/users" || echo "❌ User Service not accessible"

# Test Order Service
echo "5. Testing Order Service..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/app/api/orders" || echo "❌ Order Service not accessible"

# Test Payment Service
echo "6. Testing Payment Service..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "$API_GATEWAY_URL/app/api/payments" || echo "❌ Payment Service not accessible"

echo "=================================="
echo "✅ E2E Tests have been updated to use:"
echo "   - Base URL: $API_GATEWAY_URL"
echo "   - Routes: /app/api/* (instead of /service-name/api/*)"
echo ""
echo "📝 Files updated:"
echo "   - tests/src/test/java/com/selimhorri/app/e2e/*.java"
echo "   - tests/e2e/*.java"
echo "   - taller2-tests-package/e2e/*.java"
