resource "aws_lb" "lb" {
  name_prefix     = "todo"
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_listener" "lb" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ingress_port
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      stickiness {
        duration = "60"
      }

      dynamic "target_group" {
        for_each = local.apps

        content {
          arn    = aws_lb_target_group.lb[target_group.key].arn
          weight = var.active_app == target_group.key ? 100 : 0
        }
      }
    }
  }
}

resource "aws_lb_target_group" "lb" {
  for_each    = local.apps
  name_prefix = "todo"
  target_type = "instance"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
  }

  tags = {
    "Key" = each.key
  }
}

resource "aws_security_group" "lb" {
  name_prefix = "lb"
  description = "Security group for load balancer."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP"
    from_port        = var.ingress_port
    to_port          = var.ingress_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
