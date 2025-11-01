package com.selimhorri.app.e2e;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

import com.selimhorri.app.utils.AuthTestUtils;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;

/**
 * End-to-End test for Complete Order Creation Flow
 *
 * This test simulates the complete order creation process:
 * 1. User adds products to cart
 * 2. User reviews cart
 * 3. User creates order from cart
 * 4. Order is confirmed and persisted
 *
 * Services involved: user-service, product-service, order-service
 *
 * Prerequisites:
 * - All services running
 * - User authenticated
 * - Products available in catalog
 */
@TestInstance(Lifecycle.PER_CLASS)
class OrderCreationE2ETest {

    private static final String BASE_URL = System.getProperty("test.base.url", 
            System.getenv().getOrDefault("API_URL", "http://localhost:80"));
    
    private String authToken;
    private Integer testUserId;

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
        // Authenticate once before all tests
        authToken = AuthTestUtils.authenticateAsTestUser();
        // Get the authenticated user's ID
        testUserId = AuthTestUtils.getTestUserId(authToken);
    }

    @Test
    void createCart_shouldReturnNewCart() {
        // For creating a cart, we need userId - using authenticated user's ID
        final String cartPayload = String.format("{\"userId\": %d}", testUserId);

        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(cartPayload)
        .when()
                .post("/app/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("cartId", notNullValue());
    }

    @Test
    void createOrderFromCart_shouldSucceed() {
        // Step 1: Create cart with userId
        final Integer cartId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"userId\": %d}", testUserId))
        .when()
                .post("/app/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("cartId");

        // Step 2: Create order from cart - include cart object with cartId
        final String orderPayload = String.format("""
                {
                    "orderDesc": "E2E Test Order",
                    "orderFee": 150.00,
                    "cart": {
                        "cartId": %d
                    }
                }
                """, cartId);

        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(orderPayload)
        .when()
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderId", notNullValue())
                .body("orderDesc", equalTo("E2E Test Order"))
                .body("orderFee", equalTo(150.00f));
    }

    @Test
    void getOrderById_shouldReturnOrderDetails() {
        // Step 1: Create cart with userId
        final Integer cartId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"userId\": %d}", testUserId))
        .when()
                .post("/app/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("cartId");

        // Step 2: Create order with cart
        final String orderPayload = String.format("""
                {
                    "orderDesc": "Retrieve Test Order",
                    "orderFee": 99.99,
                    "cart": {
                        "cartId": %d
                    }
                }
                """, cartId);

        final Integer orderId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(orderPayload)
        .when()
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 3: Retrieve order
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
        .when()
                .get("/app/api/orders/" + orderId)
        .then()
                .statusCode(200)
                .body("orderId", equalTo(orderId))
                .body("orderDesc", equalTo("Retrieve Test Order"))
                .body("orderFee", equalTo(99.99f));
    }

    @Test
    void getAllOrders_shouldReturnOrderList() {
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
        .when()
                .get("/app/api/orders")
        .then()
                .statusCode(200)
                .body("collection", not(empty()))
                .body("collection[0].orderId", notNullValue())
                .body("collection[0].orderDate", notNullValue());
    }
}
