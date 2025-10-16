# Multi-stage build for user-service
FROM maven:3.8.7-openjdk-18-slim AS build
WORKDIR /app

# Copy parent pom and proxy-client (dependency)
COPY pom.xml ./
COPY proxy-client ./proxy-client
COPY user-service ./user-service

# Build the application
RUN mvn clean package -pl user-service -am -DskipTests

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
