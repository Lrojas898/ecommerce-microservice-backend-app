package com.selimhorri.app.business.auth.service.impl;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

import com.selimhorri.app.business.auth.model.request.AuthenticationRequest;
import com.selimhorri.app.business.auth.model.response.AuthenticationResponse;
import com.selimhorri.app.business.auth.service.AuthenticationService;
import com.selimhorri.app.exception.wrapper.IllegalAuthenticationCredentialsException;
import com.selimhorri.app.jwt.service.JwtService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class AuthenticationServiceImpl implements AuthenticationService {
	
	private final AuthenticationManager authenticationManager;
	private final UserDetailsService userDetailsService;
	private final JwtService jwtService;
	
	@Override
	public AuthenticationResponse authenticate(final AuthenticationRequest authenticationRequest) {
		
		log.info("** AuthenticationResponse, authenticate user service - DEBUG MODE (JWT DISABLED)*\n");
		
		// TEMPORARY DEBUG - Skip authentication manager completely
		log.info("** DEBUG: Username: {}, Password provided: {}", 
				authenticationRequest.getUsername(), 
				authenticationRequest.getPassword() != null ? "YES" : "NO");
		
		// Skip AuthenticationManager for debugging
		// Instead, just verify user exists via UserDetailsService
		try {
			this.userDetailsService.loadUserByUsername(authenticationRequest.getUsername());
			log.info("** DEBUG: User found via UserDetailsService");
			
			// Return dummy JWT token for debugging
			return new AuthenticationResponse("DEBUG-TOKEN-JWT-DISABLED-" + authenticationRequest.getUsername());
		}
		catch (Exception e) {
			log.error("** DEBUG: Error loading user: {}", e.getMessage());
			throw new IllegalAuthenticationCredentialsException("#### User not found or service error! ####");
		}
	}
	
	@Override
	public Boolean authenticate(final String jwt) {
		return null;
	}
	
	
	
}










