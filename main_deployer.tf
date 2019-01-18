module "azurelb" {
  source                   = "../../../modules/azure-lb"
  tf_az_name               = "demo"
  tf_az_env                = "dev"
  tf_az_location           = "westeurope"
  tf_az_ft_name            = "lb-web-server"
  tf_az_lb_probes_protocol = "http"
  tf_az_lb_probes_port     = "8200"
  tf_az_lb_probes_path     = "/v1/sys/health"
  tf_az_lb_nb_probes       = "2"
  tf_az_lb_rule_proto      = "Tcp"
  tf_az_lb_rule_ft_port    = "8200"
  tf_az_lb_rule_bck_port   = "8200"

  tf_az_rg_name = "dev-demo-rg"

  tf_az_tags = {
    environment = "dev"
  }
}

output "load_balancer_id" {
  value = "${module.azurelb.load_balancer_id}"
}

output "load_balancer_backend_pool_id" {
  value = "${module.azurelb.load_balancer_backend_pool_id}"
}

output "load_balancer_public_ip_address" {
  value = "${module.azurelb.load_balancer_public_ip_address}"
}
