
CREATE TABLE address (
	address_id SERIAL PRIMARY KEY,
	user_id INTEGER,
	full_address VARCHAR(255),
	postal_code VARCHAR(255),
	city VARCHAR(255),
	created_at TIMESTAMP DEFAULT LOCALTIMESTAMP NOT NULL,
	updated_at TIMESTAMP
);


