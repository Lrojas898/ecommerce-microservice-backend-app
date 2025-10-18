# Multi-stage build for user-service
FROM maven:3.8.7-openjdk-18-slim AS build
WORKDIR /app

# Copy parent pom and all required modules
COPY pom.xml ./
COPY mvnw ./
COPY .mvn ./.mvn
COPY proxy-client ./proxy-client
COPY user-service ./user-service
COPY service-discovery ./service-discovery
COPY cloud-config ./cloud-config
COPY api-gateway ./api-gateway
COPY product-service ./product-service
COPY favourite-service ./favourite-service
COPY order-service ./order-service
COPY shipping-service ./shipping-service
COPY payment-service ./payment-service

# Build the application
RUN chmod +x mvnw && ./mvnw clean install -pl user-service -am -DskipTests

# Runtime stage
FROM openjdk:11-jre-slim
WORKDIR /app

# Copy the built jar
COPY --from=build /app/user-service/target/user-service-*.jar app.jar

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8081/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
