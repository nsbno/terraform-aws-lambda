locals {
  service_definition = {
    schema-version = "v2.2"
    team           = var.team
    dd-service     = var.service_name
    description    = var.description
    #     contacts = [
    #       {
    #         name = "Support Email"
    #         type = "email"
    #         contact = var.support_email
    #       },
    #     ]
    #     tier = var.tier
    #     application = var.application
    #     languages = var.languages
    #     type = var.type
    #     links = var.links
    tags = ["team:${var.team}"]
  }
}

// Service Definition with v2.2 Schema Definition
resource "datadog_service_definition_yaml" "service_definition_v2_2" {
  service_definition = yamlencode(local.service_definition)
}
