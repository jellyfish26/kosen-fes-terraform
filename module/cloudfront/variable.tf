variable "name" {
  default = "main"
}

variable "domain" {
}

variable "accept_ip" {
  default = ["0.0.0.0/1", "128.0.0.0/1"]
}

variable "accept_origin" {
  default = ["https://example.com"]
}

variable "cloudfront_headers" {
  default = []
}