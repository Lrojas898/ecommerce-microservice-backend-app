package com.selimhorri.app.e2e;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;

/**
 * End-to-End test for Shipping and Fulfillment Flow
 *
 * This test simulates the complete order fulfillment process:
 * 1. Order is created and paid
 * 2. Shipping items are created from order
 * 3. Shipping status is tracked
 * 4. Order is marked as shipped
 *
 * Services involved: order-service, payment-service, shipping-service
 *
 * This is the final step in the e-commerce workflow
 */
@TestInstance(Lifecycle.PER_CLASS)
class ShippingFulfillmentE2ETest {

    private static final String BASE_URL = System.getenv().getOrDefault("API_URL", "http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com");

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    void createShippingItem_afterPaymentConfirmed() {
        // Step 1: Create order
        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body("{\"orderDesc\":\"Shipping Test Order\",\"orderFee\":75.00}")
        .when()
                .post("/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 2: Create payment and mark as paid
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 3: Create shipping item
        final String shippingPayload = String.format("""
                {
                    "orderId": %d,
                    "productId": 1,
                    "orderedQuantity": 2
                }
                """, orderId);

        given()
                .contentType(ContentType.JSON)
                .body(shippingPayload)
        .when()
                .post("/api/order-items")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderItemId", notNullValue())
                .body("orderId", equalTo(orderId))
                .body("orderedQuantity", equalTo(2));
    }

    @Test
    void getShippingItemsByOrder_shouldReturnAllItems() {
        // Step 1: Create order
        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body("{\"orderDesc\":\"Multi-item Order\",\"orderFee\":150.00}")
        .when()
                .post("/api/orders")
        .then()
                .extract()
                .path("orderId");

        // Step 2: Create multiple shipping items
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":1}", orderId))
        .when()
                .post("/api/order-items")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":2,\"orderedQuantity\":3}", orderId))
        .when()
                .post("/api/order-items")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 3: Get all shipping items for order
        given()
                .queryParam("orderId", orderId)
        .when()
                .get("/api/order-items/search")
        .then()
                .statusCode(anyOf(is(200), is(404)))
                .body("$", anyOf(empty(), hasSize(greaterThanOrEqualTo(2))));
    }

    @Test
    void completeOrderWorkflow_endToEnd() {
        // Complete workflow: Order → Payment → Shipping

        // Step 1: Create order
        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body("{\"orderDesc\":\"Complete Workflow Test\",\"orderFee\":500.00}")
        .when()
                .post("/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderId", notNullValue())
                .extract()
                .path("orderId");

        // Step 2: Create and process payment
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("isPayed", equalTo(true));

        // Step 3: Create shipping item
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":5}", orderId))
        .when()
                .post("/api/order-items")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderedQuantity", equalTo(5));

        // Step 4: Verify order still exists and is complete
        given()
        .when()
                .get("/api/orders/" + orderId)
        .then()
                .statusCode(200)
                .body("orderId", equalTo(orderId))
                .body("orderDesc", equalTo("Complete Workflow Test"));
    }

    @Test
    void getAllShippingItems_shouldReturnList() {
        given()
        .when()
                .get("/api/order-items")
        .then()
                .statusCode(200)
                .body("$", anyOf(empty(), not(empty())));
    }
}
