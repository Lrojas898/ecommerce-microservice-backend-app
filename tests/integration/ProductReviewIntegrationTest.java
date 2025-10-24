package com.ecommerce.product.integration;

import com.ecommerce.product.domain.Review;
import com.ecommerce.product.domain.Product;
import com.ecommerce.product.dto.ReviewDto;
import com.ecommerce.product.repository.ReviewRepository;
import com.ecommerce.product.repository.ProductRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for Product Review functionality
 * Tests communication between services and database
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Transactional
class ProductReviewIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
        .withDatabaseName("ecommerce_test")
        .withUsername("test")
        .withPassword("test");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private ProductRepository productRepository;

    private Product testProduct;

    @BeforeEach
    void setUp() {
        reviewRepository.deleteAll();
        productRepository.deleteAll();

        testProduct = Product.builder()
            .productTitle("Integration Test Laptop")
            .imageUrl("laptop.jpg")
            .sku("INT-LAP-001")
            .priceUnit(1299.99)
            .quantity(5)
            .build();

        testProduct = productRepository.save(testProduct);
    }

    @Test
    @DisplayName("Integration Test 1: POST /api/reviews - Create review and persist to database")
    void testCreateReview_EndToEnd() throws Exception {
        // Given
        ReviewDto reviewDto = ReviewDto.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(5)
            .comment("Amazing laptop for development!")
            .build();

        // When & Then
        mockMvc.perform(post("/api/reviews")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(reviewDto)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.rating").value(5))
            .andExpect(jsonPath("$.comment").value("Amazing laptop for development!"));

        // Verify database persistence
        assertThat(reviewRepository.findAll()).hasSize(1);
    }

    @Test
    @DisplayName("Integration Test 2: GET /api/reviews/product/{productId} - Retrieve all reviews")
    void testGetReviewsByProduct_EndToEnd() throws Exception {
        // Given - Create multiple reviews
        Review review1 = Review.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(5)
            .comment("Excellent!")
            .reviewDate(LocalDateTime.now())
            .build();

        Review review2 = Review.builder()
            .productId(testProduct.getProductId())
            .userId(101)
            .rating(4)
            .comment("Very good")
            .reviewDate(LocalDateTime.now())
            .build();

        reviewRepository.save(review1);
        reviewRepository.save(review2);

        // When & Then
        mockMvc.perform(get("/api/reviews/product/" + testProduct.getProductId())
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(2))
            .andExpect(jsonPath("$[0].rating").exists())
            .andExpect(jsonPath("$[1].rating").exists());
    }

    @Test
    @DisplayName("Integration Test 3: GET /api/reviews/product/{productId}/average - Calculate average rating")
    void testGetAverageRating_EndToEnd() throws Exception {
        // Given - Create reviews with different ratings
        reviewRepository.save(Review.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(5)
            .comment("Perfect!")
            .reviewDate(LocalDateTime.now())
            .build());

        reviewRepository.save(Review.builder()
            .productId(testProduct.getProductId())
            .userId(101)
            .rating(4)
            .comment("Good")
            .reviewDate(LocalDateTime.now())
            .build());

        reviewRepository.save(Review.builder()
            .productId(testProduct.getProductId())
            .userId(102)
            .rating(3)
            .comment("Average")
            .reviewDate(LocalDateTime.now())
            .build());

        // When & Then - Average should be (5+4+3)/3 = 4.0
        mockMvc.perform(get("/api/reviews/product/" + testProduct.getProductId() + "/average")
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.averageRating").value(4.0))
            .andExpect(jsonPath("$.totalReviews").value(3));
    }

    @Test
    @DisplayName("Integration Test 4: PUT /api/reviews/{reviewId} - Update review")
    void testUpdateReview_EndToEnd() throws Exception {
        // Given - Create initial review
        Review review = reviewRepository.save(Review.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(3)
            .comment("Initial comment")
            .reviewDate(LocalDateTime.now())
            .build());

        ReviewDto updateDto = ReviewDto.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(5)
            .comment("Updated: Now I love it!")
            .build();

        // When & Then
        mockMvc.perform(put("/api/reviews/" + review.getReviewId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateDto)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.rating").value(5))
            .andExpect(jsonPath("$.comment").value("Updated: Now I love it!"));

        // Verify database update
        Review updated = reviewRepository.findById(review.getReviewId()).orElseThrow();
        assertThat(updated.getRating()).isEqualTo(5);
        assertThat(updated.getComment()).isEqualTo("Updated: Now I love it!");
    }

    @Test
    @DisplayName("Integration Test 5: DELETE /api/reviews/{reviewId} - Delete review and verify cascade")
    void testDeleteReview_EndToEnd() throws Exception {
        // Given - Create review
        Review review = reviewRepository.save(Review.builder()
            .productId(testProduct.getProductId())
            .userId(100)
            .rating(5)
            .comment("Will be deleted")
            .reviewDate(LocalDateTime.now())
            .build());

        Integer reviewId = review.getReviewId();
        assertThat(reviewRepository.findById(reviewId)).isPresent();

        // When
        mockMvc.perform(delete("/api/reviews/" + reviewId)
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isNoContent());

        // Then - Verify deletion
        assertThat(reviewRepository.findById(reviewId)).isEmpty();
        assertThat(reviewRepository.findAll()).hasSize(0);
    }
}
