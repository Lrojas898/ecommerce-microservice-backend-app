#!/bin/bash

# Enable Flyway in all microservices dev configurations
services=("user-service" "product-service" "favourite-service" "order-service" "payment-service" "shipping-service")

for service in "${services[@]}"; do
    config_file="${service}/src/main/resources/application-dev.yml"
    if [ -f "$config_file" ]; then
        echo "Fixing Flyway configuration in $service..."
        sed -i 's/#flyway:/flyway:/' "$config_file"
        sed -i 's/#  baseline-on-migrate: true/  baseline-on-migrate: true/' "$config_file"
        sed -i 's/#  enabled: true/  enabled: true/' "$config_file"
        echo "Fixed $service"
    else
        echo "Config file not found for $service"
    fi
done

echo "All services updated!"
