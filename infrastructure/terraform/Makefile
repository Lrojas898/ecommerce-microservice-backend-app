# Makefile for Terraform Infrastructure Management
# Usage: make <target>

.PHONY: help init plan apply destroy validate fmt clean

# Default target
.DEFAULT_GOAL := help

# Variables
TF_VARS_FILE := terraform.tfvars

help: ## Show this help message
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║     E-Commerce Microservices - Terraform Management          ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make init          # Initialize Terraform"
	@echo "  make plan          # Preview changes"
	@echo "  make apply         # Apply infrastructure"
	@echo "  make destroy       # Destroy infrastructure (⚠️  use with caution!)"
	@echo ""

check-vars: ## Check if terraform.tfvars exists
	@if [ ! -f $(TF_VARS_FILE) ]; then \
		echo "❌ Error: $(TF_VARS_FILE) not found!"; \
		echo ""; \
		echo "Please create it from the example:"; \
		echo "  cp terraform.tfvars.example terraform.tfvars"; \
		echo "  vi terraform.tfvars"; \
		echo ""; \
		exit 1; \
	fi
	@echo "✅ terraform.tfvars found"

init: check-vars ## Initialize Terraform
	@echo "🔧 Initializing Terraform..."
	terraform init
	@echo "✅ Terraform initialized successfully"

validate: ## Validate Terraform configuration
	@echo "🔍 Validating Terraform configuration..."
	terraform validate
	@echo "✅ Configuration is valid"

fmt: ## Format Terraform files
	@echo "📝 Formatting Terraform files..."
	terraform fmt -recursive
	@echo "✅ Files formatted"

plan: check-vars validate ## Preview infrastructure changes
	@echo "📋 Planning infrastructure changes..."
	terraform plan -var-file=$(TF_VARS_FILE) -out=tfplan
	@echo ""
	@echo "✅ Plan generated successfully"
	@echo "💡 Run 'make apply' to apply these changes"

apply: check-vars ## Apply infrastructure changes
	@echo "🚀 Applying infrastructure changes..."
	@echo "⚠️  This will create real resources and may incur costs!"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform apply -var-file=$(TF_VARS_FILE); \
		echo ""; \
		echo "✅ Infrastructure applied successfully!"; \
		echo ""; \
		echo "Next steps:"; \
		echo "  make output         # View all outputs"; \
		echo "  make kubeconfig     # Save kubeconfig"; \
		echo "  make show-ip        # Show LoadBalancer IP"; \
	else \
		echo "❌ Apply cancelled"; \
	fi

apply-auto: check-vars ## Apply infrastructure changes without confirmation (use in CI/CD)
	@echo "🚀 Applying infrastructure changes (auto-approved)..."
	terraform apply -var-file=$(TF_VARS_FILE) -auto-approve

destroy: ## Destroy infrastructure (⚠️  use with caution!)
	@echo "💣 WARNING: This will destroy ALL infrastructure!"
	@echo "⚠️  This action cannot be undone!"
	@echo ""
	@read -p "Type 'destroy' to confirm: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		terraform destroy -var-file=$(TF_VARS_FILE); \
		echo ""; \
		echo "✅ Infrastructure destroyed"; \
	else \
		echo "❌ Destroy cancelled"; \
	fi

output: ## Show Terraform outputs
	@echo "📤 Terraform Outputs:"
	@echo ""
	@terraform output

show-ip: ## Show LoadBalancer IP
	@echo "🌐 LoadBalancer IP Address:"
	@terraform output loadbalancer_ip

kubeconfig: ## Save kubeconfig to file
	@echo "💾 Saving kubeconfig..."
	@terraform output -raw kubeconfig > kubeconfig.yaml
	@echo "✅ Kubeconfig saved to: kubeconfig.yaml"
	@echo ""
	@echo "To use it:"
	@echo "  export KUBECONFIG=$$PWD/kubeconfig.yaml"
	@echo "  kubectl cluster-info"

connect: kubeconfig ## Configure kubectl to use the cluster
	@echo "🔌 Connecting kubectl to cluster..."
	@export KUBECONFIG=$$PWD/kubeconfig.yaml && \
	echo "✅ Kubeconfig configured" && \
	echo "" && \
	echo "Cluster info:" && \
	kubectl cluster-info && \
	echo "" && \
	echo "Nodes:" && \
	kubectl get nodes

verify: ## Verify cluster is healthy
	@echo "🏥 Verifying cluster health..."
	@kubectl get nodes
	@echo ""
	@kubectl get namespaces
	@echo ""
	@kubectl get pods -A
	@echo ""
	@echo "✅ Cluster verification complete"

cost: ## Estimate monthly cost
	@echo "💰 Estimated Monthly Cost:"
	@terraform output infrastructure_summary | grep "estimated_cost"

clean: ## Clean Terraform files (keeps state)
	@echo "🧹 Cleaning Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f tfplan
	rm -f kubeconfig.yaml
	@echo "✅ Cleaned (state files preserved)"

clean-all: ## Clean all Terraform files including state (⚠️  dangerous!)
	@echo "💣 WARNING: This will delete ALL Terraform files including state!"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		rm -rf .terraform terraform.tfstate* .terraform.lock.hcl tfplan kubeconfig.yaml; \
		echo "✅ All files cleaned"; \
	else \
		echo "❌ Clean cancelled"; \
	fi

upgrade: ## Upgrade Terraform providers
	@echo "⬆️  Upgrading Terraform providers..."
	terraform init -upgrade
	@echo "✅ Providers upgraded"

graph: ## Generate infrastructure graph
	@echo "📊 Generating infrastructure graph..."
	terraform graph | dot -Tpng > infrastructure-graph.png
	@echo "✅ Graph saved to: infrastructure-graph.png"

docs: ## Generate Terraform documentation
	@echo "📚 Generating Terraform documentation..."
	@echo "Install terraform-docs: brew install terraform-docs"
	terraform-docs markdown table . > TERRAFORM_DOCS.md
	@echo "✅ Documentation generated: TERRAFORM_DOCS.md"
