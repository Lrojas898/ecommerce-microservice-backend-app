# Multi-stage build for product-service
FROM maven:3.8.7-openjdk-18-slim AS build
WORKDIR /app

# Copy parent pom and proxy-client (dependency)
COPY pom.xml ./
COPY proxy-client ./proxy-client
COPY product-service ./product-service

# Build the application
RUN mvn clean package -pl product-service -am -DskipTests

# Runtime stage
FROM openjdk:11-jre-slim
WORKDIR /app

# Copy the built jar
COPY --from=build /app/product-service/target/product-service-*.jar app.jar

# Expose port
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8082/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
