locals {
  helm_overrides_values = {
    # TFE image settings
    tfe_replica_count       = 1
    tfe_image_repository_url = "images.releases.hashicorp.com"
    tfe_image_name           = "hashicorp/terraform-enterprise"
    tfe_image_tag            = "v202409-1"

    # TFE config settings
    tfe_hostname = "tfe.hashicorp.local"

    # Database settings
    tfe_database_host       = "${data.kubernetes_secret.postgres.data.host}:${data.kubernetes_secret.postgres.data.port}"
    tfe_database_name       = "${data.kubernetes_secret.postgres.data.dbname}"
    tfe_database_user       = "${data.kubernetes_secret.postgres.data.user}"
    tfe_database_parameters = "sslmode=require"
    # Object storage settings
    tfe_object_storage_type                                 = "s3"
    tfe_object_storage_s3_bucket                            = data.kubernetes_resource.s3.object.spec.bucketName
    tfe_object_storage_s3_region                            = "us-east-1"
    tfe_object_storage_s3_endpoint                          = "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc"
    tfe_object_storage_s3_use_instance_profile              = false
    tfe_object_storage_s3_access_key_id                     = data.kubernetes_secret.s3.data.AWS_ACCESS_KEY_ID

    # Redis settings
    tfe_redis_host     = "redb.tfe.svc.cluster.local:12672"
    tfe_redis_use_auth = true
    tfe_redis_use_tls  = false
  }

  tfe_helm_values = templatefile("${path.module}/templates/helm_overrides_values.yaml.tpl", local.helm_overrides_values)
}

data "kubernetes_secret" "s3" {
  metadata {
    name = "tfeapp"
    namespace = "tfe"
  }
}


data "kubernetes_resource" "s3" {
  api_version = "objectbucket.io/v1alpha1"
  kind        = "ObjectBucketClaim"

  metadata {
    name      = "tfeapp"
    namespace = "tfe"
  }
}


data "kubernetes_secret" "postgres" {
  metadata {
    name = "tfedb-pguser-tfeadmin"
    namespace = "tfe"
  }
}

data "kubernetes_secret" "redis" {
  depends_on = [ kubernetes_manifest.redis-db ]
  metadata {
    name = "redb"
    namespace = "tfe"
  }
}

resource "kubernetes_secret" "tfe-secrets" {
  depends_on = [ kubernetes_manifest.s3bucket-tfeapp ]
  metadata {
    name = "tfe-secrets"
    namespace = "tfe"
  }

  data = {
    TFE_LICENSE: var.tfe_license
    TFE_ENCRYPTION_PASSWORD: var.tfe_encryption_password
    TFE_DATABASE_PASSWORD: "${data.kubernetes_secret.postgres.data.password}"
    TFE_REDIS_PASSWORD: data.kubernetes_secret.redis.data.password
    TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID: data.kubernetes_secret.s3.data.AWS_ACCESS_KEY_ID
    TFE_OBJECT_STORAGE_S3_SECRET_ACCESS_KEY: data.kubernetes_secret.s3.data.AWS_SECRET_ACCESS_KEY
  }

}
