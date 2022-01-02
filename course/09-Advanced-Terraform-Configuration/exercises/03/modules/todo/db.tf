resource "random_password" "db" {
  count   = var.db.password == "" ? 1 : 0
  length  = 16
  special = false
}

resource "aws_db_instance" "db" {
  identifier_prefix      = "todo"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = var.db.instance_class
  db_name                = var.db.name
  username               = var.db.user
  password               = local.db_password
  allocated_storage      = 10
  apply_immediately      = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_security_group" "db" {
  name_prefix = "db"
  description = "Security group for todo database."

  ingress {
    description     = "Todo application database access."
    from_port       = var.db.port
    to_port         = var.db.port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
