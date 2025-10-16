
package com.selimhorri.app.resource;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.selimhorri.app.domain.Order;
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
    private OrderRepository orderRepository;

    @Test
    void saveOrder_shouldPersistInDatabase() {
        // Arrange
        final Order order = Order.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("TEST_ORDER")
                .orderFee(100.0)
                .build();

        // Act
        final Order savedOrder = this.orderRepository.save(order);

        // Assert
        assertThat(savedOrder).isNotNull();
        assertThat(savedOrder.getOrderId()).isNotNull();
        assertThat(savedOrder.getOrderDesc()).isEqualTo("TEST_ORDER");
        assertThat(savedOrder.getOrderFee()).isEqualTo(100.0);
    }

    @Test
    void findById_shouldReturnOrder() {
        // Arrange
        final Order order = this.orderRepository.save(Order.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("FIND_TEST_ORDER")
                .orderFee(50.0)
                .build());

        // Act
        final Order foundOrder = this.orderRepository.findById(order.getOrderId()).orElse(null);

        // Assert
        assertThat(foundOrder).isNotNull();
        assertThat(foundOrder.getOrderId()).isEqualTo(order.getOrderId());
        assertThat(foundOrder.getOrderDesc()).isEqualTo("FIND_TEST_ORDER");
    }

    @Test
    void findAll_shouldReturnAllOrders() {
        // Arrange
        this.orderRepository.deleteAll();
        this.orderRepository.save(Order.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("ORDER_1")
                .orderFee(25.0)
                .build());
        this.orderRepository.save(Order.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("ORDER_2")
                .orderFee(75.0)
                .build());

        // Act
        final List<Order> orders = this.orderRepository.findAll();

        // Assert
        assertThat(orders).hasSize(2);
    }

}
