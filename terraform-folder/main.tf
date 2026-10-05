
provider "aws" {
  region = "eu-north-1"
}

## S3 bucket config

resource "random_id" "bucket_suffix" {
  byte_length = 4 
}

resource "aws_kms_key" "job_market_intelligence_platform_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "job_market_intelligence_platform_bucket" {
  bucket = "my-job-market-intelligence-platform-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "my bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expiration" {
    bucket = aws_s3_bucket.job_market_intelligence_platform_bucket.id

    rule { 
        filter {}
        id = "expire-objects"
        status = "Enabled"
        expiration {
            days = 30
        }
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    bucket = aws_s3_bucket.job_market_intelligence_platform_bucket.id

    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = aws_kms_key.job_market_intelligence_platform_key.arn
            sse_algorithm     = "aws:kms"
        }
        bucket_key_enabled       = true
        blocked_encryption_types = ["SSE-C"]
    }
}

data "aws_availability_zones" "available" {
  state = "available"
}


## VPC Config

resource "aws_vpc" "redshift_vpc" {
    tags = {
        Name = "redshift-vpc"
    }
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
}


resource "aws_route" "route" {
  route_table_id         = aws_vpc.redshift_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "internet-gateway-for-custom-vpc"
  }
}

resource "aws_security_group" "redshift_security_group" {
  name = "redshift-security-group"
  description = "Security group for Redshift database"
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "redshift-security-group"
  }
}
resource "aws_vpc_security_group_ingress_rule" "redshift_security_group_ingress_rule" {
  security_group_id = aws_security_group.redshift_security_group.id
  description       = "Allow Redshift"
  from_port         = 5439
  to_port           = 5439
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip_cidr

  tags = {
    Name = "allow-redshift"
  }
}

resource "aws_subnet" "redshift_subnet" {
  vpc_id = aws_vpc.redshift_vpc.id
  count = 3
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 1)
  tags = {
        Name = "redshift-subnet-${count.index + 1}"
    }
  availability_zone = data.aws_availability_zones.available.names[count.index]
}


## Redshift Severless Config

resource "aws_redshiftserverless_namespace" "redshift_namespace" {
    namespace_name = var.my_namespace_name
    db_name = var.my_db_name
    admin_username = var.my_admin_username
    admin_user_password = var.my_admin_user_password
    default_iam_role_arn = aws_iam_role.redshift_role.arn
    iam_roles = [aws_iam_role.redshift_role.arn]
}


## IAM Role

resource "aws_iam_role" "redshift_role" {
  name = "redshift-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "S3_policy_Redshift" {
  name = "test-policy-redshift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.job_market_intelligence_platform_bucket.arn}/*",
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.job_market_intelligence_platform_bucket.arn}"
        ]
      },
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Effect   = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_role_policy" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.S3_policy_Redshift.arn
}


resource "aws_redshiftserverless_workgroup" "redshift_workgroup" {
  namespace_name = aws_redshiftserverless_namespace.redshift_namespace.namespace_name
  workgroup_name = "redshift-workgroup"
  base_capacity = 8
  subnet_ids = aws_subnet.redshift_subnet[*].id
  security_group_ids = [
    aws_security_group.redshift_security_group.id
  ]
  publicly_accessible = true
}
