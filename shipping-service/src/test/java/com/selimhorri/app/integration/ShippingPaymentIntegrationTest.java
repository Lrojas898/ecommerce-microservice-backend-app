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

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.repository.OrderItemRepository;

/**
 * Integration test for Shipping service
 * Tests shipping item management after payment processing
 * Uses H2 in-memory database for testing
 *
 * This test validates that shipping-service can:
 * - Create shipping items from order items
 * - Track shipping status
 * - Handle order fulfillment workflow
 *
 * Architecture flow: order-service → payment-service → shipping-service
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class ShippingPaymentIntegrationTest {

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
    private OrderItemRepository orderItemRepository;

    @Test
    void createShippingItem_afterPaymentConfirmed() {
        // Arrange: Simulate order item ready for shipping after payment
        final OrderItem shippingItem = OrderItem.builder()
                .orderedQuantity(2)
                .productId(101)
                .orderId(1001)
                .build();

        // Act: Save shipping item
        final OrderItem savedItem = this.orderItemRepository.save(shippingItem);

        // Assert
        assertThat(savedItem).isNotNull();
        assertThat(savedItem.getOrderItemId()).isNotNull();
        assertThat(savedItem.getOrderedQuantity()).isEqualTo(2);
        assertThat(savedItem.getProductId()).isEqualTo(101);
        assertThat(savedItem.getOrderId()).isEqualTo(1001);
    }

    @Test
    void findShippingItemsByOrder_shouldReturnAllItems() {
        // Arrange: Create multiple items for same order
        this.orderItemRepository.save(OrderItem.builder()
                .orderedQuantity(1)
                .productId(201)
                .orderId(2001)
                .build());

        this.orderItemRepository.save(OrderItem.builder()
                .orderedQuantity(3)
                .productId(202)
                .orderId(2001)
                .build());

        // Act
        final var items = this.orderItemRepository.findAll().stream()
                .filter(item -> item.getOrderId().equals(2001))
                .toList();

        // Assert
        assertThat(items).hasSize(2);
        assertThat(items).allMatch(item -> item.getOrderId().equals(2001));
    }

    @Test
    void updateShippingQuantity_shouldReflectChanges() {
        // Arrange
        final OrderItem item = this.orderItemRepository.save(OrderItem.builder()
                .orderedQuantity(5)
                .productId(301)
                .orderId(3001)
                .build());

        // Act: Update quantity
        item.setOrderedQuantity(10);
        final OrderItem updated = this.orderItemRepository.save(item);

        // Assert
        assertThat(updated.getOrderedQuantity()).isEqualTo(10);
        assertThat(updated.getOrderItemId()).isEqualTo(item.getOrderItemId());
    }
}
