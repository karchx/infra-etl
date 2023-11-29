terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_cloudwatch_event_rule" "custom_glue_job_metrics" {
  name        = var.glue_job_config_name
  description = "Create custom metrics from glue job events"

  state = "ENABLED"

  event_pattern = jsonencode(
    {
      "detail-type" : ["Glue Job State Change"],
    }
  )
}

resource "aws_cloudwatch_event_target" "custom_glue_job_metrics" {
  target_id = "CustomGlueJobMetrics"
  rule      = aws_cloudwatch_event_rule.custom_glue_job_metrics.name
  arn       = aws_lambda_function.custom_glue_job_metrics.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 0
  }
}

data "archive_file" "zip_handler" {
  type = "zip"
  source_dir  = "${path.module}/scripts/"
  output_path = "${path.module}/handler.zip"
}

resource "aws_lambda_function" "custom_glue_job_metrics" {
  function_name = "CustomGlueJobMetrics"

  filename         = "${path.module}/handler.zip" 
  role             = aws_iam_role.custom_glue_job_metrics.arn
  handler          = "app.handler.handler"
  runtime          = "python3.9"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_glue_job_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.custom_glue_job_metrics.arn
}

resource "aws_iam_role" "custom_glue_job_metrics" {
  name = "CustomGlueJobMetricsETL"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Principal : {
            Service : "lambda.amazonaws.com"
          },
          Action : "sts:AssumeRole"
        }
      ]
  })
}

resource "aws_iam_role_policy" "custom_glue_job_metrics" {
  name = "CustomGlueJobMetricsETL"
  role = aws_iam_role.custom_glue_job_metrics.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_glue_job" "job_logs" {
  name  = var.glue_job_config_name
  role_arn  = var.iam_arn_glue
  command {
    name = "pythonshell"
    script_location = var.s3_job_glue
  }

  default_arguments = {
    "--continuous-log-logGroup"          = "/aws/glue/jobs"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  } 
}
