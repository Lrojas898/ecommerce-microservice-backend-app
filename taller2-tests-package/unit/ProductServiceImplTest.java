
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

import com.selimhorri.app.domain.Category;
import com.selimhorri.app.domain.Product;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;
import com.selimhorri.app.helper.ProductMappingHelper;
import com.selimhorri.app.repository.ProductRepository;

@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private Category category;
    private Product product;
    private ProductDto productDto;

    @BeforeEach
    void setUp() {
        this.category = Category.builder()
                .categoryId(1)
                .categoryTitle("Electronics")
                .build();
        this.product = Product.builder()
                .productId(1)
                .productTitle("Test Product")
                .category(this.category)
                .build();
        this.productDto = ProductMappingHelper.map(this.product);
    }

    @Test
    void findById_shouldThrowProductNotFoundException_whenProductNotExists() {
        // given
        final int productId = 0;
        when(this.productRepository.findById(productId)).thenReturn(Optional.empty());

        // when, then
        assertThrows(ProductNotFoundException.class, () -> this.productService.findById(productId));
        verify(this.productRepository, times(1)).findById(productId);
    }

    @Test
    void findAll_shouldReturnListOfProductDtos() {
        // given
        when(this.productRepository.findAll()).thenReturn(List.of(this.product));

        // when
        final List<ProductDto> productDtos = this.productService.findAll();

        // then
        assertNotNull(productDtos);
        assertEquals(1, productDtos.size());
        assertEquals(this.productDto.getProductTitle(), productDtos.get(0).getProductTitle());
        verify(this.productRepository, times(1)).findAll();
    }
    
    @Test
    void findAll_shouldReturnEmptyList_whenNoProductsExist() {
        // given
        when(this.productRepository.findAll()).thenReturn(Collections.emptyList());

        // when
        final List<ProductDto> productDtos = this.productService.findAll();

        // then
        assertNotNull(productDtos);
        assertEquals(0, productDtos.size());
        verify(this.productRepository, times(1)).findAll();
    }

    @Test
    void save_shouldReturnSavedProductDto() {
        // given
        when(this.productRepository.save(any(Product.class))).thenReturn(this.product);

        // when
        final ProductDto savedProductDto = this.productService.save(this.productDto);

        // then
        assertNotNull(savedProductDto);
        assertEquals(this.productDto.getProductTitle(), savedProductDto.getProductTitle());
        verify(this.productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void deleteById_shouldCallRepositoryDelete() {
        // given
        final int productId = 1;
        when(this.productRepository.findById(productId)).thenReturn(Optional.of(this.product));
        doNothing().when(this.productRepository).delete(any(Product.class));

        // when
        this.productService.deleteById(productId);

        // then
        verify(this.productRepository, times(1)).findById(productId);
        verify(this.productRepository, times(1)).delete(any(Product.class));
    }

}
