data "azurerm_resource_group" "this" {
  depends_on = [var.resource_group_name]
  name       = var.resource_group_name
}

# Create a user assigned identity
resource "azurerm_user_assigned_identity" "this" {
  location            = data.azurerm_resource_group.this.location
  name                = var.name
  resource_group_name = var.resource_group_name
}

# create role assignments for built-in roles
resource "azurerm_role_assignment" "builtin" {
  count                = length(var.role_assignments)
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = var.role_assignments[count.index].built_in_role_name
  scope                = var.role_assignments[count.index].scope == "" ? data.azurerm_resource_group.this.id : var.role_assignments[count.index].scope
}

# create custom roles definitions
resource "azurerm_role_definition" "custom" {
  count = length(var.custom_role_definitions)
  name  = var.custom_role_definitions[count.index].name
  scope = data.azurerm_resource_group.this.id
  permissions {
    actions          = var.custom_role_definitions[count.index].actions
    not_actions      = var.custom_role_definitions[count.index].not_actions
    data_actions     = var.custom_role_definitions[count.index].data_actions
    not_data_actions = var.custom_role_definitions[count.index].not_data_actions
  }
  assignable_scopes = [data.azurerm_resource_group.this.id]
}

# create role assignments for custom roles
resource "azurerm_role_assignment" "custom" {
  count                = length(var.custom_role_definitions)
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = azurerm_role_definition.custom[count.index].name
  scope                = var.custom_role_definitions[count.index].scope
}


# Output the user assigned identity
output "this" {
  value = azurerm_user_assigned_identity.this
}

# Output the user assigned identity principal id
output "principal_id" {
  value = azurerm_user_assigned_identity.this.principal_id
}

# Output the user assigned identity id
output "id" {
  value = azurerm_user_assigned_identity.this.id
}

# Output the user assigned identity client id
output "client_id" {
  value = azurerm_user_assigned_identity.this.client_id
}

