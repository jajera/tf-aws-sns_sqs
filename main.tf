variable "use_case" {
  default = "tf-aws-sns_sqs"
}

resource "aws_resourcegroups_group" "example" {
  name        = "tf-rg-example"
  description = "Resource group for example resources"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Owner",
          "Values": ["John Ajera"]
        },
        {
          "Key": "UseCase",
          "Values": ["${var.use_case}"]
        }
      ]
    }
    JSON
  }

  tags = {
    Name    = "tf-rg-example"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_sns_topic" "example" {
  name = "tf-sns-example"

  tags = {
    Name    = "tf-sns-example"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_sqs_queue" "example" {
  name                       = "tf-sqs-example"
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 60

  tags = {
    Name    = "tf-sqs-example"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_sns_topic_subscription" "example" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = aws_sns_topic.example.arn
  endpoint             = aws_sqs_queue.example.arn
}

resource "aws_sqs_queue_policy" "example" {
  queue_url = aws_sqs_queue.example.id
  policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.example.arn}"
      ],
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.example.arn}"
        }
      }
    }
  ]
}
EOF
}

resource "null_resource" "send_message" {
  provisioner "local-exec" {
    command = <<EOT
      aws sns publish --topic-arn "${aws_sns_topic.example.arn}" --message "Hello, Terraform!" || true
    EOT
  }
}
