resource "aws_dynamodb_table" "app-notifications_table" {
  name           = var.table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "app-notifications table"
    Environment = var.stage
  }
}
