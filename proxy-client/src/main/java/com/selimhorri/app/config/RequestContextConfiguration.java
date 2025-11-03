package com.selimhorri.app.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.context.request.RequestContextListener;

/**
 * Configuration to ensure request context is available for Feign interceptors
 * This allows propagating HTTP headers (like Authorization) from incoming requests
 * to outgoing Feign client calls
 */
@Configuration
public class RequestContextConfiguration {

    @Bean
    public RequestContextListener requestContextListener() {
        return new RequestContextListener();
    }
}
