"""
Locust Performance Tests for E-Commerce Microservices
======================================================

This file contains load and stress tests for the e-commerce platform.

Tests included:
1. Product Service Load Test - Simulates users browsing products
2. Order Service Stress Test - Tests order creation under high load
3. User Authentication Load Test - Tests login/registration endpoints
4. Complete Purchase Flow - End-to-end user journey

Usage:
    # Run with web UI
    locust -f locustfile.py --host=http://localhost:8080

    # Run headless with 100 users, spawn rate 10/sec, run for 60 seconds
    locust -f locustfile.py --host=http://localhost:8080 \
           --users 100 --spawn-rate 10 --run-time 60s --headless

    # Run specific test class
    locust -f locustfile.py ProductServiceLoadTest \
           --host=http://localhost:8080 --users 50 --spawn-rate 5

Prerequisites:
    pip install locust
"""

import random
import json
from locust import HttpUser, task, between, SequentialTaskSet


class ProductServiceLoadTest(HttpUser):
    """
    Load test for Product Service

    Simulates users browsing the product catalog:
    - View all products
    - View product details
    - Browse categories
    - Search products

    Expected Response Times:
    - GET /products: < 500ms (p95)
    - GET /products/{id}: < 300ms (p95)
    - GET /categories: < 200ms (p95)
    """

    wait_time = between(1, 3)  # Users wait 1-3 seconds between requests

    @task(5)  # Weight 5 - most common action
    def browse_all_products(self):
        """View all products in the catalog"""
        with self.client.get("/app/api/products", catch_response=True, name="Browse Products") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

    @task(3)  # Weight 3
    def view_product_details(self):
        """View a specific product's details"""
        product_id = random.randint(1, 100)
        with self.client.get(f"/app/api/products/{product_id}",
                            catch_response=True,
                            name="View Product Details") as response:
            if response.status_code in [200, 404]:  # 404 is acceptable if product doesn't exist
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

    @task(2)  # Weight 2
    def browse_categories(self):
        """View all product categories"""
        with self.client.get("/app/api/categories",
                            catch_response=True,
                            name="Browse Categories") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

    @task(1)  # Weight 1 - less common
    def view_favourites(self):
        """View user favourites"""
        with self.client.get("/app/api/favourites",
                            catch_response=True,
                            name="View Favourites") as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")


class OrderServiceStressTest(HttpUser):
    """
    Stress test for Order Service

    Tests the system under high order creation load:
    - Create orders
    - Retrieve orders
    - View order details

    This simulates Black Friday / flash sale scenarios

    Expected Response Times:
    - POST /orders: < 1000ms (p95)
    - GET /orders: < 500ms (p95)
    - GET /orders/{id}: < 300ms (p95)
    """

    wait_time = between(0.5, 2)  # Faster pace for stress test

    @task(4)
    def create_order(self):
        """Create a new order"""
        # First create a cart
        cart_data = {"userId": random.randint(1, 100)}
        cart_response = self.client.post("/app/api/carts", json=cart_data)
        
        if cart_response.status_code in [200, 201]:
            cart_id = cart_response.json().get('cartId', random.randint(1, 1000))
            
            order_data = {
                "orderDesc": f"Stress Test Order {random.randint(1000, 9999)}",
                "orderFee": round(random.uniform(10.0, 500.0), 2),
                "cart": {"cartId": cart_id}
            }

            with self.client.post("/app/api/orders",
                                 json=order_data,
                                 catch_response=True,
                                 name="Create Order") as response:
                if response.status_code in [200, 201]:
                    response.success()
                else:
                    response.failure(f"Order creation failed: {response.status_code}")

    @task(2)
    def browse_orders(self):
        """View all orders"""
        with self.client.get("/app/api/orders",
                            catch_response=True,
                            name="Browse Orders") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

    @task(1)
    def view_order_details(self):
        """View specific order details"""
        order_id = random.randint(1, 1000)
        with self.client.get(f"/app/api/orders/{order_id}",
                            catch_response=True,
                            name="View Order Details") as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")


class UserAuthenticationLoadTest(HttpUser):
    """
    Load test for User Authentication

    Tests user registration and login under load:
    - User registration
    - User login
    - Profile retrieval

    Expected Response Times:
    - POST /register: < 1500ms (p95)
    - POST /login: < 800ms (p95)
    - GET /users/{id}: < 300ms (p95)
    """

    wait_time = between(2, 5)

    @task(3)
    def register_user(self):
        """Register a new user"""
        user_id = random.randint(10000, 99999)
        user_data = {
            "firstName": f"LoadTest{user_id}",
            "lastName": "User",
            "email": f"loadtest{user_id}@example.com",
            "phone": f"+1{random.randint(1000000000, 9999999999)}",
            "username": f"loadtest{user_id}",
            "password": "TestPass123!"
        }

        with self.client.post("/app/api/users",
                             json=user_data,
                             catch_response=True,
                             name="Register User") as response:
            if response.status_code in [200, 201, 409]:  # 409 = already exists
                response.success()
            else:
                response.failure(f"Registration failed: {response.status_code}")

    @task(5)
    def login_user(self):
        """Login with credentials"""
        login_data = {
            "username": f"loadtest{random.randint(10000, 99999)}",
            "password": "TestPass123!"
        }

        with self.client.post("/app/api/authenticate",
                             json=login_data,
                             catch_response=True,
                             name="User Login") as response:
            if response.status_code in [200, 401]:  # 401 = invalid credentials
                response.success()
            else:
                response.failure(f"Login failed: {response.status_code}")

    @task(2)
    def get_user_profile(self):
        """Retrieve user profile"""
        user_id = random.randint(1, 100)
        with self.client.get(f"/app/api/users/{user_id}",
                            catch_response=True,
                            name="Get User Profile") as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")


class CompletePurchaseFlow(SequentialTaskSet):
    """
    Sequential task set simulating a complete purchase flow:
    1. Browse products
    2. View product details
    3. Create cart
    4. Create order
    5. Create payment
    6. Create shipping item

    This represents a realistic user journey through the entire system.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.product_id = None
        self.cart_id = None
        self.order_id = None
        self.payment_id = None

    @task
    def browse_products(self):
        """Step 1: Browse products"""
        response = self.client.get("/app/api/products", name="1. Browse Products")
        if response.status_code == 200:
            self.product_id = random.randint(1, 50)

    @task
    def view_product(self):
        """Step 2: View product details"""
        if self.product_id:
            self.client.get(f"/app/api/products/{self.product_id}",
                          name="2. View Product Details")

    @task
    def create_cart(self):
        """Step 3: Create shopping cart"""
        response = self.client.post("/app/api/carts",
                                   json={"userId": random.randint(1, 100)},
                                   name="3. Create Cart")
        if response.status_code in [200, 201]:
            try:
                self.cart_id = response.json().get('cartId')
            except:
                self.cart_id = random.randint(1, 1000)

    @task
    def create_order(self):
        """Step 4: Create order"""
        order_data = {
            "orderDesc": "Complete Flow Test Order",
            "orderFee": round(random.uniform(50.0, 300.0), 2),
            "cart": {"cartId": self.cart_id if self.cart_id else random.randint(1, 1000)}
        }

        response = self.client.post("/app/api/orders",
                                   json=order_data,
                                   name="4. Create Order")
        if response.status_code in [200, 201]:
            try:
                self.order_id = response.json().get('orderId')
            except:
                self.order_id = random.randint(1, 10000)

    @task
    def create_payment(self):
        """Step 5: Process payment"""
        if self.order_id:
            payment_data = {
                "order": {"orderId": self.order_id},
                "isPayed": True
            }

            response = self.client.post("/app/api/payments",
                                       json=payment_data,
                                       name="5. Process Payment")
            if response.status_code in [200, 201]:
                try:
                    self.payment_id = response.json().get('paymentId')
                except:
                    self.payment_id = random.randint(1, 10000)

    @task
    def create_shipping(self):
        """Step 6: Create shipping item"""
        if self.order_id and self.product_id:
            shipping_data = {
                "orderId": self.order_id,
                "productId": self.product_id,
                "orderedQuantity": random.randint(1, 5)
            }

            self.client.post("/app/api/shippings",
                           json=shipping_data,
                           name="6. Create Shipping Item")

    @task
    def stop(self):
        """Complete the flow"""
        self.interrupt()


class ECommercePurchaseUser(HttpUser):
    """
    User that performs complete purchase flows
    """
    wait_time = between(3, 10)
    tasks = [CompletePurchaseFlow]


class MixedWorkloadUser(HttpUser):
    """
    Simulates realistic mixed workload with different user behaviors:
    - 60% browsing products
    - 20% creating orders
    - 15% authentication
    - 5% complete purchase flow
    """

    wait_time = between(1, 5)

    @task(12)  # 60%
    def browse_products(self):
        product_id = random.randint(1, 100)
        self.client.get(f"/app/api/products", name="Browse Products")
        if random.random() > 0.5:
            self.client.get(f"/app/api/products/{product_id}", name="View Product")

    @task(4)  # 20%
    def create_order(self):
        # Create cart first
        cart_response = self.client.post("/app/api/carts", json={"userId": random.randint(1, 100)})
        cart_id = cart_response.json().get('cartId', random.randint(1, 1000)) if cart_response.status_code in [200, 201] else random.randint(1, 1000)
        
        order_data = {
            "orderDesc": f"Mixed Workload Order {random.randint(1, 9999)}",
            "orderFee": round(random.uniform(20.0, 200.0), 2),
            "cart": {"cartId": cart_id}
        }
        self.client.post("/app/api/orders", json=order_data, name="Create Order")

    @task(3)  # 15%
    def user_auth(self):
        user_id = random.randint(1, 100)
        self.client.get(f"/app/api/users/{user_id}", name="Get User")

    @task(1)  # 5%
    def complete_purchase(self):
        # Simplified purchase flow
        product_id = random.randint(1, 50)
        self.client.get(f"/app/api/products/{product_id}")

        # Create cart
        cart_response = self.client.post("/app/api/carts", json={"userId": random.randint(1, 100)})
        cart_id = cart_response.json().get('cartId', random.randint(1, 1000)) if cart_response.status_code in [200, 201] else random.randint(1, 1000)

        order_response = self.client.post("/app/api/orders", json={
            "orderDesc": "Quick Purchase",
            "orderFee": 99.99,
            "cart": {"cartId": cart_id}
        })

        if order_response.status_code in [200, 201]:
            try:
                order_id = order_response.json().get('orderId', random.randint(1, 1000))
                self.client.post("/app/api/payments", json={
                    "order": {"orderId": order_id},
                    "isPayed": True
                })
            except:
                pass


if __name__ == "__main__":
    import os
    os.system("locust -f locustfile.py --host=http://localhost:8080")
