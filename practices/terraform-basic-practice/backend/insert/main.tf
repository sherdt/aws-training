provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key # TODO
  secret_key = var.aws_credentials.secret_key # TODO
}

/*
  This creates a role for the lambda function.
  Then we can add the logging and eni policy to the role and add the role to the lambda function.
*/
resource "aws_iam_role" "this" {
  name = "${local.name}-iam-role"

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
  tags = local.default_tags
}

resource "aws_iam_policy" "lambda_logging" {
  name = "${local.name}-logging-policy"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# This policy is needed because we need to create the lambdas in our VP
resource "aws_iam_policy" "lambda_eni" {
  name = "${local.name}-eni-policy"
  path = "/"
  description = "IAM policy for creating ENI's from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
resource "aws_iam_role_policy_attachment" "lambda_eni" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_eni.arn
}

# Normaly you create a more restrictive security group
resource "aws_security_group" "allow_all" {
  name        = "${local.name}-node-security-group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_created.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_lambda_function" "insert_object" {
  filename = "${local.lambdaName}.zip"
  function_name = local.lambdaName
  role = aws_iam_role.this.arn
  handler = "${local.lambdaName}.handler"
  source_code_hash = data.archive_file.lambda_app.output_base64sha256
  runtime = "nodejs12.x"

  vpc_config {
    security_group_ids = [aws_security_group.allow_all.id]
    subnet_ids = data.terraform_remote_state.vpc.outputs.addition_subnet_ids
  }

  environment {
    variables = {
      DB_HOST = data.terraform_remote_state.database.outputs.database.address
      DB_PORT = data.terraform_remote_state.database.outputs.database.port
      DB = data.terraform_remote_state.database.outputs.database.name
      DB_USER = var.db_credentials.user
      DB_PW = var.db_credentials.pw
    }
  }

  tags = local.default_tags
}

# Zip's your lambda files. Don't forget to add *.zip to your gitignore.
data "archive_file" "lambda_app" {
  type = "zip"
  output_path = "${path.module}/${local.lambdaName}.zip"
  source_dir = "${path.module}/app"
}
