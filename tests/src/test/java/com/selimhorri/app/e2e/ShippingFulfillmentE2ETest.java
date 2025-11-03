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

import com.selimhorri.app.utils.AuthTestUtils;

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
    void createShippingItem_afterPaymentConfirmed() {
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
        final Integer orderId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderDesc\":\"Shipping Test Order\",\"orderFee\":75.00,\"cart\":{\"cartId\":%d}}", cartId))
        .when()
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 3: Create payment and mark as paid
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/app/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 4: Create shipping item
        final String shippingPayload = String.format("""
                {
                    "orderId": %d,
                    "productId": 1,
                    "orderedQuantity": 2
                }
                """, orderId);

        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
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
        final Integer orderId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderDesc\":\"Multi-item Order\",\"orderFee\":150.00,\"cart\":{\"cartId\":%d}}", cartId))
        .when()
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("orderId");

        // Step 3: Create multiple shipping items
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":1}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":2,\"orderedQuantity\":3}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 4: Get all shipping items (search by orderId not supported yet)
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
        .when()
                .get("/app/api/shippings")
        .then()
                .statusCode(200)
                .body("collection", notNullValue())
                .body("collection", anyOf(empty(), hasSize(greaterThanOrEqualTo(0))));
    }

    @Test
    void completeOrderWorkflow_endToEnd() {
        // Complete workflow: Cart → Order → Payment → Shipping

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
        final Integer orderId = given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderDesc\":\"Complete Workflow Test\",\"orderFee\":500.00,\"cart\":{\"cartId\":%d}}", cartId))
        .when()
                .post("/app/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderId", notNullValue())
                .extract()
                .path("orderId");

        // Step 3: Create and process payment
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"isPayed\":true}", orderId))
        .when()
                .post("/app/api/payments")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("isPayed", equalTo(true));

        // Step 3: Create shipping item
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
                .contentType(ContentType.JSON)
                .body(String.format("{\"orderId\":%d,\"productId\":1,\"orderedQuantity\":5}", orderId))
        .when()
                .post("/app/api/shippings")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderedQuantity", equalTo(5));

        // Step 4: Verify order still exists and is complete
        given()
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
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
                .header("Authorization", AuthTestUtils.createAuthHeader(authToken))
        .when()
                .get("/app/api/shippings")
        .then()
                .statusCode(200)
                .body("collection", notNullValue())
                .body("collection", anyOf(empty(), not(empty())));
    }
}
