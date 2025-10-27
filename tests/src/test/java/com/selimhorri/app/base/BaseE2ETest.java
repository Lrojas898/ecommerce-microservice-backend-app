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

    @BeforeAll
    public static void waitForServices() {
        // Wait for core infrastructure services first
        await().atMost(2, TimeUnit.MINUTES)
               .pollInterval(Duration.ofSeconds(5))
               .until(() -> healthCheck.waitForService("http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com/eureka"));

        await().atMost(2, TimeUnit.MINUTES)
               .pollInterval(Duration.ofSeconds(5))
               .until(() -> healthCheck.waitForService("http://cloud-config:8888"));

        // Then wait for business services
        String[] services = {
            "http://user-service:8100",
            "http://product-service:8200",
            "http://order-service:8300",
            "http://payment-service:8400",
            "http://shipping-service:8500"
        };

        await().atMost(5, TimeUnit.MINUTES)
               .pollInterval(Duration.ofSeconds(10))
               .until(() -> healthCheck.waitForAllServices(services));
    }
}