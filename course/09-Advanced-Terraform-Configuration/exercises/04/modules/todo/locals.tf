locals {
  db_password = var.db.password == "" ? random_password.db[0].result : var.db.password

  apps = {
    blue  = var.app_blue
    green = var.app_green
  }
}
