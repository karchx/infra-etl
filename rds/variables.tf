variable "rd_username" {
  description = "username for rd postgres"
  type        = string
  default     = "root"
}

variable "rd_pass" {
  description = "password for rd postgres"
  type        = string
  default     = "root10O14"
}

variable "glue_job_config_name" {
  description = "config name job"
  type        = string
  default     = "Data_Studio_POC_Glue_Cloudwatch_Test"
}

variable "s3_job_glue" {
  description = "s3 path job glue"
  type        = string
  default     = "s3://aws-glue-assets-335282840374-us-gov-east-1/scripts/Data_Studio_POC_Glue_Cloudwatch.py"
}

variable "unzipped_lambda_dir" {
  type    = string
  default = "./scripts/"
}

variable "zipped_lambda_dir" {
  type    = string
  default = "./scripts/handler.zip"
}

variable "lambda_function_name" {
  type    = string
  default = "S3TriggerGlueJobProductDataTest"
}
