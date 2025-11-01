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

    private static final String BASE_URL = System.getenv().getOrDefault("API_URL", "http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com");

    private String authToken;
    private Integer testUserId;

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
        // Authenticate once for all tests
        authToken = AuthTestUtils.authenticateAsTestUser();
        testUserId = AuthTestUtils.getTestUserId(authToken);
    }

    @Test
    void createCart_shouldReturnNewCart() {
        final String cartPayload = String.format("""
                {
                    "userId": %d
                }
                """, testUserId);

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
        // Step 1: Create cart
        final Integer cartId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"userId\":%d}", testUserId))
        .when()
                .post("/app/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("cartId");

        // Step 2: Create order from cart
        final String orderPayload = String.format("""
                {
                    "userId": %d,
                    "cartId": %d,
                    "orderDesc": "E2E Test Order",
                    "orderFee": 150.00
                }
                """, testUserId, cartId);

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
        // Step 1: Create order
        final String orderPayload = String.format("""
                {
                    "userId": %d,
                    "orderDesc": "Retrieve Test Order",
                    "orderFee": 99.99
                }
                """, testUserId);

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

        // Step 2: Retrieve order
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
                .body("$", not(empty()))
                .body("[0].orderId", notNullValue())
                .body("[0].orderDate", notNullValue());
    }
}
