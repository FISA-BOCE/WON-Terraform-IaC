locals {
  rds_data_subnet_keys = {
    card = [
      "card-data-layer-private-subnet-01",
      "card-data-layer-private-subnet-02"
    ]

    securities = [
      "securities-data-layer-private-subnet-01",
      "securities-data-layer-private-subnet-02"
    ]
  }

  rds_networks = {
    for key, database in var.rds_databases : key => {
      vpc_id = data.terraform_remote_state.network.outputs.vpc_ids[key]
      data_subnet_ids = [
        for subnet_key in local.rds_data_subnet_keys[key] :
        data.terraform_remote_state.network.outputs.subnet_ids[subnet_key]
      ]
      db_name     = database.db_name
      db_username = database.db_username
    }
  }
}
