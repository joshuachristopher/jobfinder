provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "job-finder" {
  name     = "job-finder-group"
  location = "Central US"
}

resource "azurerm_storage_account" "job-finder" {
  name                     = "job-finder-sa"
  resource_group_name      = azurerm_resource_group.job-finder.name
  location                 = azurerm_resource_group.job-finder.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "job-finder" {
  name                = "job-finder-service-plan"
  location            = azurerm_resource_group.job-finder.location
  resource_group_name = azurerm_resource_group.job-finder.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "job-finder" {
  name                = "job-finder-function-app"
  location            = azurerm_resource_group.job-finder.location
  resource_group_name = azurerm_resource_group.job-finder.name
  service_plan_id     = azurerm_service_plan.job-finder.id

  storage_account_name       = azurerm_storage_account.job-finder.name
  storage_account_access_key = azurerm_storage_account.job-finder.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_function_app_function" "job-finder" {
  name            = "job-finder-function-app-function"
  function_app_id = azurerm_linux_function_app.job-finder.id
  language        = "Python"
  test_data = jsonencode({
    "name" = "Azure"
  })
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
    ]
  })
}