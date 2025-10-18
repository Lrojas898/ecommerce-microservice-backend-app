package com.selimhorri.app.integration;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDateTime;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.repository.FavouriteRepository;

/**
 * Integration test for Favourite service
 * Tests user favourite products management
 * Uses H2 in-memory database for testing
 *
 * This test validates that favourite-service can:
 * - Link users with their favourite products
 * - Manage user wishlists
 * - Query favourites by user
 *
 * Architecture: user-service ← favourite-service → product-service
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class FavouriteUserProductIntegrationTest {

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
    private FavouriteRepository favouriteRepository;

    @BeforeEach
    void setUp() {
        this.favouriteRepository.deleteAll();
    }

    @Test
    void addProductToUserFavourites_shouldCreateFavourite() {
        // Arrange: User wants to favourite a product
        final Favourite favourite = Favourite.builder()
                .userId(1)  // User from user-service
                .productId(101)  // Product from product-service
                .likeDate(LocalDateTime.now())
                .build();

        // Act
        final Favourite saved = this.favouriteRepository.save(favourite);

        // Assert
        assertThat(saved).isNotNull();
        assertThat(saved.getUserId()).isEqualTo(1);
        assertThat(saved.getProductId()).isEqualTo(101);
        assertThat(saved.getLikeDate()).isNotNull();
    }

    @Test
    void getUserFavourites_shouldReturnAllFavouriteProducts() {
        // Arrange: User has multiple favourite products
        this.favouriteRepository.save(Favourite.builder()
                .userId(2)
                .productId(201)
                .likeDate(LocalDateTime.now())
                .build());

        this.favouriteRepository.save(Favourite.builder()
                .userId(2)
                .productId(202)
                .likeDate(LocalDateTime.now())
                .build());

        this.favouriteRepository.save(Favourite.builder()
                .userId(2)
                .productId(203)
                .likeDate(LocalDateTime.now())
                .build());

        // Another user's favourites (should not be included)
        this.favouriteRepository.save(Favourite.builder()
                .userId(3)
                .productId(301)
                .likeDate(LocalDateTime.now())
                .build());

        // Act: Get favourites for user 2
        final var userFavourites = this.favouriteRepository.findAll().stream()
                .filter(f -> f.getUserId().equals(2))
                .toList();

        // Assert
        assertThat(userFavourites).hasSize(3);
        assertThat(userFavourites).allMatch(f -> f.getUserId().equals(2));
        assertThat(userFavourites)
                .extracting(Favourite::getProductId)
                .containsExactlyInAnyOrder(201, 202, 203);
    }

    @Test
    void removeProductFromFavourites_shouldDelete() {
        // Arrange
        final LocalDateTime likeDate = LocalDateTime.now();
        final Favourite favourite = this.favouriteRepository.save(Favourite.builder()
                .userId(4)
                .productId(401)
                .likeDate(likeDate)
                .build());

        // Build composite key for deletion
        final com.selimhorri.app.domain.id.FavouriteId favouriteId =
            new com.selimhorri.app.domain.id.FavouriteId(4, 401, likeDate);

        // Act
        this.favouriteRepository.deleteById(favouriteId);

        // Assert
        final var remaining = this.favouriteRepository.findById(favouriteId);
        assertThat(remaining).isEmpty();
    }

    @Test
    void checkIfProductIsFavourited_byUser() {
        // Arrange
        this.favouriteRepository.save(Favourite.builder()
                .userId(5)
                .productId(501)
                .likeDate(LocalDateTime.now())
                .build());

        // Act
        final boolean isFavourited = this.favouriteRepository.findAll().stream()
                .anyMatch(f -> f.getUserId().equals(5) && f.getProductId().equals(501));

        final boolean isNotFavourited = this.favouriteRepository.findAll().stream()
                .anyMatch(f -> f.getUserId().equals(5) && f.getProductId().equals(999));

        // Assert
        assertThat(isFavourited).isTrue();
        assertThat(isNotFavourited).isFalse();
    }
}
