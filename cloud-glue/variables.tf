variable "lambda_src_file" {
  description = "file for script create metrics"
  type        = string
  default     = "handler.py"
}

variable "lambda_out_file" {
  description = "file for script create metrics output"
  type        = string
  default     = "handler.zip"
}

variable "glue_job_config_name" {
  description   = "Name glue job"
  type          = string 
  default       = "etl-logs"
}

variable "iam_arn_glue" {
  description   = "rol arn glue job"
  type          = string
  default       = ""
}

variable "s3_job_glue" {
  description   = "script job glue"
  type          = string
  default       = ""
}