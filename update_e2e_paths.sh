#!/bin/bash

# Update E2E test paths to use correct service context paths

TEST_DIR="/mnt/c/Users/luism/OneDrive/Documents/ICESI/IngeSoftV/ecommerce-microservice-backend-app/tests/src/test/java/com/selimhorri/app/e2e"

# Update user service paths
sed -i 's|/app/api/users|/user-service/api/users|g' "$TEST_DIR"/*.java
sed -i 's|/app/api/auth|/user-service/api/auth|g' "$TEST_DIR"/*.java

# Update product service paths
sed -i 's|/app/api/products|/product-service/api/products|g' "$TEST_DIR"/*.java
sed -i 's|/app/api/categories|/product-service/api/categories|g' "$TEST_DIR"/*.java

# Update order service paths
sed -i 's|/app/api/orders|/order-service/api/orders|g' "$TEST_DIR"/*.java
sed -i 's|/app/api/carts|/order-service/api/carts|g' "$TEST_DIR"/*.java

# Update payment service paths
sed -i 's|/app/api/payments|/payment-service/api/payments|g' "$TEST_DIR"/*.java

# Update shipping service paths
sed -i 's|/app/api/shipping|/shipping-service/api/shipping|g' "$TEST_DIR"/*.java

# Update favourite service paths
sed -i 's|/app/api/favourites|/favourite-service/api/favourites|g' "$TEST_DIR"/*.java

echo "Updated all E2E test paths to use correct service context paths"
