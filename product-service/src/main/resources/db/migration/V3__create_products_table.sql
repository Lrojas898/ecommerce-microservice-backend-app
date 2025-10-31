
CREATE TABLE products (
	product_id SERIAL PRIMARY KEY,
	category_id INTEGER,
	product_title VARCHAR(255),
	image_url VARCHAR(255),
	sku VARCHAR(255),
	price_unit DECIMAL(7, 2),
	quantity INTEGER,
	created_at TIMESTAMP DEFAULT LOCALTIMESTAMP NOT NULL,
	updated_at TIMESTAMP
);

