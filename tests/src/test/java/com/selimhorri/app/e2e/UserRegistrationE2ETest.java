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
 * End-to-End test for Complete User Registration Flow
 *
 * This test simulates a real user registration journey:
 * 1. User submits registration form
 * 2. User-service creates user record
 * 3. Credentials are created and linked
 * 4. User can login with new credentials
 *
 * Services involved: proxy-client, user-service
 *
 * Prerequisites:
 * - All microservices running (via Docker Compose or Kubernetes)
 * - API Gateway accessible at configured port
 */
@TestInstance(Lifecycle.PER_CLASS)
class UserRegistrationE2ETest {

    private static final String BASE_URL = System.getenv().getOrDefault("API_URL", "http://ab025653f4c6b47648ad4cb30e326c96-149903195.us-east-2.elb.amazonaws.com");

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    void completeUserRegistrationFlow_shouldSucceed() {
        // Step 1: Register new user
        final String registrationPayload = """
                {
                    "firstName": "E2E",
                    "lastName": "TestUser",
                    "email": "e2e.test@example.com",
                    "phone": "+1234567890",
                    "username": "e2etest",
                    "password": "SecurePass123!"
                }
                """;

        given()
                .contentType(ContentType.JSON)
                .body(registrationPayload)
        .when()
                .post("/user-service/api/users/register")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("firstName", equalTo("E2E"))
                .body("lastName", equalTo("TestUser"))
                .body("email", equalTo("e2e.test@example.com"))
                .body("userId", notNullValue());
    }

    @Test
    void userLogin_afterSuccessfulRegistration_shouldAuthenticate() {
        // Step 1: Register user
        final String registrationPayload = """
                {
                    "firstName": "Login",
                    "lastName": "Test",
                    "email": "login.test@example.com",
                    "phone": "+9876543210",
                    "username": "logintest",
                    "password": "Password123!"
                }
                """;

        given()
                .contentType(ContentType.JSON)
                .body(registrationPayload)
        .when()
                .post("/user-service/api/users/register")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // Step 2: Attempt login
        final String loginPayload = """
                {
                    "username": "logintest",
                    "password": "Password123!"
                }
                """;

        given()
                .contentType(ContentType.JSON)
                .body(loginPayload)
        .when()
                .post("/user-service/api/auth/login")
        .then()
                .statusCode(200)
                .body("token", notNullValue())
                .body("username", equalTo("logintest"));
    }

    @Test
    void getUserProfile_afterAuthentication_shouldReturnUserData() {
        // Step 1: Register
        final String registrationPayload = """
                {
                    "firstName": "Profile",
                    "lastName": "Test",
                    "email": "profile.test@example.com",
                    "phone": "+1122334455",
                    "username": "profiletest",
                    "password": "Profile123!"
                }
                """;

        final Integer userId = given()
                .contentType(ContentType.JSON)
                .body(registrationPayload)
        .when()
                .post("/user-service/api/users/register")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract()
                .path("userId");

        // Step 2: Login
        final String loginPayload = """
                {
                    "username": "profiletest",
                    "password": "Profile123!"
                }
                """;

        final String token = given()
                .contentType(ContentType.JSON)
                .body(loginPayload)
        .when()
                .post("/user-service/api/auth/login")
        .then()
                .statusCode(200)
                .extract()
                .path("token");

        // Step 3: Get user profile
        given()
                .header("Authorization", "Bearer " + token)
        .when()
                .get("/user-service/api/users/" + userId)
        .then()
                .statusCode(200)
                .body("firstName", equalTo("Profile"))
                .body("email", equalTo("profile.test@example.com"));
    }
}
