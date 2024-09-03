locals {
  service_definition = {
    schema-version = "v2.2"
    team           = var.team
    dd-service     = var.service_name
#     description    = var.description
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
#     tags = ["team:${var.team}"]
  }
}
