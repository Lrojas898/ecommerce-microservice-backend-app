package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Cart;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.exception.wrapper.CartNotFoundException;
import com.selimhorri.app.helper.CartMappingHelper;
import com.selimhorri.app.repository.CartRepository;

/**
 * Unit tests for CartServiceImpl
 * Tests shopping cart management functionality
 * Part of order-service microservice
 */
@ExtendWith(MockitoExtension.class)
class CartServiceImplTest {

    @Mock
    private CartRepository cartRepository;

    @InjectMocks
    private CartServiceImpl cartService;

    private Cart cart;
    private CartDto cartDto;

    @BeforeEach
    void setUp() {
        this.cart = Cart.builder()
                .cartId(1)
                .build();
        this.cartDto = CartMappingHelper.map(this.cart);
    }

    @Test
    void findAll_shouldReturnListOfCarts() {
        // given
        when(this.cartRepository.findAll()).thenReturn(List.of(this.cart));

        // when
        final List<CartDto> result = this.cartService.findAll();

        // then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(this.cart.getCartId(), result.get(0).getCartId());
        verify(this.cartRepository, times(1)).findAll();
    }

    @Test
    void findAll_shouldReturnEmptyList_whenNoCartsExist() {
        // given
        when(this.cartRepository.findAll()).thenReturn(Collections.emptyList());

        // when
        final List<CartDto> result = this.cartService.findAll();

        // then
        assertNotNull(result);
        assertEquals(0, result.size());
        verify(this.cartRepository, times(1)).findAll();
    }

    @Test
    void findById_shouldReturnCart_whenIdExists() {
        // given
        final Integer cartId = 1;
        when(this.cartRepository.findById(cartId)).thenReturn(Optional.of(this.cart));

        // when
        final CartDto result = this.cartService.findById(cartId);

        // then
        assertNotNull(result);
        assertEquals(cartId, result.getCartId());
        verify(this.cartRepository, times(1)).findById(cartId);
    }

    @Test
    void findById_shouldThrowException_whenIdNotFound() {
        // given
        final Integer cartId = 999;
        when(this.cartRepository.findById(cartId)).thenReturn(Optional.empty());

        // when, then
        assertThrows(CartNotFoundException.class,
                () -> this.cartService.findById(cartId));
        verify(this.cartRepository, times(1)).findById(cartId);
    }

    @Test
    void save_shouldReturnSavedCart() {
        // given
        when(this.cartRepository.save(any(Cart.class))).thenReturn(this.cart);

        // when
        final CartDto result = this.cartService.save(this.cartDto);

        // then
        assertNotNull(result);
        assertEquals(this.cart.getCartId(), result.getCartId());
        verify(this.cartRepository, times(1)).save(any(Cart.class));
    }

    @Test
    void update_shouldReturnUpdatedCart() {
        // given
        when(this.cartRepository.save(any(Cart.class))).thenReturn(this.cart);

        // when
        final CartDto result = this.cartService.update(this.cartDto);

        // then
        assertNotNull(result);
        assertEquals(this.cart.getCartId(), result.getCartId());
        verify(this.cartRepository, times(1)).save(any(Cart.class));
    }

    @Test
    void deleteById_shouldCallRepositoryDelete() {
        // given
        final Integer cartId = 1;
        when(this.cartRepository.findById(cartId)).thenReturn(Optional.of(this.cart));
        doNothing().when(this.cartRepository).delete(any(Cart.class));

        // when
        this.cartService.deleteById(cartId);

        // then
        verify(this.cartRepository, times(1)).findById(cartId);
        verify(this.cartRepository, times(1)).delete(any(Cart.class));
    }
}
