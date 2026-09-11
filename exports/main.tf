# exports/main.tf — Scheduled Exports

variable "export_worker_access_key_id" {
  type    = string
  default = "AKIA3H7QX2MPLEXAMPLE"
}

variable "export_worker_secret_access_key" {
  type      = string
  sensitive = true
  # value in shared-services.auto.tfvars
}

variable "analytics_publishable_key" {
  description = "Client-side key for the embedded analytics widget. Public by design."
  type        = string
  default     = "pk_live_4f9c2ab81de74c0e9b3a"
}

resource "aws_iam_role" "export_worker" {
  name = "export-worker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "export_worker" {
  role = aws_iam_role.export_worker.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:*",
        "rds-data:ExecuteStatement",
        "secretsmanager:GetSecretValue",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_s3_bucket" "export_staging" {
  bucket = "casebook-export-staging"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "export_staging" {
  bucket = aws_s3_bucket.export_staging.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "export_staging" {
  bucket                  = aws_s3_bucket.export_staging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "export_worker" {
  name              = "/casebook/export-worker"
  retention_in_days = 0
}

resource "aws_lambda_function" "export_worker" {
  function_name = "export-worker"
  role          = aws_iam_role.export_worker.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 900

  environment {
    variables = {
      LOG_LEVEL                 = "DEBUG"
      STAGING_BUCKET            = aws_s3_bucket.export_staging.id
      AWS_ACCESS_KEY_ID         = var.export_worker_access_key_id
      AWS_SECRET_ACCESS_KEY     = var.export_worker_secret_access_key
      ANALYTICS_PUBLISHABLE_KEY = var.analytics_publishable_key
    }
  }
}

resource "aws_apigatewayv2_route" "download" {
  api_id             = aws_apigatewayv2_api.downloads.id
  route_key          = "GET /exports/{token}"
  authorization_type = "NONE"
}
