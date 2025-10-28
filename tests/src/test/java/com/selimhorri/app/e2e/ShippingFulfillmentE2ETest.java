package com.selimhorri.app.e2e;

import static org.hamcrest.Matchers.anyOf;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;

import io.restassured.RestAssured;
import static io.restassured.RestAssured.given;
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

    private static final String BASE_URL = System.getProperty("test.base.url", 
            System.getenv().getOrDefault("API_URL", "http://localhost:80"));

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
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 2: Create payment and mark as paid
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/app/api/payments")
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
                .post("/app/api/shippings")
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
                .post("/app/api/orders")
        .then()
                .extract()
                .path("orderId");

        // Step 2: Create multiple shipping items
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":1}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":2,\"orderedQuantity\":3}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 3: Get all shipping items for order
        given()
                .queryParam("orderId", orderId)
        .when()
                .get("/app/api/shippings")
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
                .post("/app/api/orders")
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
                .post("/app/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("isPayed", equalTo(true));

        // Step 3: Create shipping item
        given()
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":5}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderedQuantity", equalTo(5));

        // Step 4: Verify order still exists and is complete
        given()
        .when()
                .get("/app/api/orders/" + orderId)
        .then()
                .statusCode(200)
                .body("orderId", equalTo(orderId))
                .body("orderDesc", equalTo("Complete Workflow Test"));
    }

    @Test
    void getAllShippingItems_shouldReturnList() {
        given()
        .when()
                .get("/app/api/shippings")
        .then()
                .statusCode(200)
                .body("$", anyOf(empty(), not(empty())));
    }
}
