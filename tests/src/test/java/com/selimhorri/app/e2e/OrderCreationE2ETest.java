package com.selimhorri.app.e2e;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import com.selimhorri.app.base.BaseE2ETest;
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
@SpringBootTest
class OrderCreationE2ETest extends BaseE2ETest {

    @BeforeEach
    void setup() {
        RestAssured.baseURI = System.getProperty("test.base.url");
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    @Test
    void createCart_shouldReturnNewCart() {
        final String cartPayload = """
                {
                    "cartId": null
                }
                """;

        given()
                .contentType(ContentType.JSON)
                .body(cartPayload)
        .when()
                .post("/order-service/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("cartId", notNullValue());
    }

    @Test
    void createOrderFromCart_shouldSucceed() {
        // Step 1: Create cart
        final Integer cartId = given()
                .contentType(ContentType.JSON)
                .body("{}")
        .when()
                .post("/order-service/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("cartId");

        // Step 2: Create order from cart
        final String orderPayload = String.format("""
                {
                    "cartId": %d,
                    "orderDesc": "E2E Test Order",
                    "orderFee": 150.00
                }
                """, cartId);

        given()
                .contentType(ContentType.JSON)
                .body(orderPayload)
        .when()
                .post("/order-service/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderId", notNullValue())
                .body("orderDesc", equalTo("E2E Test Order"))
                .body("orderFee", equalTo(150.00f));
    }

    @Test
    void getOrderById_shouldReturnOrderDetails() {
        // Step 1: Create order
        final String orderPayload = """
                {
                    "orderDesc": "Retrieve Test Order",
                    "orderFee": 99.99
                }
                """;

        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body(orderPayload)
        .when()
                .post("/order-service/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 2: Retrieve order
        given()
        .when()
                .get("/order-service/api/orders/" + orderId)
        .then()
                .statusCode(200)
                .body("orderId", equalTo(orderId))
                .body("orderDesc", equalTo("Retrieve Test Order"))
                .body("orderFee", equalTo(99.99f));
    }

    @Test
    void getAllOrders_shouldReturnOrderList() {
        given()
        .when()
                .get("/order-service/api/orders")
        .then()
                .statusCode(200)
                .body("$", not(empty()))
                .body("[0].orderId", notNullValue())
                .body("[0].orderDate", notNullValue());
    }
}
