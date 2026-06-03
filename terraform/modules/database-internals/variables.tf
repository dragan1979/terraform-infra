variable "tags" {
  type    = map(string)
  default = {}
}

variable "app_user_password" {
  type = string
  description = "The password for the petclinic database user. This should be stored securely in Key Vault and passed in as a variable."
}