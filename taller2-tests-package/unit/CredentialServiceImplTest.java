package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.exception.wrapper.CredentialNotFoundException;
import com.selimhorri.app.helper.CredentialMappingHelper;
import com.selimhorri.app.repository.CredentialRepository;

/**
 * Unit tests for CredentialServiceImpl
 * Tests user authentication credential management
 * Part of user-service microservice
 */
@ExtendWith(MockitoExtension.class)
class CredentialServiceImplTest {

    @Mock
    private CredentialRepository credentialRepository;

    @InjectMocks
    private CredentialServiceImpl credentialService;

    private User user;
    private Credential credential;
    private CredentialDto credentialDto;

    @BeforeEach
    void setUp() {
        this.user = User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@test.com")
                .build();

        this.credential = Credential.builder()
                .credentialId(1)
                .username("johndoe")
                .password("$2a$10$hashedPassword")
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .user(this.user)
                .build();

        this.credentialDto = CredentialMappingHelper.map(this.credential);
    }

    @Test
    void findByUsername_shouldReturnCredentialDto_whenUsernameExists() {
        // given
        final String username = "johndoe";
        when(this.credentialRepository.findByUsername(username))
                .thenReturn(Optional.of(this.credential));

        // when
        final CredentialDto result = this.credentialService.findByUsername(username);

        // then
        assertNotNull(result);
        assertEquals(username, result.getUsername());
        assertEquals(this.credential.getIsEnabled(), result.getIsEnabled());
        verify(this.credentialRepository, times(1)).findByUsername(username);
    }

    @Test
    void findByUsername_shouldThrowException_whenUsernameNotFound() {
        // given
        final String username = "nonexistent";
        when(this.credentialRepository.findByUsername(username))
                .thenReturn(Optional.empty());

        // when, then
        assertThrows(CredentialNotFoundException.class,
                () -> this.credentialService.findByUsername(username));
        verify(this.credentialRepository, times(1)).findByUsername(username);
    }

    @Test
    void save_shouldReturnSavedCredential() {
        // given
        when(this.credentialRepository.save(any(Credential.class)))
                .thenReturn(this.credential);

        // when
        final CredentialDto result = this.credentialService.save(this.credentialDto);

        // then
        assertNotNull(result);
        assertEquals(this.credentialDto.getUsername(), result.getUsername());
        verify(this.credentialRepository, times(1)).save(any(Credential.class));
    }

    @Test
    void update_shouldReturnUpdatedCredential() {
        // given
        final CredentialDto updatedDto = this.credentialDto;
        updatedDto.setIsEnabled(false);

        final Credential updatedCredential = CredentialMappingHelper.map(updatedDto);
        when(this.credentialRepository.save(any(Credential.class)))
                .thenReturn(updatedCredential);

        // when
        final CredentialDto result = this.credentialService.update(updatedDto);

        // then
        assertNotNull(result);
        assertEquals(false, result.getIsEnabled());
        verify(this.credentialRepository, times(1)).save(any(Credential.class));
    }

    @Test
    void findById_shouldReturnCredentialDto_whenIdExists() {
        // given
        final Integer credentialId = 1;
        when(this.credentialRepository.findById(credentialId))
                .thenReturn(Optional.of(this.credential));

        // when
        final CredentialDto result = this.credentialService.findById(credentialId);

        // then
        assertNotNull(result);
        assertEquals(credentialId, result.getCredentialId());
        assertEquals("johndoe", result.getUsername());
        verify(this.credentialRepository, times(1)).findById(credentialId);
    }
}
