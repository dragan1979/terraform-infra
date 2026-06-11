locals {
  petclinic_db_names = ["customers", "vets", "visits"]
}

# Grant Database-level permissions for all DBs
resource "postgresql_grant" "db_connect" {
  for_each    = toset(local.petclinic_db_names)
  database    = each.value # This maps to customers, then vets, then visits
  role        = postgresql_role.petclinic_user.name
  object_type = "database"
  privileges  = ["CONNECT", "CREATE", "TEMPORARY"]
  
}


# Create the Database Role (The User)
resource "postgresql_role" "petclinic_user" {
  name     = "petclinic"
  login    = true
  # We now pass this password in as a variable from Key Vault
  password = var.app_user_password 
}

# Grant Schema-level permissions (So Spring Boot can create tables)
resource "postgresql_grant" "schema_create" {
  for_each    = toset(local.petclinic_db_names)
  database    = each.value
  role        = postgresql_role.petclinic_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}
