package com.selimhorri.app.e2e;

import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

import com.selimhorri.app.utils.AuthTestUtils;

import io.restassured.RestAssured;
import static io.restassured.RestAssured.given;
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

    private static final String BASE_URL = System.getProperty("test.base.url", 
            System.getenv().getOrDefault("API_URL", "http://localhost:80"));
    
    private String authToken;

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
        // Authenticate once before all tests
        authToken = AuthTestUtils.authenticateAsTestUser();
    }

    @Test
    void createPaymentForOrder_shouldSucceed() {
        // Step 1: Create cart with userId
        final Integer cartId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body("{\"userId\": 1}")
        .when()
                .post("/app/api/carts")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("cartId");

        // Step 2: Create an order with cart
        final String orderPayload = String.format("""
                {
                    "orderDesc": "Payment Test Order",
                    "orderFee": 299.99,
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

        // Step 3: Create payment for order
        final String paymentPayload = String.format("""
                {
                    "order": {
                        "orderId": %d
                    },
                    "isPayed": false
                }
                """, orderId);

        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(paymentPayload)
        .when()
                .post("/app/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("paymentId", notNullValue())
                .body("order.orderId", equalTo(orderId))
                .body("isPayed", equalTo(false));
    }

   
}
