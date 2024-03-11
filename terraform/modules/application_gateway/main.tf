


resource "azurerm_public_ip" "pip" {
  name                = "AGPublicIPAddress"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "vasomhelstalipet"
}


resource "azurerm_web_application_firewall_policy" "example" {
  name                = "ApplicationGatewayWAFPolicy"
  location            = var.location
  resource_group_name = var.resource_group_name

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }

    action = "Log"
  }

  custom_rules {
    name      = "Rule2"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24"]
    }

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }

    action = "Log"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Log"
        }
      }
    }
  }
}

/*
resource "azurerm_web_application_firewall_policy" "example" {
  name                = "ApplicationGatewayWAFPolicy"
  location            = var.location
  resource_group_name = var.resource_group_name

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }

    action = "Log"
  }

  policy_settings {
    mode = "Prevention"
  }

  managed_rules {
    priority = 1
    rule_type = "OWASP"
    rule_set_version = "3.0"
    
    rule_group_override {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      disabled_rules  = ["920300", "920310"]
    }
    action = "Log"
  }
}
*/

resource "azurerm_application_gateway" "network" {
  name                = "AppGateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "backend-address-pool"
    fqdns = ["10.0.2.3"]
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "health-probe"
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "my-frontend-ip-configuration"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "backend-address-pool"
    backend_http_settings_name = "backend-http-settings"
    priority = 1
  }

  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/"
    host                = "127.0.0.1"
    timeout             = 120
    interval            = 30
    unhealthy_threshold = 3
  }

/*
  ssl_certificate {
    name     = "ssl"
    data     = filebase64("certificate.pfx")
    password = "<CERTIFICATE PASSWORD>"
  }
*/

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"

    file_upload_limit_mb = 100
    request_body_check   = true
    max_request_body_size_kb = 128
  }
}