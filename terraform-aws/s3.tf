resource "aws_s3_bucket" "backup" {
  bucket        = var.s3_backup_bucket
  acl           = "private"
  force_destroy = var.delete_backup_bucket

  tags = {
    Name = "${var.es_cluster}-elk-backup"
  }
}
