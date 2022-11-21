variable "identifier" {
  type        = string
  description = "Cluster identifier"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "writer_instance_type" {
  type        = string
  description = "Instance type of writers"
  default     = "db.t3.small"
}

variable "mysql_version" {
  type        = string
  description = "The mysql version to use"
  default     = "5.7.mysql_aurora.2.10.0"
}

variable "zones" {
  type        = list(string)
  description = "Availability zones"
}

variable "master_username" {
  type        = string
  description = "Username for master user"
}

variable "vpc" {
  type        = object({ id : string, cidr_block : string })
  description = "The VPC to create the cluster in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids where cluster should be located"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Store final snapshot or not when destroying database"
}

variable "cluster_parameters" {
  type        = map(string)
  default     = {}
  description = "cluster parameter group overrides"
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS key to use for encryption"
}

variable "enhanced_monitoring" {
  type        = bool
  default     = false
  description = "Enable enhanced monitor on the instance"
}

variable "reader_instance_type" {
  type        = string
  description = "Instance type of writers"
  default     = null
}

variable "performance_insights_retention_period" {
  default     = 7
  description = <<EOT
  Performance insights is enabled by default, not all instance types are supported: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_PerfInsights.Overview.Engines.html.
  Performance insights retention period in days, 7 days is free of charge. Read more here: https://aws.amazon.com/rds/performance-insights/pricing
EOT
}
