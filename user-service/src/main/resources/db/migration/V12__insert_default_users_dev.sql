-- Insert default users for development and testing
INSERT INTO users (first_name, last_name, image_url, email, phone) VALUES
('Selim', 'Horri', 'https://bootdey.com/img/Content/avatar/avatar1.png', 'selimhorri@example.com', '+21622125140'),
('Amine', 'Ladjimi', 'https://bootdey.com/img/Content/avatar/avatar2.png', 'amineladjimi@example.com', '+21622125141'), 
('Omar', 'Derouiche', 'https://bootdey.com/img/Content/avatar/avatar3.png', 'omarderouiche@example.com', '+21622125142'),
('Admin', 'User', 'https://bootdey.com/img/Content/avatar/avatar7.png', 'admin@ecommerce.com', '+21622125144'),
('Test', 'User', 'https://bootdey.com/img/Content/avatar/avatar5.png', 'test@example.com', '+21622125145')
ON CONFLICT (email) DO NOTHING;

-- Insert credentials with proper BCrypt hashes
-- Default password for development users: 'password123'
-- Test user password: 'Test123!' (using simplified hash for consistency in tests)
INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) VALUES
(1, 'selimhorri', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true),
(2, 'amineladjimi', '$2a$04$8D8OuqPbE4LhRckvtBAHrOmpeWmE92xNNVtyK8Z/lrJFjsImpjBkm', 'ROLE_USER', true, true, true, true),
(3, 'omarderouiche', '$2a$04$jelNGcF4wFHJirT5Pm7jPO8812QE/3tIWIs1DNnajS68iG4aKUqvS', 'ROLE_USER', true, true, true, true),
(4, 'admin', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_ADMIN', true, true, true, true),
(5, 'testuser', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true, true, true, true)
ON CONFLICT (username) DO NOTHING;