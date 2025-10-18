package com.selimhorri.app.integration;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.repository.CredentialRepository;
import com.selimhorri.app.repository.UserRepository;

/**
 * Integration test for User Service
 * Tests user creation and credential association
 * Uses H2 in-memory database for testing
 *
 * This test validates that user-service can:
 * - Store user data persistently
 * - Associate credentials with users
 * - Query users with their credentials
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class UserServiceIntegrationTest {

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> "jdbc:h2:mem:testdb");
        registry.add("spring.datasource.driver-class-name", () -> "org.h2.Driver");
        registry.add("spring.datasource.username", () -> "sa");
        registry.add("spring.datasource.password", () -> "");
        registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.H2Dialect");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CredentialRepository credentialRepository;

    @Test
    void createUserWithCredentials_shouldPersistBothEntities() {
        // Arrange: Create a user
        final User user = User.builder()
                .firstName("Integration")
                .lastName("Test")
                .email("integration@test.com")
                .phone("+1234567890")
                .build();

        // Act: Save user
        final User savedUser = this.userRepository.save(user);

        // Create credentials for the user
        final Credential credential = Credential.builder()
                .username("integrationtest")
                .password("$2a$10$hashedPassword")
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .user(savedUser)
                .build();

        final Credential savedCredential = this.credentialRepository.save(credential);

        // Assert: Verify both entities were saved and linked
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getUserId()).isNotNull();
        assertThat(savedUser.getEmail()).isEqualTo("integration@test.com");

        assertThat(savedCredential).isNotNull();
        assertThat(savedCredential.getCredentialId()).isNotNull();
        assertThat(savedCredential.getUsername()).isEqualTo("integrationtest");
        assertThat(savedCredential.getUser().getUserId()).isEqualTo(savedUser.getUserId());
    }

    @Test
    void findUserByEmail_shouldReturnCorrectUser() {
        // Arrange
        final User user = this.userRepository.save(User.builder()
                .firstName("Search")
                .lastName("Test")
                .email("search@test.com")
                .phone("+9876543210")
                .build());

        // Act
        final User foundUser = this.userRepository.findAll().stream()
                .filter(u -> u.getEmail().equals("search@test.com"))
                .findFirst()
                .orElse(null);

        // Assert
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getUserId()).isEqualTo(user.getUserId());
        assertThat(foundUser.getFirstName()).isEqualTo("Search");
    }

    @Test
    void findCredentialByUsername_shouldReturnCorrectCredential() {
        // Arrange
        final User user = this.userRepository.save(User.builder()
                .firstName("Credential")
                .lastName("Test")
                .email("credential@test.com")
                .build());

        this.credentialRepository.save(Credential.builder()
                .username("credtest")
                .password("$2a$10$test")
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .user(user)
                .build());

        // Act
        final Credential foundCredential = this.credentialRepository
                .findByUsername("credtest")
                .orElse(null);

        // Assert
        assertThat(foundCredential).isNotNull();
        assertThat(foundCredential.getUsername()).isEqualTo("credtest");
        assertThat(foundCredential.getUser().getEmail()).isEqualTo("credential@test.com");
    }
}
