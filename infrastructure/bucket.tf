resource "aws_s3_bucket" "blast_arena_bucket" {
  bucket = "blast-arena-bucket"
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

# Deshabilitar Block Public Access para permitir políticas públicas
resource "aws_s3_bucket_public_access_block" "blast_arena_bucket_public_access" {
  bucket = aws_s3_bucket.blast_arena_bucket.id
  block_public_acls   = false
  block_public_policy = false
}

# Definir la política pública del bucket
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

# Salida de la URL del sitio web
output "website_url" {
  value = aws_s3_bucket.blast_arena_bucket.website_endpoint
}