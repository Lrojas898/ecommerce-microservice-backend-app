package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.exception.wrapper.PaymentNotFoundException;
import com.selimhorri.app.helper.PaymentMappingHelper;
import com.selimhorri.app.repository.PaymentRepository;

/**
 * Unit tests for PaymentServiceImpl
 * Tests payment processing functionality with order service integration
 * Part of payment-service microservice
 */
@ExtendWith(MockitoExtension.class)
class PaymentServiceImplTest {

    @Mock
    private PaymentRepository paymentRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private PaymentServiceImpl paymentService;

    private OrderDto orderDto;
    private Payment payment;
    private PaymentDto paymentDto;

    @BeforeEach
    void setUp() {
        this.orderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(100.0)
                .build();

        this.payment = Payment.builder()
                .paymentId(1)
                .isPayed(true)
                .orderId(1)
                .build();

        this.paymentDto = PaymentMappingHelper.map(this.payment);
        this.paymentDto.setOrderDto(this.orderDto);
    }

    @Test
    void findById_shouldReturnPaymentWithOrderDetails() {
        // given
        final Integer paymentId = 1;
        when(this.paymentRepository.findById(paymentId))
                .thenReturn(Optional.of(this.payment));
        when(this.restTemplate.getForObject(anyString(), any()))
                .thenReturn(this.orderDto);

        // when
        final PaymentDto result = this.paymentService.findById(paymentId);

        // then
        assertNotNull(result);
        assertEquals(paymentId, result.getPaymentId());
        assertNotNull(result.getOrderDto());
        assertEquals(this.orderDto.getOrderId(), result.getOrderDto().getOrderId());
        verify(this.paymentRepository, times(1)).findById(paymentId);
        verify(this.restTemplate, times(1)).getForObject(anyString(), any());
    }

    @Test
    void findById_shouldThrowException_whenPaymentNotFound() {
        // given
        final Integer paymentId = 999;
        when(this.paymentRepository.findById(paymentId))
                .thenReturn(Optional.empty());

        // when, then
        assertThrows(PaymentNotFoundException.class,
                () -> this.paymentService.findById(paymentId));
        verify(this.paymentRepository, times(1)).findById(paymentId);
    }

    @Test
    void save_shouldReturnSavedPayment() {
        // given
        when(this.paymentRepository.save(any(Payment.class)))
                .thenReturn(this.payment);

        // when
        final PaymentDto result = this.paymentService.save(this.paymentDto);

        // then
        assertNotNull(result);
        assertEquals(this.payment.getPaymentId(), result.getPaymentId());
        assertEquals(this.payment.getIsPayed(), result.getIsPayed());
        verify(this.paymentRepository, times(1)).save(any(Payment.class));
    }

    @Test
    void findAll_shouldReturnPaymentsWithOrderDetails() {
        // given
        when(this.paymentRepository.findAll()).thenReturn(List.of(this.payment));
        when(this.restTemplate.getForObject(anyString(), any()))
                .thenReturn(this.orderDto);

        // when
        final List<PaymentDto> result = this.paymentService.findAll();

        // then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertNotNull(result.get(0).getOrderDto());
        assertEquals(this.orderDto.getOrderId(), result.get(0).getOrderDto().getOrderId());
        verify(this.paymentRepository, times(1)).findAll();
    }

    @Test
    void deleteById_shouldCallRepositoryDelete() {
        // given
        final Integer paymentId = 1;

        // when
        this.paymentService.deleteById(paymentId);

        // then
        verify(this.paymentRepository, times(1)).deleteById(paymentId);
    }
}
