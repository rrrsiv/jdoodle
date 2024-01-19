provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier = ["subnet-xxxxxxxxxxx"]  # Replace with your subnet ID

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete               = true
  wait_for_capacity_timeout  = "0"
  health_check_type          = "EC2"

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "example" {
  name = "example-lt"

  version = "$Latest"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }

  network_interfaces {
    network_interface_id = aws_network_interface.example.id
  }

  credit_specification {
    cpu_credits = "standard"
  }

  instance_market_options {
    market_type = "spot"
  }
}

resource "aws_network_interface" "example" {
  subnet_id = "subnet-xxxxxxxxxxx"  # Replace with your subnet ID
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5-minute load average"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Scale up when the 5-minute load average is greater than or equal to 75%"

  actions_enabled = true

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:example-scale-up-sns-topic"]
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5-minute load average"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Scale down when the 5-minute load average is less than or equal to 50%"

  actions_enabled = true

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:example-scale-down-sns-topic"]
}

resource "aws_cloudwatch_event_rule" "daily_refresh" {
  name                = "daily_refresh_rule"
  description         = "Trigger daily refresh at UTC 12am"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_refresh_target" {
  rule = aws_cloudwatch_event_rule.daily_refresh.name
  arn  = aws_autoscaling_group.example.arn
}

resource "aws_sns_topic" "scale_up_sns_topic" {
  name = "scale_up_sns_topic"
}

resource "aws_sns_topic" "scale_down_sns_topic" {
  name = "scale_down_sns_topic"
}
