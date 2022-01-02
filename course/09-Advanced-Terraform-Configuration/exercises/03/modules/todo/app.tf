resource "aws_key_pair" "app" {
  key_name_prefix = "todo"
  public_key      = var.ssh_public_key
}

resource "aws_security_group" "app" {
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
    from_port       = var.app.port
    to_port         = var.app.port
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
}

resource "aws_launch_template" "app" {
  name_prefix            = "todo"
  description            = "Launch template for todo application."
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.app.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  update_default_version = true
  user_data = base64encode(templatefile("${path.module}/user_data.tmpl",
    {
      app_image   = var.app.image
      app_port    = var.app.port
      app_version = var.app.version
      db_host     = aws_db_instance.db.endpoint
      db_name     = var.db.name
      db_user     = var.db.user
      db_password = local.db_password
    }
  ))
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "todo"
  min_size            = 1
  max_size            = 1
  health_check_type   = "ELB"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.lb.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }
}
