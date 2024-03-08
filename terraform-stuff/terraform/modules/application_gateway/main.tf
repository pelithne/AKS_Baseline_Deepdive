resource "azurerm_public_ip" "example" {
  name                = "AGPublicIPAddress"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.ip_domain_name
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

    action = "Block"
  }

  policy_settings {
    mode = "Prevention"
  }
}

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
    subnet_id = var.application_gateway_subnet_id
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = "backend-address-pool"
    fqdns = ["<LOAD BALANCER PRIVATE IP>"]
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
    frontend_port_name             = "port_443"
  }

  request_routing_rule {
    name                       = "rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "backend-address-pool"
    backend_http_settings_name = "backend-http-settings"
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

  ssl_certificate {
    name     = "ssl"
    data     = filebase64("certificate.pfx")
    password = "<CERTIFICATE PASSWORD>"
  }

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