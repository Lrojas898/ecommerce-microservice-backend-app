package com.selimhorri.app.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

/**
 * Feign Client Interceptor to propagate Authorization header
 * from incoming requests to outgoing Feign client requests.
 *
 * This ensures that JWT tokens are passed through the proxy-client
 * to downstream microservices (order-service, payment-service, etc.)
 */
@Slf4j
public class FeignClientInterceptor implements RequestInterceptor {

    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    @Override
    public void apply(RequestTemplate requestTemplate) {
        log.debug("FeignClientInterceptor.apply() called for URL: {}", requestTemplate.url());
        
        try {
            ServletRequestAttributes attributes =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                String authHeader = request.getHeader(AUTHORIZATION_HEADER);

                if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
                    log.info("✓ Propagating Authorization header to Feign request: {}", requestTemplate.url());
                    requestTemplate.header(AUTHORIZATION_HEADER, authHeader);
                } else {
                    log.warn("✗ No valid Authorization header found in request context for: {}", requestTemplate.url());
                }
            } else {
                log.warn("✗ No request attributes available for: {}, this may cause 401 errors", requestTemplate.url());
            }
        } catch (Exception e) {
            log.error("✗ Error propagating Authorization header: {}", e.getMessage(), e);
        }
    }
}
