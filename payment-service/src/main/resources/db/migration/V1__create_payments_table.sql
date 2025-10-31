
CREATE TABLE payments (
	payment_id SERIAL PRIMARY KEY,
	order_id INTEGER,
	is_payed BOOLEAN,
	payment_status VARCHAR(255),
	created_at TIMESTAMP DEFAULT LOCALTIMESTAMP NOT NULL,
	updated_at TIMESTAMP
);

