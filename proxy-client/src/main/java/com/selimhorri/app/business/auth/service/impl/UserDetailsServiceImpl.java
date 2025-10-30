package com.selimhorri.app.business.auth.service.impl;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.selimhorri.app.business.user.model.CredentialDto;
import com.selimhorri.app.business.user.model.UserDetailsImpl;
import com.selimhorri.app.business.user.service.CredentialClientService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {
	
	private final CredentialClientService credentialClientService;
	
	@Override
	public UserDetails loadUserByUsername(final String username) throws UsernameNotFoundException {
		log.info("**UserDetails, load user by username: {}*\n", username);
		try {
			CredentialDto credential = this.credentialClientService.findByUsername(username).getBody();
			if (credential == null) {
				throw new UsernameNotFoundException("User not found: " + username);
			}
			return new UserDetailsImpl(credential);
		} catch (Exception e) {
			log.error("**Error loading user by username: {}, error: {}*\n", username, e.getMessage());
			throw new UsernameNotFoundException("User not found: " + username, e);
		}
	}
	
	
	
}










