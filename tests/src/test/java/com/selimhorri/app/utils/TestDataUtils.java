package com.selimhorri.app.utils;

import io.restassured.response.Response;
import org.springframework.http.HttpStatus;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.notNullValue;

public class TestDataUtils {
    
    public static Integer createTestUser() {
        String userPayload = """
                {
                    "username": "testuser",
                    "email": "test@example.com",
                    "password": "Test123!"
                }
                """;
                
        return given()
                .contentType("application/json")
                .body(userPayload)
                .when()
                .post("/app/api/users")
                .then()
                .statusCode(HttpStatus.CREATED.value())
                .body("userId", notNullValue())
                .extract()
                .path("userId");
    }
    
    public static Integer createTestProduct() {
        String productPayload = """
                {
                    "productName": "Test Product",
                    "description": "Product for E2E testing",
                    "price": 99.99,
                    "stockQuantity": 100
                }
                """;
                
        return given()
                .contentType("application/json")
                .body(productPayload)
                .when()
                .post("/app/api/products")
                .then()
                .statusCode(HttpStatus.CREATED.value())
                .body("productId", notNullValue())
                .extract()
                .path("productId");
    }
    
    public static void cleanupTestData(Integer userId, Integer productId) {
        if (userId != null) {
            given()
                .when()
                .delete("/app/api/users/" + userId)
                .then()
                .statusCode(HttpStatus.NO_CONTENT.value());
        }
        
        if (productId != null) {
            given()
                .when()
                .delete("/app/api/products/" + productId)
                .then()
                .statusCode(HttpStatus.NO_CONTENT.value());
        }
    }
    
    public static Response createOrder(Integer userId, Integer productId, int quantity) {
        String orderPayload = String.format("""
                {
                    "userId": %d,
                    "items": [
                        {
                            "productId": %d,
                            "quantity": %d
                        }
                    ]
                }
                """, userId, productId, quantity);
                
        return given()
                .contentType("application/json")
                .body(orderPayload)
                .when()
                .post("/app/api/orders")
                .then()
                .statusCode(HttpStatus.CREATED.value())
                .extract()
                .response();
    }
}