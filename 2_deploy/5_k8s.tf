# ref
# https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider

data "aws_eks_cluster" "cluster" {
  depends_on = [aws_eks_cluster.app]
  name       = aws_eks_cluster.app.name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [aws_eks_cluster.app]
  name       = aws_eks_cluster.app.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_ecr_repository" "app" {
  name = "aws-demo"
}

data "aws_ecr_image" "app" {
  repository_name = data.aws_ecr_repository.app.name
  image_tag       = "latest"
}

resource "kubernetes_secret" "dbstring" {
  metadata {
    name = "dbstring"
  }
  data = {
    DB_CONN_STRING = "mongodb://aws-demo:aws-demo@${aws_instance.mongo-server.private_ip}:27017/aws-demo?retryWrites=true&w=majority"
  }
}

resource "kubernetes_deployment" "aws-demo-app" {
  depends_on = [aws_eks_cluster.app]
  metadata {
    name = "aws-demo-app"
    labels = {
      app = "aws-demo-app"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aws-demo-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "aws-demo-app"
        }
      }
      spec {
        container {
          name  = "aws-demo-app"
          image = data.aws_ecr_image.app.image_uri
          port {
            container_port = 443
          }
          env {
            name = "DB_CONN_STRING"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.dbstring.metadata[0].name
                key  = "DB_CONN_STRING"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "aws-demo-app" {
  metadata {
    name = "aws-demo-app"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "ssl"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"        = "443"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"           = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-subnets"          = "${aws_subnet.public1.id},${aws_subnet.public2.id}"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.aws-demo-app.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 443
      target_port = 443
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.aws-demo-app.spec
}