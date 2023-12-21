resource "aws_db_instance" "postgres_db_test" {
    allocated_storage = 20
    engine = "postgres"
    engine_version = "15.5"
    instance_class = "db.t4g.small"
    identifier = "product-db-test"
    username = var.rd_username
    password = var.rd_pass
    db_name = "studio"
    storage_encrypted = true

    # vpc_security_group_ids = []

    backup_retention_period = 7
    maintenance_window = "tue:18:21-tue:18:51"
    backup_window = "21:34-22:04"

    skip_final_snapshot = true // required to destroy
}

resource "aws_db_instance" "postgres_db_processed_test" {
    allocated_storage = 20
    engine = "postgres"
    engine_version = "15.5"
    instance_class = "db.t4g.micro"
    identifier = "postgres_db_processed_test"
    username = var.rd_username
    password = var.rd_pass
    db_name = "studio"
    storage_encrypted = true

    # vpc_security_group_ids = []

    backup_retention_period = 7
    maintenance_window = "mon:16:34-mon:17-04"
    backup_window = "23:41-00:11"

    skip_final_snapshot = true // required to destroy
}