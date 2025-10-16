
package com.selimhorri.app.resource;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.selimhorri.app.domain.Order;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.repository.OrderRepository;

@Testcontainers
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class OrderResourceIT {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "update");
    }

    @Autowired
    private TestRestTemplate testRestTemplate;

    @Autowired
    private OrderRepository orderRepository;

    @Test
    void createOrder_shouldSaveOrderInDatabase() {
        // Arrange
        final OrderDto orderDto = OrderDto.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(100.0)
                .build();

        final HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/json");
        final HttpEntity<OrderDto> request = new HttpEntity<>(orderDto, headers);

        // Act
        final ResponseEntity<OrderDto> response = this.testRestTemplate.exchange("/api/orders", HttpMethod.POST, request, OrderDto.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getOrderDesc()).isEqualTo("Test Order");

        final List<Order> orders = this.orderRepository.findAll();
        assertThat(orders).hasSize(1);
        assertThat(orders.get(0).getOrderDesc()).isEqualTo("PENDING");
        assertThat(orders.get(0).getCart().getCartId()).isEqualTo(cart.getCartId());
    }

    @Test
    void findById_shouldReturnOrder() {
        // Arrange
        final Cart cart = this.cartRepository.save(Cart.builder().build());
        final Order savedOrder = this.orderRepository.save(Order.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("TEST_ORDER")
                .cart(cart)
                .build());

        // Act
        final ResponseEntity<OrderDto> response = this.testRestTemplate.getForEntity("/api/orders/{orderId}", OrderDto.class, savedOrder.getOrderId());

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getOrderId()).isEqualTo(savedOrder.getOrderId());
        assertThat(response.getBody().getOrderDesc()).isEqualTo("TEST_ORDER");
    }

}
