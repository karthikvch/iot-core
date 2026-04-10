terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# IAM Role for Fleet Provisioning
# -----------------------------
resource "aws_iam_role" "iot_provisioning_role" {
  name = "iot_fleet_provisioning_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "iot.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "iot_provisioning_policy" {
  name = "iot_fleet_provisioning_policy"
  role = aws_iam_role.iot_provisioning_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:CreateThing",
          "iot:CreateKeysAndCertificate",
          "iot:AttachPolicy",
          "iot:AttachThingPrincipal"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# Device Policy (SECURE)
# -----------------------------
resource "aws_iot_policy" "device_policy" {
  name = var.device_policy_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      {
        Effect = "Allow",
        Action = "iot:Connect",
        Resource = "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:client/\${iot:Connection.Thing.ThingName}"
      },

      {
        Effect = "Allow",
        Action = "iot:Publish",
        Resource = "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topic/sensors/\${iot:Connection.Thing.ThingName}/data"
      },

      {
        Effect = "Allow",
        Action = "iot:Subscribe",
        Resource = "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topicfilter/sensors/\${iot:Connection.Thing.ThingName}/cmd"
      },

      {
        Effect = "Allow",
        Action = "iot:Receive",
        Resource = "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topic/sensors/\${iot:Connection.Thing.ThingName}/cmd"
      }
    ]
  })
}

# -----------------------------
# Fleet Provisioning Template
# -----------------------------
resource "aws_iot_provisioning_template" "fleet_template" {
  name = var.template_name

  provisioning_role_arn = aws_iam_role.iot_provisioning_role.arn
  enabled               = true

  template_body = jsonencode({
    Parameters = {
      ThingName = {
        Type = "String"
      }
    }

    Resources = {

      thing = {
        Type = "AWS::IoT::Thing"
        Properties = {
          ThingName = { Ref = "ThingName" }
        }
      },

      certificate = {
        Type = "AWS::IoT::Certificate"
        Properties = {
          Status = "ACTIVE"
        }
      },

      policy = {
        Type = "AWS::IoT::Policy"
        Properties = {
          PolicyName = var.device_policy_name
        }
      }
    }
  })
}

# -----------------------------
# Claim Certificate (Bootstrap)
# -----------------------------
resource "aws_iot_certificate" "claim_cert" {
  active = true
}

# -----------------------------
# Claim Policy (STRICT)
# -----------------------------
resource "aws_iot_policy" "claim_policy" {
  name = "claim_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      {
        Effect = "Allow",
        Action = "iot:Connect",
        Resource = "*"
      },

      {
        Effect = "Allow",
        Action = [
          "iot:Publish",
          "iot:Receive",
          "iot:Subscribe"
        ],
        Resource = [
          "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topic/$aws/certificates/create/*",
          "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topic/$aws/provisioning-templates/${var.template_name}/*",
          "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topicfilter/$aws/certificates/create/*",
          "arn:aws:iot:${var.aws_region}:ACCOUNT_ID:topicfilter/$aws/provisioning-templates/${var.template_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iot_policy_attachment" "claim_attach" {
  policy = aws_iot_policy.claim_policy.name
  target = aws_iot_certificate.claim_cert.arn
}

# -----------------------------
# Save certificates locally
# -----------------------------
resource "local_file" "claim_cert_file" {
  content  = aws_iot_certificate.claim_cert.certificate_pem
  filename = "${path.module}/certs/claim_certificate.pem.crt"
}

resource "local_file" "claim_private_key" {
  content  = aws_iot_certificate.claim_cert.private_key
  filename = "${path.module}/certs/claim_private.pem.key"
}

# -----------------------------
# Download Root CA
# -----------------------------
resource "null_resource" "download_root_ca" {
  provisioner "local-exec" {
    command = "mkdir -p certs && curl -s https://www.amazontrust.com/repository/AmazonRootCA1.pem -o certs/AmazonRootCA1.pem"
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "template_name" {
  value = aws_iot_provisioning_template.fleet_template.name
}

output "claim_certificate_path" {
  value = "${path.module}/certs/claim_certificate.pem.crt"
}

output "claim_private_key_path" {
  value = "${path.module}/certs/claim_private.pem.key"
}