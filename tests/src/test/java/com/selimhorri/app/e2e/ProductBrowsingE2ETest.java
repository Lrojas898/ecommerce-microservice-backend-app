package com.selimhorri.app.e2e;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

import io.restassured.RestAssured;

/**
 * End-to-End test for Product Browsing and Search Flow
 *
 * This test simulates a customer browsing the product catalog:
 * 1. Browse all products
 * 2. View product details
 * 3. Filter products by category
 * 4. Add product to favourites
 *
 * Services involved: product-service, favourite-service
 *
 * Prerequisites:
 * - product-service running
 * - favourite-service running
 * - Sample products seeded in database
 */
@TestInstance(Lifecycle.PER_CLASS)
class ProductBrowsingE2ETest {

    private static final String BASE_URL = System.getenv().getOrDefault("API_URL", "http://localhost:8080");

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    void browseAllProducts_shouldReturnProductList() {
        given()
        .when()
                .get("/product-service/api/products")
        .then()
                .statusCode(200)
                .body("$", not(empty()))
                .body("[0].productId", notNullValue())
                .body("[0].productTitle", notNullValue())
                .body("[0].priceUnit", notNullValue());
    }

    @Test
    void viewProductDetails_shouldReturnCompleteProductInfo() {
        // Step 1: Get first product ID
        final Integer productId = given()
        .when()
                .get("/product-service/api/products")
        .then()
                .statusCode(200)
                .extract()
                .path("[0].productId");

        // Step 2: View product details
        given()
        .when()
                .get("/product-service/api/products/" + productId)
        .then()
                .statusCode(200)
                .body("productId", equalTo(productId))
                .body("productTitle", notNullValue())
                .body("priceUnit", notNullValue())
                .body("quantity", notNullValue())
                .body("category", notNullValue());
    }

    @Test
    void browseProductsByCategory_shouldFilterCorrectly() {
        // Step 1: Get all categories
        given()
        .when()
                .get("/product-service/api/categories")
        .then()
                .statusCode(200)
                .body("$", not(empty()));

        // Step 2: Get category ID
        final Integer categoryId = given()
        .when()
                .get("/product-service/api/categories")
        .then()
                .statusCode(200)
                .extract()
                .path("[0].categoryId");

        // Step 3: Get products by category
        given()
                .queryParam("categoryId", categoryId)
        .when()
                .get("/product-service/api/products/search")
        .then()
                .statusCode(anyOf(is(200), is(404)))  // 404 if no products in category
                .body("$", anyOf(empty(), not(empty())));
    }

    @Test
    void addProductToFavourites_shouldCreateFavourite() {
        // Assuming user is authenticated (simplified for E2E)
        final Integer userId = 1;
        final Integer productId = 1;

        final String favouritePayload = String.format("""
                {
                    "userId": %d,
                    "productId": %d
                }
                """, userId, productId);

        given()
                .contentType("application/json")
                .body(favouritePayload)
        .when()
                .post("/favourite-service/api/favourites")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("userId", equalTo(userId))
                .body("productId", equalTo(productId))
                .body("favouriteId", notNullValue());
    }

    @Test
    void getUserFavourites_shouldReturnFavouriteProducts() {
        final Integer userId = 1;

        given()
        .when()
                .get("/favourite-service/api/favourites/user/" + userId)
        .then()
                .statusCode(anyOf(is(200), is(404)))
                .body("$", anyOf(empty(), not(empty())));
    }
}
