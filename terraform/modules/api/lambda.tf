###################################
# app-notifications-api-authorizer lambda function
###################################

resource "aws_iam_role" "app-notifications-api-authorizer-invocation-role" {
  name = "${var.prefix}-app-notifications-api-authorizer-invocation-role-${var.stage}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "app-notifications-api-authorizer-invocation-policy" {
  name = "${var.prefix}-app-notifications-api-authorizer-invocation-policy-${var.stage}"
  role = aws_iam_role.app-notifications-api-authorizer-invocation-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.app-notifications-api-authorizer.arn}"
    }
  ]
}
EOF
}


# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "app-notifications-api-authorizer-role" {
  name = "${var.prefix}-app-notifications-api-authorizer-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "app-notifications-api-authorizer-policy" {
    name        = "${var.prefix}-app-notifications-api-authorizer-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "app-notifications-api-authorizer-attach" {
    role       = aws_iam_role.app-notifications-api-authorizer-role.name
    policy_arn = aws_iam_policy.app-notifications-api-authorizer-policy.arn
}

resource "aws_lambda_function" "app-notifications-api-authorizer" {
  function_name = "${var.prefix}-app-notifications-api-authorizer-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/api-authorizer.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/api-authorizer.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.app-notifications-api-authorizer-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.cognito_user_pool_id
    }
  }
}

###################################
# get-app-notifications lambda function
###################################

resource "aws_lambda_function" "get-app-notifications" {
  function_name = "${var.prefix}-get-app-notifications-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/get.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/get.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.get-app-notifications-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.app-notifications_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "get-app-notifications-role" {
  name = "${var.prefix}-get-app-notifications-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get-app-notifications-policy" {
    name        = "${var.prefix}-get-app-notifications-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:Scan"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.app-notifications_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get-app-notifications-attach" {
    role       = aws_iam_role.get-app-notifications-role.name
    policy_arn = aws_iam_policy.get-app-notifications-policy.arn
}

resource "aws_lambda_permission" "get-app-notifications-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-app-notifications.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.app-notifications-api.execution_arn}/*/*"
}

###################################
# create-app-notification function
###################################

resource "aws_lambda_function" "create-app-notification" {
  function_name = "${var.prefix}-create-app-notification-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/create.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/create.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.create-app-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.app-notifications_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "create-app-notification-role" {
  name = "${var.prefix}-create-app-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "create-app-notification-policy" {
    name        = "${var.prefix}-create-app-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:PutItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.app-notifications_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "create-app-notification-attach" {
    role       = aws_iam_role.create-app-notification-role.name
    policy_arn = aws_iam_policy.create-app-notification-policy.arn
}

resource "aws_lambda_permission" "create-app-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create-app-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.app-notifications-api.execution_arn}/*/*"
}


###################################
# get-app-notification-details function
###################################

resource "aws_lambda_function" "get-app-notification-details" {
  function_name = "${var.prefix}-get-app-notification-details-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/get-item.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/get-item.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.get-app-notification-details-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.app-notifications_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "get-app-notification-details-role" {
  name = "${var.prefix}-get-app-notification-details-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get-app-notification-details-policy" {
    name        = "${var.prefix}-get-app-notification-details-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:GetItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.app-notifications_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get-app-notification-details-attach" {
    role       = aws_iam_role.get-app-notification-details-role.name
    policy_arn = aws_iam_policy.get-app-notification-details-policy.arn
}

resource "aws_lambda_permission" "get-app-notification-details-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-app-notification-details.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.app-notifications-api.execution_arn}/*/*"
}


###################################
# delete-app-notification function
###################################

resource "aws_lambda_function" "delete-app-notification" {
  function_name = "${var.prefix}-delete-app-notification-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/delete.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/delete.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.delete-app-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.app-notifications_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "delete-app-notification-role" {
  name = "${var.prefix}-delete-app-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "delete-app-notification-policy" {
    name        = "${var.prefix}-delete-app-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:DeleteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.app-notifications_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "delete-app-notification-attach" {
    role       = aws_iam_role.delete-app-notification-role.name
    policy_arn = aws_iam_policy.delete-app-notification-policy.arn
}

resource "aws_lambda_permission" "delete-app-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete-app-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.app-notifications-api.execution_arn}/*/*"
}

###################################
# update-app-notification function
###################################

resource "aws_lambda_function" "update-app-notification" {
  function_name = "${var.prefix}-update-app-notification-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/update.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/update.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.update-app-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.app-notifications_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "update-app-notification-role" {
  name = "${var.prefix}-update-app-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "update-app-notification-policy" {
    name        = "${var.prefix}-update-app-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:UpdateItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.app-notifications_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "update-app-notification-attach" {
    role       = aws_iam_role.update-app-notification-role.name
    policy_arn = aws_iam_policy.update-app-notification-policy.arn
}

resource "aws_lambda_permission" "update-app-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-app-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.app-notifications-api.execution_arn}/*/*"
}