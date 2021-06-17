// Build S3 bucket

resource "aws_s3_bucket" "coal-bucket2"{
  bucket = "coal-bucket2"
  acl    = "private"

lifecycle_rule {
    id      = "image archive"
    enabled = true

    prefix = "images/"

    tags = {
      rule = "images/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

  }
lifecycle_rule {
    id      = "logs"
    enabled = true

    prefix = "logs/"

    tags = {
      rule = "logs/"
    }

    expiration {
      days = 90
    }
  }

}

resource "aws_s3_bucket_object" "s3-images" {
  bucket = "${aws_s3_bucket.coal-bucket2.id}"
  acl    = "private"
  key    = "images/"

}


resource "aws_s3_bucket_object" "s3-logs" {
  bucket = "${aws_s3_bucket.coal-bucket2.id}"
  acl    = "private"
  key    = "logs/"

}

