#!/bin/bash

# Script para agregar dependencia H2 con scope runtime a todos los servicios que usan JPA

set -e

# Servicios que necesitan H2 (que usan JPA)
SERVICES_WITH_JPA=(
    "order-service"
    "payment-service" 
    "product-service"
    "user-service"
    "shipping-service"
)

echo "🔄 Agregando dependencia H2 con scope runtime a servicios JPA..."

for service in "${SERVICES_WITH_JPA[@]}"; do
    echo "📝 Procesando $service..."
    
    if [ -f "${service}/pom.xml" ]; then
        # Verificar si ya tiene la dependencia H2
        if grep -q "com.h2database" "${service}/pom.xml"; then
            echo "   ✅ ${service} ya tiene dependencia H2, actualizando scope y versión..."
            
            # Reemplazar la dependencia H2 existente
            sed -i '/<groupId>com\.h2database<\/groupId>/,/<\/dependency>/{
                s/<scope>test<\/scope>/<scope>runtime<\/scope>/
                /<artifactId>h2<\/artifactId>/a\
			<version>2.3.232</version>
            }' "${service}/pom.xml"
        else
            echo "   ➕ Agregando nueva dependencia H2 a ${service}..."
            
            # Buscar la posición después de mysql-connector para insertar H2
            if grep -q "mysql-connector-java" "${service}/pom.xml"; then
                # Insertar después de mysql-connector
                sed -i '/mysql-connector-java/,/<\/dependency>/a\
		<dependency>\
			<groupId>com.h2database</groupId>\
			<artifactId>h2</artifactId>\
			<version>2.3.232</version>\
			<scope>runtime</scope>\
		</dependency>' "${service}/pom.xml"
            else
                echo "   ⚠️  No se encontró mysql-connector-java en ${service}, revisar manualmente"
            fi
        fi
        
        echo "   ✅ ${service} actualizado"
    else
        echo "   ⚠️  ${service}/pom.xml no encontrado"
    fi
done

echo ""
echo "🎉 Dependencia H2 agregada a todos los servicios JPA!"
echo ""
echo "📋 Servicios actualizados:"
for service in "${SERVICES_WITH_JPA[@]}"; do
    echo "   - $service: H2 2.3.232 con scope runtime"
done