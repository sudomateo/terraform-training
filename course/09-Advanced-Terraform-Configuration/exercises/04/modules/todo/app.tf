resource "aws_key_pair" "app" {
  key_name_prefix = "todo"
  public_key      = var.ssh_public_key
}

resource "aws_security_group" "app" {
  for_each    = local.apps
  name_prefix = "todo"
  description = "Security group for todo application."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "Todo application port."
    from_port       = each.value.port
    to_port         = each.value.port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Key" = each.key
  }
}

resource "aws_launch_template" "app" {
  for_each               = local.apps
  name_prefix            = "todo"
  description            = "Launch template for todo application."
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = each.value.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.app[each.key].id]
  update_default_version = true
  user_data = base64encode(templatefile("${path.module}/user_data.tmpl",
    {
      app_image   = each.value.image
      app_port    = each.value.port
      app_version = each.value.version
      db_host     = aws_db_instance.db.endpoint
      db_name     = var.db.name
      db_user     = var.db.user
      db_password = local.db_password
    }
  ))

  tags = {
    "Key" = each.key
  }
}

resource "aws_autoscaling_group" "app" {
  for_each            = local.apps
  name_prefix         = "todo"
  min_size            = 1
  max_size            = 1
  health_check_type   = "ELB"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.lb[each.key].arn]

  launch_template {
    id      = aws_launch_template.app[each.key].id
    version = aws_launch_template.app[each.key].latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Key"
    value               = each.key
    propagate_at_launch = true
  }
}
