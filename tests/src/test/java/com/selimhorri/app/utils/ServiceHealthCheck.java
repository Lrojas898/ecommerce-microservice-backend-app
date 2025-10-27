package com.selimhorri.app.utils;

import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import java.util.concurrent.TimeUnit;

public class ServiceHealthCheck {
    
    private final RestTemplate restTemplate;
    private static final int MAX_RETRIES = 30;
    private static final int RETRY_DELAY = 2000; // 2 seconds
    
    public ServiceHealthCheck(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    @Retryable(maxAttempts = MAX_RETRIES, backoff = @Backoff(delay = RETRY_DELAY))
    public boolean waitForService(String serviceUrl) {
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(serviceUrl + "/actuator/health", String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            return false;
        }
    }
    
    public boolean waitForAllServices(String... serviceUrls) {
        for (String url : serviceUrls) {
            if (!waitForService(url)) {
                return false;
            }
        }
        return true;
    }
}