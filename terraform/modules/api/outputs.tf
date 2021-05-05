output "api_base_url" {
  value = aws_api_gateway_deployment.app-notifications-api.invoke_url
}