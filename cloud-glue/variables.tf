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
