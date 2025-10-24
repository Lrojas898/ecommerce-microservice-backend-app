package com.ecommerce.product.service;

import com.ecommerce.product.domain.Review;
import com.ecommerce.product.domain.Product;
import com.ecommerce.product.repository.ReviewRepository;
import com.ecommerce.product.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

/**
 * Unit tests for Product Review Service
 * Tests individual components without external dependencies
 */
class ProductReviewServiceTest {

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductReviewService productReviewService;

    private Product testProduct;
    private Review testReview;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);

        testProduct = Product.builder()
            .productId(1)
            .productTitle("Test Laptop")
            .imageUrl("laptop.jpg")
            .sku("LAP-001")
            .priceUnit(999.99)
            .quantity(10)
            .build();

        testReview = Review.builder()
            .reviewId(1)
            .productId(1)
            .userId(100)
            .rating(5)
            .comment("Excellent product!")
            .reviewDate(LocalDateTime.now())
            .build();
    }

    @Test
    @DisplayName("Test 1: Should create a new review successfully")
    void testCreateReview_Success() {
        // Given
        when(productRepository.findById(anyInt())).thenReturn(Optional.of(testProduct));
        when(reviewRepository.save(any(Review.class))).thenReturn(testReview);

        // When
        Review createdReview = productReviewService.createReview(testReview);

        // Then
        assertThat(createdReview).isNotNull();
        assertThat(createdReview.getRating()).isEqualTo(5);
        assertThat(createdReview.getComment()).isEqualTo("Excellent product!");
        verify(reviewRepository, times(1)).save(any(Review.class));
    }

    @Test
    @DisplayName("Test 2: Should retrieve all reviews for a product")
    void testGetReviewsByProductId_Success() {
        // Given
        Review review2 = Review.builder()
            .reviewId(2)
            .productId(1)
            .userId(101)
            .rating(4)
            .comment("Good product")
            .reviewDate(LocalDateTime.now())
            .build();

        List<Review> reviews = Arrays.asList(testReview, review2);
        when(reviewRepository.findByProductId(1)).thenReturn(reviews);

        // When
        List<Review> foundReviews = productReviewService.getReviewsByProductId(1);

        // Then
        assertThat(foundReviews).hasSize(2);
        assertThat(foundReviews.get(0).getRating()).isEqualTo(5);
        assertThat(foundReviews.get(1).getRating()).isEqualTo(4);
        verify(reviewRepository, times(1)).findByProductId(1);
    }

    @Test
    @DisplayName("Test 3: Should calculate average rating correctly")
    void testCalculateAverageRating_Success() {
        // Given
        Review review2 = Review.builder().reviewId(2).productId(1).rating(4).build();
        Review review3 = Review.builder().reviewId(3).productId(1).rating(3).build();

        List<Review> reviews = Arrays.asList(testReview, review2, review3);
        when(reviewRepository.findByProductId(1)).thenReturn(reviews);

        // When
        double averageRating = productReviewService.calculateAverageRating(1);

        // Then
        assertThat(averageRating).isEqualTo(4.0); // (5 + 4 + 3) / 3 = 4.0
    }

    @Test
    @DisplayName("Test 4: Should validate rating range (1-5)")
    void testValidateRating_InvalidRange() {
        // Given
        Review invalidReview = Review.builder()
            .productId(1)
            .userId(100)
            .rating(6) // Invalid rating
            .comment("Test")
            .build();

        // When & Then
        assertThatThrownBy(() -> productReviewService.createReview(invalidReview))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Rating must be between 1 and 5");

        verify(reviewRepository, never()).save(any(Review.class));
    }

    @Test
    @DisplayName("Test 5: Should delete review by ID successfully")
    void testDeleteReview_Success() {
        // Given
        when(reviewRepository.findById(1)).thenReturn(Optional.of(testReview));
        doNothing().when(reviewRepository).deleteById(1);

        // When
        productReviewService.deleteReview(1);

        // Then
        verify(reviewRepository, times(1)).findById(1);
        verify(reviewRepository, times(1)).deleteById(1);
    }
}
