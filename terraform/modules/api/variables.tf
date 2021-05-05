variable "region" {
  default = "eu-west-1"
}

variable "stage" {
  default = "dev"
}

variable "prefix" {
  default = "seobooker"
}

variable "account_id" {
  default = "703387863451"
}

variable "api_name" {
  default = "app-notifications"
}

variable "table_name" {
  default = "app-notifications_table"
}

variable "cognito_user_pool_id" {
}

variable "runtime" {
  default = "nodejs12.x"
}
