variable my_ip_cidr {
  type        = string
  description = "ip public address in CIDR format to allow access to Redshift cluster"
}


variable my_namespace_name {
  type        = string
  description = "name of Redshift namespace"
}

variable my_admin_username {
  type        = string
  description = "username of admin"
}

variable my_admin_user_password {
  type        = string
  description = "password admin"
  sensitive = true
}

variable my_db_name {
  type        = string
  description = "database name"
}
