# ============================================================
# NGINX Ingress Controller
# ============================================================

resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = "ingress-nginx"

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/do-loadbalancer-name" = "${var.project_name}-${var.environment}-lb"
            "service.beta.kubernetes.io/do-loadbalancer-protocol" = "http"
            "service.beta.kubernetes.io/do-loadbalancer-healthcheck-port" = "10254"
            "service.beta.kubernetes.io/do-loadbalancer-healthcheck-path" = "/healthz"
          }
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
        resources = {
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }
    })
  ]

  timeout = 600

  depends_on = [var.cluster_dependency]
}

# ============================================================
# Cert-Manager for SSL Certificates
# ============================================================

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  timeout = 600

  depends_on = [var.cluster_dependency]
}

# ============================================================
# ClusterIssuer for Let's Encrypt (Production)
# ============================================================

resource "kubernetes_manifest" "letsencrypt_prod" {
  count = var.enable_cert_manager && var.letsencrypt_email != "" ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# ============================================================
# ClusterIssuer for Let's Encrypt (Staging - for testing)
# ============================================================

resource "kubernetes_manifest" "letsencrypt_staging" {
  count = var.enable_cert_manager && var.letsencrypt_email != "" ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# ============================================================
# Get LoadBalancer IP for DNS configuration
# ============================================================

data "kubernetes_service" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}
