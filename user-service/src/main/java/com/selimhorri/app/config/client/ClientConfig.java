package com.selimhorri.app.config.client;

import com.selimhorri.app.config.interceptor.AuthorizationHeaderInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

@Configuration
public class ClientConfig {

	@Autowired
	private AuthorizationHeaderInterceptor authorizationHeaderInterceptor;

	@LoadBalanced
	@Bean
	public RestTemplate restTemplateBean() {
		RestTemplate restTemplate = new RestTemplate();
		restTemplate.setInterceptors(Collections.singletonList(authorizationHeaderInterceptor));
		return restTemplate;
	}
	
	
	
}










