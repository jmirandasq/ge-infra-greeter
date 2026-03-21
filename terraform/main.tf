# ── Realm ──────────────────────────────────────────────────────────────────────
resource "keycloak_realm" "ge_app" {
  realm   = var.realm_id
  enabled = true

  display_name     = "GE App"
  display_name_html = "<b>GE App</b>"

  # Configuración de tokens JWT
  access_token_lifespan                    = "15m"
  access_token_lifespan_for_implicit_flow  = "15m"
  sso_session_idle_timeout                 = "30m"
  sso_session_max_lifespan                 = "8h"
  offline_session_idle_timeout             = "720h"
  refresh_token_max_reuse                  = 0

  # Algoritmo de firma del JWT — RS256 es el estándar para validación con JWKS
  default_signature_algorithm = "RS256"
}

# ── Cliente confidencial (machine-to-machine) ───────────────────────────────────
# Flujo: client_credentials grant → JWT Bearer token
# El consumidor obtiene el token con:
#   POST /realms/ge-app/protocol/openid-connect/token
#   grant_type=client_credentials&client_id=ge-go-greeter&client_secret=<secret>
resource "keycloak_openid_client" "ge_go_greeter" {
  realm_id  = keycloak_realm.ge_app.id
  client_id = var.client_id

  name        = "GE Go Greeter"
  description = "Cliente de la aplicación ge-go-greeter"
  enabled     = true

  # CONFIDENTIAL = tiene client_secret; necesario para client_credentials
  access_type = "CONFIDENTIAL"

  # Habilitar client credentials grant para JWT machine-to-machine
  service_accounts_enabled = true

  standard_flow_enabled = false

  # Direct Access Grant (solo para testing/dev)
  direct_access_grants_enabled = true

  # Configuración del JWT de acceso
  login_theme = "keycloak"
}

# ── Scope: roles ───────────────────────────────────────────────────────────────
# Incluir los roles del cliente en el JWT para que Envoy pueda validar permisos
resource "keycloak_openid_client_scope" "app_roles" {
  realm_id    = keycloak_realm.ge_app.id
  name        = "app-roles"
  description = "Roles de la aplicación ge-go-greeter"

  include_in_token_scope = true
  gui_order              = 1
}

# ── Mapper: roles del cliente en el JWT ────────────────────────────────────────
# Sin este mapper los roles no aparecen en el access_token
resource "keycloak_generic_protocol_mapper" "client_roles_mapper" {
  realm_id        = keycloak_realm.ge_app.id
  client_scope_id = keycloak_openid_client_scope.app_roles.id
  name            = "client-roles"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-usermodel-client-role-mapper"

  config = {
    "access.token.claim"                  = "true"
    "claim.name"                          = "roles"
    "jsonType.label"                      = "String"
    "multivalued"                         = "true"
    "usermodel.clientRoleMapping.clientId" = var.client_id
  }
}

# ── Asignar el scope al cliente ────────────────────────────────────────────────
resource "keycloak_openid_client_default_scopes" "ge_go_greeter_scopes" {
  realm_id  = keycloak_realm.ge_app.id
  client_id = keycloak_openid_client.ge_go_greeter.id

  default_scopes = [
    "openid",
    "profile",
    "email",
    keycloak_openid_client_scope.app_roles.name,
  ]
}

# ── Rol: greet ─────────────────────────────────────────────────────────────────
# Solo service accounts con este rol pueden consumir el endpoint /greet
resource "keycloak_role" "greet" {
  realm_id  = keycloak_realm.ge_app.id
  client_id = keycloak_openid_client.ge_go_greeter.id
  name      = "greet"
  description = "Permite llamar al endpoint POST /greet"
}

# ── Asignar el rol greet a la service account del propio cliente ──────────────
# Así el cliente puede llamarse a sí mismo en flujos de prueba
resource "keycloak_openid_client_service_account_role" "greet_self" {
  realm_id                = keycloak_realm.ge_app.id
  service_account_user_id = keycloak_openid_client.ge_go_greeter.service_account_user_id
  client_id               = keycloak_openid_client.ge_go_greeter.id
  role                    = keycloak_role.greet.name
}
