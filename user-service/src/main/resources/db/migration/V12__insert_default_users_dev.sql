-- Insert default users for development
INSERT INTO users (first_name, last_name, image_url, email, phone) VALUES
('Selim', 'Horri', 'https://bootdey.com/img/Content/avatar/avatar1.png', 'selimhorri@example.com', '+21622125140'),
('Amine', 'Ladjimi', 'https://bootdey.com/img/Content/avatar/avatar2.png', 'amineladjimi@example.com', '+21622125141'), 
('Omar', 'Derouiche', 'https://bootdey.com/img/Content/avatar/avatar3.png', 'omarderouiche@example.com', '+21622125142'),
('Admin', 'User', 'https://bootdey.com/img/Content/avatar/avatar7.png', 'admin@ecommerce.com', '+21622125144')
ON CONFLICT (email) DO NOTHING;

-- Insert credentials with proper BCrypt hashes
-- Password for all users is 'password123'
INSERT INTO credentials (user_id, username, password, role, is_enabled, is_account_non_expired, is_account_non_locked, is_credentials_non_expired) VALUES
(1, 'selimhorri', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iIDp.aVl3jAzDlL5nJG.lGkbzaUu', 'ROLE_USER', true, true, true, true),
(2, 'amineladjimi', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iIDp.aVl3jAzDlL5nJG.lGkbzaUu', 'ROLE_USER', true, true, true, true),
(3, 'omarderouiche', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iIDp.aVl3jAzDlL5nJG.lGkbzaUu', 'ROLE_USER', true, true, true, true),
(4, 'admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iIDp.aVl3jAzDlL5nJG.lGkbzaUu', 'ROLE_ADMIN', true, true, true, true)
ON CONFLICT (username) DO NOTHING;