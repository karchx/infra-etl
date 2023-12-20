resource "aws_db_instance" "postgres_rd_test" {
    allocated_storage = 10
    engine = "aurora-postgresql"
    instance_class = "db.t3.micro"
    username = var.rd_username
    password = var.rd_pass
    skip_final_snapshot = true // required to destroy
}