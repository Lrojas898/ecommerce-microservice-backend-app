package com.selimhorri.app.utils;

import io.restassured.response.Response;
import org.springframework.http.HttpStatus;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.notNullValue;

/**
 * Authentication utilities for E2E tests
 * Uses pre-existing users created by database migrations
 */
public class AuthTestUtils {
    
    // Pre-existing test user credentials (created by migration V12)
    public static final String TEST_USERNAME = "testuser";
    public static final String TEST_PASSWORD = "password123";
    
    public static final String ADMIN_USERNAME = "admin";
    public static final String ADMIN_PASSWORD = "password123";
    
    /**
     * Authenticate with pre-existing test user
     * @return JWT token for authenticated user
     */
    public static String authenticateAsTestUser() {
        return authenticate(TEST_USERNAME, TEST_PASSWORD);
    }
    
    /**
     * Authenticate with pre-existing admin user
     * @return JWT token for authenticated admin
     */
    public static String authenticateAsAdmin() {
        return authenticate(ADMIN_USERNAME, ADMIN_PASSWORD);
    }
    
    /**
     * Authenticate with custom credentials
     * @param username the username
     * @param password the password
     * @return JWT token
     */
    public static String authenticate(String username, String password) {
        String authPayload = String.format("""
                {
                    "username": "%s",
                    "password": "%s"
                }
                """, username, password);
                
        Response response = given()
                .contentType("application/json")
                .body(authPayload)
                .when()
                .post("/app/api/authenticate")
                .then()
                .statusCode(HttpStatus.OK.value())
                .body("jwtToken", notNullValue())
                .extract()
                .response();
                
        return response.path("jwtToken");
    }
    
    /**
     * Verify that pre-existing test user can authenticate
     * This is useful for health checks before running other tests
     */
    public static boolean verifyTestUserExists() {
        try {
            String token = authenticateAsTestUser();
            return token != null && !token.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Create authorization header with JWT token
     * @param token JWT token
     * @return Authorization header value  
     */
    public static String createAuthHeader(String token) {
        return "Bearer " + token;
    }
}