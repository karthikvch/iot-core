provider "aws" {
  region = var.aws_region
}

# Create Thing
resource "aws_iot_thing" "device" {
  name = var.thing_name
}

/*
resource "aws_iot_thing" "device" {
  count = 10
  name  = "sensor-${count.index}"
}
👉 Creates:
sensor-0, sensor-1, sensor-2...
*/

# Create Certificate (ACTIVE)
resource "aws_iot_certificate" "cert" {
  active = true
}

# Create Policy
resource "aws_iot_policy" "policy" {
  name = "${var.thing_name}_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iot:*"
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Certificate
resource "aws_iot_policy_attachment" "policy_attach" {
  policy = aws_iot_policy.policy.name
  target = aws_iot_certificate.cert.arn
}

# Attach Certificate to Thing
resource "aws_iot_thing_principal_attachment" "thing_attach" {
  thing     = aws_iot_thing.device.name
  principal = aws_iot_certificate.cert.arn
}

# Output certificate and keys
output "certificate_pem" {
  value = aws_iot_certificate.cert.certificate_pem
  sensitive = true
}

output "private_key" {
  value     = aws_iot_certificate.cert.private_key
  sensitive = true
}

output "public_key" {
  value = aws_iot_certificate.cert.public_key
  sensitive = true
}
# 🔥 ADD BELOW THIS (at bottom)

resource "local_file" "cert" {
  content  = aws_iot_certificate.cert.certificate_pem
  filename = "${path.module}/certs/certificate.pem.crt"
}

resource "local_file" "private_key" {
  content  = aws_iot_certificate.cert.private_key
  filename = "${path.module}/certs/private.pem.key"
}