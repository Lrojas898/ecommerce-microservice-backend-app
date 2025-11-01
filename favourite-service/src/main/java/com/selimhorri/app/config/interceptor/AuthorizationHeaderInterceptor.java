package com.selimhorri.app.config.interceptor;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

/**
 * RestTemplate Interceptor to propagate Authorization header
 * from incoming requests to outgoing RestTemplate requests.
 *
 * This ensures that JWT tokens are passed through from the proxy-client
 * to downstream microservices (order-service, product-service, etc.)
 */
@Slf4j
@Component
public class AuthorizationHeaderInterceptor implements ClientHttpRequestInterceptor {

    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                        ClientHttpRequestExecution execution) throws IOException {
        try {
            ServletRequestAttributes attributes =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

            if (attributes != null) {
                HttpServletRequest httpRequest = attributes.getRequest();
                String authHeader = httpRequest.getHeader(AUTHORIZATION_HEADER);

                if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
                    log.debug("Propagating Authorization header to RestTemplate request: {}",
                        request.getURI());
                    request.getHeaders().add(AUTHORIZATION_HEADER, authHeader);
                } else {
                    log.debug("No Authorization header found in request context for: {}",
                        request.getURI());
                }
            } else {
                log.debug("No request attributes available for: {}", request.getURI());
            }
        } catch (Exception e) {
            log.warn("Error propagating Authorization header: {}", e.getMessage());
        }

        return execution.execute(request, body);
    }
}
