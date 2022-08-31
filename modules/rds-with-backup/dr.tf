# This file contains variables, resources, etc. used only when DR context is applied

provider "aws" {
  alias = "primary"
  region  = "us-east-1"
}

# By default, DR is not enabled
variable "dr_enabled" {
  default = false
}

variable "dr_event" {
  default = false
}

# In the DR context, this variable contains a map of all the primary deployment's outputs
variable "primary_remote_state" {
  default = null
  type = map(any)
}

