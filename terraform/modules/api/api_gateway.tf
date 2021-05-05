resource "aws_api_gateway_rest_api" "app-notifications-api" {
  name        = "${var.prefix}-app-notifications-api-${var.stage}"
  description = "${var.prefix}-app-notifications-api-${var.stage}"
  body = file("../../../swagger/${var.stage}/swagger.yaml")
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "app-notifications-api" {
  rest_api_id = aws_api_gateway_rest_api.app-notifications-api.id
  stage_name  = var.stage

  stage_description = md5(file("../../../swagger/${var.stage}/swagger.yaml"))
  
  depends_on = [aws_api_gateway_rest_api.app-notifications-api]
}