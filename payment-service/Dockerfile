# Multi-stage build for payment-service
FROM maven:3.8.7-openjdk-18-slim AS build
WORKDIR /app

# Copy parent pom and all modules
COPY pom.xml ./
COPY service-discovery ./service-discovery
COPY cloud-config ./cloud-config
COPY api-gateway ./api-gateway
COPY proxy-client ./proxy-client
COPY payment-service ./payment-service
COPY user-service ./user-service
COPY product-service ./product-service
COPY favourite-service ./favourite-service
COPY order-service ./order-service
COPY shipping-service ./shipping-service

# Build the application
RUN mvn clean package -pl payment-service -am -DskipTests

# Runtime stage
FROM openjdk:11-jre-slim
WORKDIR /app

# Copy the built jar
COPY --from=build /app/payment-service/target/payment-service-*.jar app.jar

# Expose port
EXPOSE 8084

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8084/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
