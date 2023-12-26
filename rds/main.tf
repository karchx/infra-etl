provider "aws" {
  region = "us-gov-east-1"
}

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
    identifier = "postgres-db-processed-test"
    username = var.rd_username
    password = var.rd_pass
    db_name = "studio"
    storage_encrypted = true

    backup_retention_period = 7
    maintenance_window = "mon:16:34-mon:17:04"
    backup_window = "23:41-00:11"

    skip_final_snapshot = true // required to destroy
}

resource "aws_cloudwatch_event_rule" "custom_glue_job_metrics" {
  name        = var.glue_job_config_name
  event_pattern = jsonencode(
    {
      "detail-type" : ["Glue Job State Change"],
    }
  )
}

resource "aws_cloudwatch_event_target" "custom_glue_job_metrics" {
  target_id = "CustomGlueJobMetricsForProductData"
  rule      = aws_cloudwatch_event_rule.custom_glue_job_metrics.name
  arn       = aws_cloudwatch_event_rule.custom_glue_job_metrics.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 0
  }
}

resource "aws_iam_role" "custom_glue_job_metrics" {
  name = "studio-poc-glue-test"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
         {
          Effect : "Allow",
          Principal : {
            Service: "glue.amazonaws.com"
          },
          Action : "sts:AssumeRole"
        },
        {
            Effect: "Allow",
            Principal: {
                Service: "lambda.amazonaws.com"
            },
            Action: "sts:AssumeRole"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_glue_job_metrics" {
  role = aws_iam_role.custom_glue_job_metrics.id

  for_each = toset([
    "arn:aws-us-gov:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws-us-gov:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws-us-gov:iam::aws:policy/service-role/AWSGlueServiceRole"
  ])

  policy_arn = each.value
}

resource "aws_glue_job" "job_logs" {
  name  = var.glue_job_config_name
  # role_arn = var.iam_arn_glue
  role_arn  = aws_iam_role.custom_glue_job_metrics.arn
  command {
    name = "python3"
    script_location = var.s3_job_glue
  }

  default_arguments = {
    "--continuous-log-logGroup"          = "/aws/glue/jobs"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }
}

resource "aws_s3_bucket" "bucketone" {
    bucket = "mike-glue-test-tf"
}

resource "aws_s3_bucket" "buckettwo" {
    bucket = "mike-glue-test-processed-tf"
}

resource "aws_cloudwatch_metric_alarm" "job_failed" {
  alarm_name          = "JobFailed"
  metric_name         = "Failed"
  namespace           = "GlueBasicMetrics"
  period              = "300"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = "1"
  treat_missing_data  = "ignore"
  actions_enabled     = true

  dimensions = {
    JobName = var.glue_job_config_name
  }

  alarm_description = "Alarm glue job failed"
}


# Lambda notification S3
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = var.unzipped_lambda_dir
  output_path = var.zipped_lambda_dir
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_glue_job.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucketone.arn
}

resource "aws_lambda_function" "s3_trigger_glue_job" {
  filename      = var.zipped_lambda_dir
  function_name = var.lambda_function_name
  role          = aws_iam_role.custom_glue_job_metrics.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  timeout       = 90
}


resource "aws_s3_bucket_notification" "aws_lambda_trigger" {
  depends_on = [aws_lambda_function.s3_trigger_glue_job]
  bucket     = aws_s3_bucket.bucketone.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_glue_job.arn
    events              = ["s3:ObjectCreated:Put"]

  }
}