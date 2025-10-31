package com.selimhorri.app.e2e;

import com.selimhorri.app.utils.AuthTestUtils;
import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.springframework.http.HttpStatus;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

/**
 * E2E Tests for default user authentication
 * Verifies that pre-existing users can authenticate successfully
 *
 * Prerequisites:
 * - Database migrations executed (especially V12)
 * - user-service running and accessible
 * - proxy-client running and accessible
 */
@TestInstance(Lifecycle.PER_CLASS)
class DefaultUserAuthenticationE2ETest {

    private static final String BASE_URL = System.getProperty("test.base.url",
            System.getenv().getOrDefault("API_URL", "http://localhost:80"));

    @BeforeAll
    void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    @DisplayName("Test user should authenticate successfully")
    void testUser_shouldAuthenticate() {
        String authPayload = String.format("""
                {
                    "username": "%s",
                    "password": "%s"
                }
                """, AuthTestUtils.TEST_USERNAME, AuthTestUtils.TEST_PASSWORD);

        given()
                .contentType("application/json")
                .body(authPayload)
                .when()
                .post("/app/api/authenticate")
                .then()
                .statusCode(HttpStatus.OK.value())
                .body("jwtToken", notNullValue())
                .body("jwtToken", not(emptyString()));
    }

    @Test
    @DisplayName("Admin user should authenticate successfully")
    void adminUser_shouldAuthenticate() {
        String authPayload = String.format("""
                {
                    "username": "%s",
                    "password": "%s"
                }
                """, AuthTestUtils.ADMIN_USERNAME, AuthTestUtils.ADMIN_PASSWORD);

        given()
                .contentType("application/json")
                .body(authPayload)
                .when()
                .post("/app/api/authenticate")
                .then()
                .statusCode(HttpStatus.OK.value())
                .body("jwtToken", notNullValue())
                .body("jwtToken", not(emptyString()));
    }

    @Test
    @DisplayName("Invalid credentials should return 401")
    void invalidCredentials_shouldReturn401() {
        String authPayload = """
                {
                    "username": "nonexistent",
                    "password": "wrongpass"
                }
                """;

        given()
                .contentType("application/json")  
                .body(authPayload)
                .when()
                .post("/app/api/authenticate")
                .then()
                .statusCode(HttpStatus.UNAUTHORIZED.value());
    }
    
    @Test
    @DisplayName("All default users should exist and authenticate")
    void allDefaultUsers_shouldAuthenticate() {
        // Test default development users
        String[][] defaultUsers = {
            {"selimhorri", "password123"},
            {"amineladjimi", "password123"}, 
            {"omarderouiche", "password123"},
            {"admin", "password123"},
            {"testuser", "password123"}
        };
        
        for (String[] user : defaultUsers) {
            String username = user[0];
            String password = user[1];
            
            String authPayload = String.format("""
                    {
                        "username": "%s",
                        "password": "%s"
                    }
                    """, username, password);

            given()
                    .contentType("application/json")
                    .body(authPayload)
                    .when()
                    .post("/app/api/authenticate")
                    .then()
                    .statusCode(HttpStatus.OK.value())
                    .body("jwtToken", notNullValue())
                    .body("jwtToken", not(emptyString()));
        }
    }

    @Test
    @DisplayName("AuthTestUtils should work correctly")
    void authTestUtils_shouldWork() {
        // Test utility methods
        String testUserToken = AuthTestUtils.authenticateAsTestUser();
        String adminToken = AuthTestUtils.authenticateAsAdmin();
        
        // Verify tokens are not null or empty
        assert testUserToken != null && !testUserToken.isEmpty();
        assert adminToken != null && !adminToken.isEmpty();
        
        // Verify tokens are different (different users)
        assert !testUserToken.equals(adminToken);
        
        // Verify test user exists check
        assert AuthTestUtils.verifyTestUserExists();
    }
}