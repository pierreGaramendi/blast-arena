provider "aws" {
  region = "us-east-1"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "pierreGaramendi"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "blast-arena"
}

variable "bucket_name" {
  description = "Nombre del bucket de S3"
  type        = string
  default     = "blast-arena-bucket"
}

resource "aws_s3_bucket" "blast_arena_bucket" {
  bucket              = var.bucket_name
  object_lock_enabled = false
  tags = {
    Name = "My Blast Arena React Website"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.blast_arena_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "blast_arena_bucket_public_access" {
  bucket              = aws_s3_bucket.blast_arena_bucket.id
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "blast_arena_bucket_policy" {
  bucket = aws_s3_bucket.blast_arena_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.blast_arena_bucket.arn}/*"
      }
    ]
  })
}

# CodeBuild
resource "aws_codebuild_project" "react_build" {
  name         = "blast-arena-react-build"
  description  = "Builds the React application"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    #image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# CodePipeline
resource "aws_codepipeline" "react_pipeline" {
  name     = "blast-arena-react-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.react_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.blast_arena_bucket.id
        Extract    = "true"
      }
    }
  }
}

# IAM roles
resource "aws_iam_role" "codebuild_role" {
  name = "blast-arena-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/blast-arena-react-build",
          "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/blast-arena-react-build:*"
        ]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*",
          aws_s3_bucket.blast_arena_bucket.arn,
          "${aws_s3_bucket.blast_arena_bucket.arn}/*"
        ]
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
      },
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
        ]
      }
    ]
  })
}

# Obtener la identidad actual para usar en los ARNs
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codepipeline_role" {
  name = "blast-arena-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policies (you'll need to add the necessary permissions)
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "blast-arena-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*",
          aws_s3_bucket.blast_arena_bucket.arn,
          "${aws_s3_bucket.blast_arena_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      }
    ]
  })
}
# S3 bucket for storing pipeline artifacts
resource "aws_s3_bucket" "artifact_store" {
  bucket = "blast-arena-artifact-store"
}

output "website_url" {
  value = aws_s3_bucket.blast_arena_bucket.website_endpoint
}
