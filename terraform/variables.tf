variable "keycloak_url" {
  description = "URL base de Keycloak (ej: http://192.168.1.20:30080)"
  type        = string
  default     = "http://192.168.1.20:30080"
}

variable "keycloak_admin_user" {
  description = "Usuario administrador de Keycloak"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Contraseña del administrador de Keycloak"
  type        = string
  sensitive   = true
}

variable "tls_insecure" {
  description = "Deshabilitar verificación TLS (solo para homelab/dev)"
  type        = bool
  default     = true
}

variable "realm_id" {
  description = "Nombre del realm a crear"
  type        = string
  default     = "ge-app"
}

variable "client_id" {
  description = "Client ID de la aplicación ge-go-greeter"
  type        = string
  default     = "ge-go-greeter"
}

