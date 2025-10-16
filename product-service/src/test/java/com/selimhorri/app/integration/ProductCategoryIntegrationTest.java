package com.selimhorri.app.integration;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

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

import com.selimhorri.app.domain.Category;
import com.selimhorri.app.domain.Product;
import com.selimhorri.app.repository.CategoryRepository;
import com.selimhorri.app.repository.ProductRepository;

/**
 * Integration test for Product and Category relationship
 * Tests the association between products and categories
 *
 * This test validates that product-service can:
 * - Create categories
 * - Associate products with categories
 * - Query products by category
 */
@Testcontainers
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class ProductCategoryIntegrationTest {

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
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @BeforeEach
    void setUp() {
        this.productRepository.deleteAll();
        this.categoryRepository.deleteAll();
    }

    @Test
    void createProductWithCategory_shouldLinkCorrectly() {
        // Arrange: Create category
        final Category category = Category.builder()
                .categoryTitle("Electronics")
                .build();
        final Category savedCategory = this.categoryRepository.save(category);

        // Create product linked to category
        final Product product = Product.builder()
                .productTitle("Laptop")
                .imageUrl("laptop.jpg")
                .sku("LAP-001")
                .priceUnit(999.99)
                .quantity(10)
                .category(savedCategory)
                .build();

        // Act
        final Product savedProduct = this.productRepository.save(product);

        // Assert
        assertThat(savedProduct).isNotNull();
        assertThat(savedProduct.getProductId()).isNotNull();
        assertThat(savedProduct.getCategory()).isNotNull();
        assertThat(savedProduct.getCategory().getCategoryId())
                .isEqualTo(savedCategory.getCategoryId());
        assertThat(savedProduct.getCategory().getCategoryTitle()).isEqualTo("Electronics");
    }

    @Test
    void findProductsByCategory_shouldReturnCorrectProducts() {
        // Arrange
        final Category electronics = this.categoryRepository.save(
                Category.builder().categoryTitle("Electronics").build());

        final Category clothing = this.categoryRepository.save(
                Category.builder().categoryTitle("Clothing").build());

        this.productRepository.save(Product.builder()
                .productTitle("Laptop")
                .sku("LAP-001")
                .priceUnit(999.99)
                .quantity(5)
                .category(electronics)
                .build());

        this.productRepository.save(Product.builder()
                .productTitle("Mouse")
                .sku("MOU-001")
                .priceUnit(29.99)
                .quantity(50)
                .category(electronics)
                .build());

        this.productRepository.save(Product.builder()
                .productTitle("T-Shirt")
                .sku("TSH-001")
                .priceUnit(19.99)
                .quantity(100)
                .category(clothing)
                .build());

        // Act
        final List<Product> electronicsProducts = this.productRepository.findAll().stream()
                .filter(p -> p.getCategory().getCategoryTitle().equals("Electronics"))
                .toList();

        // Assert
        assertThat(electronicsProducts).hasSize(2);
        assertThat(electronicsProducts).allMatch(
                p -> p.getCategory().getCategoryTitle().equals("Electronics"));
    }

    @Test
    void updateProductCategory_shouldReflectChanges() {
        // Arrange
        final Category oldCategory = this.categoryRepository.save(
                Category.builder().categoryTitle("Old Category").build());

        final Category newCategory = this.categoryRepository.save(
                Category.builder().categoryTitle("New Category").build());

        final Product product = this.productRepository.save(Product.builder()
                .productTitle("Test Product")
                .sku("TEST-001")
                .priceUnit(49.99)
                .quantity(20)
                .category(oldCategory)
                .build());

        // Act
        product.setCategory(newCategory);
        final Product updatedProduct = this.productRepository.save(product);

        // Assert
        assertThat(updatedProduct.getCategory().getCategoryTitle()).isEqualTo("New Category");
        assertThat(updatedProduct.getCategory().getCategoryId())
                .isEqualTo(newCategory.getCategoryId());
    }
}
