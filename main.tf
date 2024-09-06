data "kubernetes_all_namespaces" "allns" {}

output "all-ns" {
  value = data.kubernetes_all_namespaces.allns.namespaces
}


locals {
  manifest = <<EOT
---
kind: Namespace
apiVersion: v1
metadata:
  name: postgres-operator
EOT

#get files in directory ${path.module}/manifests
namespace = yamldecode(file("${path.module}/manifests/postgres-operator-ns.yaml")

}




# resource "kubernetes_manifest" "namespace" {
#   manifest = provider::kubernetes::manifest_decode(  ))
# }

output "local-manifest" {
  value = local.namespace
  
}