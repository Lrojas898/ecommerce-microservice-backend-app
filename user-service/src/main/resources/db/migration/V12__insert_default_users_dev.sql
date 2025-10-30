-- Insert default users for development and testing
-- Using individual INSERT statements with exception handling for compatibility with H2 and PostgreSQL
INSERT INTO users (user_id, first_name, last_name, image_url, email, phone) 
SELECT 1, 'Selim', 'Horri', 'https://bootdey.com/img/Content/avatar/avatar1.png', 'selimhorri@example.com', '+21622125140'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'selimhorri@example.com');

INSERT INTO users (user_id, first_name, last_name, image_url, email, phone) 
SELECT 2, 'Amine', 'Ladjimi', 'https://bootdey.com/img/Content/avatar/avatar2.png', 'amineladjimi@example.com', '+21622125141'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'amineladjimi@example.com');

INSERT INTO users (user_id, first_name, last_name, image_url, email, phone) 
SELECT 3, 'Omar', 'Derouiche', 'https://bootdey.com/img/Content/avatar/avatar3.png', 'omarderouiche@example.com', '+21622125142'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'omarderouiche@example.com');

INSERT INTO users (user_id, first_name, last_name, image_url, email, phone) 
SELECT 4, 'Admin', 'User', 'https://bootdey.com/img/Content/avatar/avatar7.png', 'admin@ecommerce.com', '+21622125144'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@ecommerce.com');

INSERT INTO users (user_id, first_name, last_name, image_url, email, phone) 
SELECT 5, 'Test', 'User', 'https://bootdey.com/img/Content/avatar/avatar5.png', 'test@example.com', '+21622125145'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'test@example.com');

-- Insert credentials with proper BCrypt hashes
-- Default password for all users: 'password123' -> $2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO
INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) 
SELECT 1, 'selimhorri', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true
WHERE NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'selimhorri');

INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) 
SELECT 2, 'amineladjimi', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true
WHERE NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'amineladjimi');

INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) 
SELECT 3, 'omarderouiche', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true
WHERE NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'omarderouiche');

INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) 
SELECT 4, 'admin', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_ADMIN', true, true, true, true
WHERE NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'admin');

INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) 
SELECT 5, 'testuser', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true
WHERE NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'testuser');