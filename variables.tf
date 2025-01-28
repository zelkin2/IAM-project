variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "current_developer_users"{
type = list(string)
default = ["developer-1", "developer-2"]
}

variable "current_operations_users"{
type = list(string)
default = ["operations-1", "operations-2"]
}

variable "current_analyst_users"{
type = list(string)
default = ["analyst-1", "analyst-2"]
}

variable "current_finance_users"{
type = list(string)
default = ["finance-1"]
}

