
CREATE TABLE verification_tokens (
	verification_token_id SERIAL PRIMARY KEY,
	credential_id INTEGER,
	verif_token VARCHAR(255),
	expire_date DATE,
	created_at TIMESTAMP DEFAULT LOCALTIMESTAMP NOT NULL,
	updated_at TIMESTAMP
);

