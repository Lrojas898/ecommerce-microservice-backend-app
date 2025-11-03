-- Insert default users for development and testing  
-- Using higher user_id values to avoid conflicts with existing migrations (V2 uses IDs 1-4)
-- Note: We avoid specifying user_id and let the database auto-generate them to prevent conflicts

-- Insert new users with auto-generated IDs, checking by email to avoid duplicates
INSERT INTO users (first_name, last_name, image_url, email, phone) 
SELECT 'Admin', 'User', 'https://bootdey.com/img/Content/avatar/avatar7.png', 'admin@ecommerce.com', '+21622125144'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@ecommerce.com');

INSERT INTO users (first_name, last_name, image_url, email, phone) 
SELECT 'Test', 'User', 'https://bootdey.com/img/Content/avatar/avatar5.png', 'test@example.com', '+21622125145'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'test@example.com');

-- Insert credentials for new users using subqueries to get the correct user_id
-- Default password for all users: 'password123' (plain text, using NoOpPasswordEncoder)

-- Admin user credentials
INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired)
SELECT
    u.user_id,
    'admin',
    'password123',
    'ROLE_ADMIN',
    true, true, true, true
FROM users u
WHERE u.email = 'admin@ecommerce.com'
AND NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'admin');

-- Test user credentials
INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired)
SELECT
    u.user_id,
    'testuser',
    'password123',
    'ROLE_USER',
    true, true, true, true
FROM users u
WHERE u.email = 'test@example.com'
AND NOT EXISTS (SELECT 1 FROM credentials WHERE username = 'testuser');