provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  # name of the s3 bucket
  bucket = "tfur-state-20200404"

  # prevent accidental deletion of this bucket.
  # any attempt to destroy this resource will cause TF to exit with an error
  # if you really wanna delete, comment out the setting
  lifecycle {
    prevent_destroy = true
  }

  # enable versioning so that we can see the full revision history of the state files
  # every update to the file creates a new ver of the file
  versioning {
    enabled = true
  }

  # enable server-side encryption
  # all data written to the bucket will be encrypted
  # => secrets present in tfstate are encrypted
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# DynamoDB for locking
resource "aws_dynamodb_table" "tf_lock" {
  name = "tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}