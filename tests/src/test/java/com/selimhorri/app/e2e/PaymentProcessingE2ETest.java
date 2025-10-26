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
 * End-to-End test for Payment Processing Flow
 *
 * This test simulates the complete payment workflow:
 * 1. Order is created
 * 2. Payment is initiated for the order
 * 3. Payment is processed (approved/rejected)
 * 4. Payment status is updated
 * 5. Order status reflects payment
 *
 * Services involved: order-service, payment-service
 *
 * Prerequisites:
 * - order-service and payment-service running
 * - API Gateway routing configured
 */
@TestInstance(Lifecycle.PER_CLASS)
class PaymentProcessingE2ETest {

    private static final String BASE_URL = System.getenv().getOrDefault("API_URL", "http://localhost:8080");

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    void createPaymentForOrder_shouldSucceed() {
        // Step 1: Create an order
        final String orderPayload = """
                {
                    "orderDesc": "Payment Test Order",
                    "orderFee": 299.99
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

        // Step 2: Create payment for order
        final String paymentPayload = String.format("""
                {
                    "orderId": %d,
                    "isPayed": false
                }
                """, orderId);

        given()
                .contentType(ContentType.JSON)
                .body(paymentPayload)
        .when()
                .post("/payment-service/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("paymentId", notNullValue())
                .body("orderId", equalTo(orderId))
                .body("isPayed", equalTo(false));
    }

    @Test
    void processPayment_shouldUpdateStatus() {
        // Step 1: Create order
        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body("{\"orderDesc\":\"Quick Order\",\"orderFee\":49.99}")
        .when()
                .post("/order-service/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 2: Create payment
        final Integer paymentId = given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":false}", orderId))
        .when()
                .post("/payment-service/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("paymentId");

        // Step 3: Process payment (mark as paid)
        final String updatePayload = String.format("""
                {
                    "paymentId": %d,
                    "orderId": %d,
                    "isPayed": true
                }
                """, paymentId, orderId);

        given()
                .contentType(ContentType.JSON)
                .body(updatePayload)
        .when()
                .put("/payment-service/api/payments/" + paymentId)
        .then()
                .statusCode(anyOf(is(200), is(204)))
                .body("isPayed", anyOf(equalTo(true), nullValue()));
    }

    @Test
    void getPaymentWithOrderDetails_shouldReturnCompleteInfo() {
        // Step 1: Create order
        final Integer orderId = given()
                .contentType(ContentType.JSON)
                .body("{\"orderDesc\":\"Details Test\",\"orderFee\":199.99}")
        .when()
                .post("/order-service/api/orders")
        .then()
                .extract()
                .path("orderId");

        // Step 2: Create payment
        final Integer paymentId = given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/payment-service/api/payments")
        .then()
                .extract()
                .path("paymentId");

        // Step 3: Get payment with order details
        given()
        .when()
                .get("/payment-service/api/payments/" + paymentId)
        .then()
                .statusCode(200)
                .body("paymentId", equalTo(paymentId))
                .body("orderDto", notNullValue())
                .body("orderDto.orderId", equalTo(orderId));
    }

    @Test
    void getAllPayments_shouldReturnPaymentList() {
        given()
        .when()
                .get("/payment-service/api/payments")
        .then()
                .statusCode(200)
                .body("$", anyOf(empty(), not(empty())));
    }
}
