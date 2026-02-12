#####################################################################################
####################### CLOUDWATCH MONITORING FOR AD CONNECTOR ######################
#####################################################################################

# CloudWatch Alarm: Recursive DNS Queries (High volume may indicate issues)
resource "aws_cloudwatch_metric_alarm" "ad_connector_dns_queries" {
  alarm_name          = "ad-connector-high-dns-queries"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 # evaluate the metric over 2 periods
  metric_name         = "Recursive DNS Queries"
  namespace           = "AWS/DirectoryService"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 10000 # triggers if EACH of 2 consecutive 5-minute periods has more than 1000 DNS queries
  alarm_description   = "AD Connector is experiencing high DNS query volume"
  treat_missing_data  = "notBreaching"

  dimensions = {
    "Directory Id" = aws_directory_service_directory.ad_connector.id
  }

  tags = {
    Name        = "AD Connector DNS Queries Alarm"
    Environment = var.environment
  }
}

#####################################################################################
############### WORKSPACES VPC FLOW LOGS FOR VPC TRAFFIC MONITORING #################
#####################################################################################

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "workspaces_vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/workspaces-vpc"
  retention_in_days = 30
  tags = {
    Name        = "WorkSpaces VPC Flow Logs"
    Environment = var.environment
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "workspaces-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "VPC Flow Logs Role"
    Environment = var.environment
  }
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "workspaces-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs for WorkSpaces VPC
resource "aws_flow_log" "workspaces_vpc" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.workspaces_vpc_flow_logs.arn
  traffic_type    = "ALL" # Options: ACCEPT, REJECT, ALL
  vpc_id          = aws_vpc.workspaces.id

  tags = {
    Name        = "WorkSpaces VPC Flow Logs"
    Environment = var.environment
  }
}
