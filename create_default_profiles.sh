#!/bin/bash

services=("user-service" "favourite-service" "order-service" "payment-service" "shipping-service")

for service in "${services[@]}"; do
    config_file="${service}/src/main/resources/application-default.yml"
    dev_config="${service}/src/main/resources/application-dev.yml"
    
    if [ -f "$dev_config" ]; then
        echo "Creating default profile for $service..."
        cp "$dev_config" "$config_file"
        echo "Created $config_file"
    else
        echo "Dev config not found for $service"
    fi
done

echo "All default profiles created!"
