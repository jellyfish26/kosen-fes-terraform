resource "aws_s3_bucket" "reversi_back_state" {
  bucket = "reversi-back-state-bucket"
  acl    = "private"

  tags = {
    Name = "reversi-back"
  }
}

resource "aws_s3_bucket" "clicker_back_state" {
  bucket = "clicker-back-state-bucket"
  acl    = "private"

  tags = {
    Name = "clicker-back"
  }
}

resource "aws_s3_bucket" "lottery_back_state" {
  bucket = "lottery-back-state-bucket"
  acl    = "private"

  tags = {
    Name = "lottery-back"
  }
}