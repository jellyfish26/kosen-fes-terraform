resource "aws_s3_bucket" "reversi_back_state" {
  bucket = "reversi-back-state-bucket"
  acl    = "private"

  tags = {
    Name = "reversi-back"
  }
}