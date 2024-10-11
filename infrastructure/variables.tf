variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
}

variable "github_owner" {
  description = "pierre-garamendi"
  type        = string
}

variable "github_repo" {
  description = "blast-arena"
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket de S3"
  type        = string
  default     = "blast_arena_bucket"
}