output "realm_id" {
  description = "ID del realm creado"
  value       = keycloak_realm.ge_app.id
}

output "client_id" {
  description = "Client ID de la aplicación"
  value       = keycloak_openid_client.ge_go_greeter.client_id
}

output "client_secret" {
  description = "Client Secret generado por Keycloak"
  value       = keycloak_openid_client.ge_go_greeter.client_secret
  sensitive   = true
}

output "jwks_uri" {
  description = "URI del JWKS para validación del JWT (usar en Envoy SecurityPolicy)"
  value       = "${var.keycloak_url}/realms/${var.realm_id}/protocol/openid-connect/certs"
}

output "token_endpoint" {
  description = "Endpoint para obtener tokens JWT via client_credentials"
  value       = "${var.keycloak_url}/realms/${var.realm_id}/protocol/openid-connect/token"
}

output "token_curl_example" {
  description = "Comando curl de ejemplo para obtener un JWT"
  value       = <<-EOT
    curl -s -X POST ${var.keycloak_url}/realms/${var.realm_id}/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "grant_type=client_credentials" \
      -d "client_id=${var.client_id}" \
      -d "client_secret=$(terraform output -raw client_secret)" \
      | jq -r '.access_token'
  EOT
}
