package com.selimhorri.app.base;

import com.selimhorri.app.config.E2ETestConfig;
import com.selimhorri.app.utils.ServiceHealthCheck;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.client.RestTemplate;

import static org.awaitility.Awaitility.await;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(E2ETestConfig.class)
@ActiveProfiles("e2e")
public abstract class BaseE2ETest {

    private static final RestTemplate restTemplate = new RestTemplateBuilder()
            .setConnectTimeout(Duration.ofSeconds(10))
            .setReadTimeout(Duration.ofSeconds(10))
            .build();
    
    private static final ServiceHealthCheck healthCheck = new ServiceHealthCheck(restTemplate);

    protected static final String API_URL = System.getProperty("test.base.url", 
            "http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com");

    @BeforeAll
    public static void waitForServices() {
        // Wait for API Gateway health check
        await().atMost(2, TimeUnit.MINUTES)
               .pollInterval(Duration.ofSeconds(5))
               .until(() -> healthCheck.waitForService(API_URL + "/actuator/health"));

        // Then check each service through the API Gateway
        String[] endpoints = {
            "/user-service/actuator/health",
            "/product-service/actuator/health",
            "/order-service/actuator/health",
            "/payment-service/actuator/health",
            "/shipping-service/actuator/health"
        };

        for (String endpoint : endpoints) {
            await().atMost(2, TimeUnit.MINUTES)
                   .pollInterval(Duration.ofSeconds(5))
                   .until(() -> healthCheck.waitForService(API_URL + endpoint));
        }
    }

    protected String createAuthToken() {
        // TODO: Implement authentication token generation
        return "test-token";
    }

    protected void cleanupTestData() {
        // TODO: Implement test data cleanup
    }
}