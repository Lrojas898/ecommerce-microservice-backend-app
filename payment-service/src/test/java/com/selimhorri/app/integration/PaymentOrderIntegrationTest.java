package com.selimhorri.app.integration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.web.client.RestTemplate;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.repository.PaymentRepository;
import com.selimhorri.app.service.PaymentService;

/**
 * Integration test for Payment → Order communication
 * Tests the interaction between payment-service and order-service
 *
 * This test validates that payment-service can:
 * - Create payments linked to orders
 * - Retrieve order details from order-service via REST
 * - Handle payment processing for completed orders
 *
 * Architecture: payment-service → RestTemplate → order-service
 */
@Testcontainers
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class PaymentOrderIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
    }

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private PaymentService paymentService;

    @MockBean
    private RestTemplate restTemplate;

    @Test
    void createPaymentForOrder_shouldLinkToOrder() {
        // Arrange: Simulate order from order-service
        final OrderDto mockOrder = OrderDto.builder()
                .orderId(123)
                .orderDate(LocalDateTime.now())
                .orderDesc("Integration Test Order")
                .orderFee(250.50)
                .build();

        // Create payment for this order
        final Payment payment = Payment.builder()
                .orderId(123)
                .isPayed(true)
                .build();

        // Act
        final Payment savedPayment = this.paymentRepository.save(payment);

        // Assert
        assertThat(savedPayment).isNotNull();
        assertThat(savedPayment.getPaymentId()).isNotNull();
        assertThat(savedPayment.getOrderId()).isEqualTo(123);
        assertThat(savedPayment.getIsPayed()).isTrue();
    }

    @Test
    void findPaymentById_shouldRetrieveOrderDetailsFromOrderService() {
        // Arrange: Create payment
        final Payment payment = this.paymentRepository.save(Payment.builder()
                .orderId(456)
                .isPayed(false)
                .build());

        // Mock order-service response
        final OrderDto mockOrder = OrderDto.builder()
                .orderId(456)
                .orderDate(LocalDateTime.now())
                .orderDesc("Mock Order from Order Service")
                .orderFee(100.0)
                .build();

        when(this.restTemplate.getForObject(anyString(), eq(OrderDto.class)))
                .thenReturn(mockOrder);

        // Act
        final PaymentDto result = this.paymentService.findById(payment.getPaymentId());

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getOrderDto()).isNotNull();
        assertThat(result.getOrderDto().getOrderId()).isEqualTo(456);
        assertThat(result.getOrderDto().getOrderDesc()).isEqualTo("Mock Order from Order Service");
        assertThat(result.getOrderDto().getOrderFee()).isEqualTo(100.0);
    }

    @Test
    void processPaymentWorkflow_shouldUpdatePaymentStatus() {
        // Arrange: Create unpaid payment
        final Payment payment = this.paymentRepository.save(Payment.builder()
                .orderId(789)
                .isPayed(false)
                .build());

        // Mock order retrieval
        when(this.restTemplate.getForObject(anyString(), eq(OrderDto.class)))
                .thenReturn(OrderDto.builder()
                        .orderId(789)
                        .orderFee(500.0)
                        .build());

        // Act: Simulate payment processing
        payment.setIsPayed(true);
        final Payment processedPayment = this.paymentRepository.save(payment);

        // Assert
        assertThat(processedPayment.getIsPayed()).isTrue();

        // Verify payment can still retrieve order details after processing
        final PaymentDto result = this.paymentService.findById(processedPayment.getPaymentId());
        assertThat(result.getOrderDto()).isNotNull();
        assertThat(result.getOrderDto().getOrderId()).isEqualTo(789);
    }
}
