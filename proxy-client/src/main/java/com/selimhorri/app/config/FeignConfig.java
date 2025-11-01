package com.selimhorri.app.config;

import feign.RequestInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Feign Configuration
 * Registers the FeignClientInterceptor to propagate Authorization headers
 */
@Configuration
public class FeignConfig {

    @Bean
    public RequestInterceptor feignClientInterceptor() {
        return new FeignClientInterceptor();
    }
}
