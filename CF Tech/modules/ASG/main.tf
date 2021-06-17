locals {
  
  lt_name                 = coalesce(var.lt_name, var.name)
  launch_template         = var.create_lt ? aws_launch_template.this[0].name : var.launch_template
  launch_template_version = var.create_lt && var.lt_version == null ? aws_launch_template.this[0].latest_version : var.lt_version

  tags = concat(
    [
      {
        key                 = "Name"
        value               = var.name
        propagate_at_launch = var.propagate_name
      },
    ],
    var.tags,
    null_resource.tags_as_list_of_maps.*.triggers,
  )
}

resource "null_resource" "tags_as_list_of_maps" {
  count = length(keys(var.tags_as_map))

  triggers = {
    key                 = keys(var.tags_as_map)[count.index]
    value               = values(var.tags_as_map)[count.index]
    propagate_at_launch = true
  }
}

################################################################################
# Launch template
################################################################################
resource "aws_launch_template" "this" {
  count = var.create_lt ? 1 : 0

  name        = var.lt_use_name_prefix ? null : local.lt_name
  name_prefix = var.lt_use_name_prefix ? "${local.lt_name}-" : null
  description = var.description

  ebs_optimized = var.ebs_optimized
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data_base64

  vpc_security_group_ids = var.security_groups

  default_version                      = var.default_version
  update_default_version               = var.update_default_version
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  kernel_id                            = var.kernel_id
  ram_disk_id                          = var.ram_disk_id

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = flatten([lookup(block_device_mappings.value, "ebs", [])])
        content {
          delete_on_termination = lookup(ebs.value, "delete_on_termination", null)
          encrypted             = lookup(ebs.value, "encrypted", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          iops                  = lookup(ebs.value, "iops", null)
          throughput            = lookup(ebs.value, "throughput", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_carrier_ip_address = lookup(network_interfaces.value, "associate_carrier_ip_address", null)
      associate_public_ip_address  = lookup(network_interfaces.value, "associate_public_ip_address", null)
      delete_on_termination        = lookup(network_interfaces.value, "delete_on_termination", null)
      description                  = lookup(network_interfaces.value, "description", null)
      device_index                 = lookup(network_interfaces.value, "device_index", null)
      ipv4_addresses               = lookup(network_interfaces.value, "ipv4_addresses", null) != null ? network_interfaces.value.ipv4_addresses : []
      ipv4_address_count           = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv6_addresses               = lookup(network_interfaces.value, "ipv6_addresses", null) != null ? network_interfaces.value.ipv6_addresses : []
      ipv6_address_count           = lookup(network_interfaces.value, "ipv6_address_count", null)
      network_interface_id         = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address           = lookup(network_interfaces.value, "private_ip_address", null)
      security_groups              = lookup(network_interfaces.value, "security_groups", null) != null ? network_interfaces.value.security_groups : []
      subnet_id                    = lookup(network_interfaces.value, "subnet_id", null)
    }
  }

  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []
    content {
      affinity          = lookup(placement.value, "affinity", null)
      availability_zone = lookup(placement.value, "availability_zone", null)
      group_name        = lookup(placement.value, "group_name", null)
      host_id           = lookup(placement.value, "host_id", null)
      spread_domain     = lookup(placement.value, "spread_domain", null)
      tenancy           = lookup(placement.value, "tenancy", null)
      partition_number  = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications
    content {
      resource_type = tag_specifications.value.resource_type
      tags          = tag_specifications.value.tags
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags_as_map
}

################################################################################
# Autoscaling group
################################################################################

resource "aws_autoscaling_group" "this" {
  count = var.create_asg ? 1 : 0

  name        = var.use_name_prefix ? null : var.name
  name_prefix = var.use_name_prefix ? "${var.name}-" : null

  dynamic "launch_template" {
    for_each = var.use_lt ? [1] : []

    content {
      name    = local.launch_template
      version = local.launch_template_version
    }
  }

  availability_zones  = var.availability_zone
  vpc_zone_identifier = var.vpc_zone_identifier

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  capacity_rebalance        = var.capacity_rebalance
  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  default_cooldown          = var.default_cooldown
  protect_from_scale_in     = var.protect_from_scale_in

  load_balancers            = var.load_balancers
 target_group_arns = var.target_group_arns
  placement_group           = var.placement_group
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  force_delete          = var.force_delete
  termination_policies  = var.termination_policies
  suspended_processes   = var.suspended_processes
  max_instance_lifetime = var.max_instance_lifetime

  enabled_metrics         = var.enabled_metrics
  metrics_granularity     = var.metrics_granularity
  service_linked_role_arn = var.service_linked_role_arn

 mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = var.create_lt ? element(concat(aws_launch_template.this.*.id, [""]), 0) : var.launch_template
        version            = local.launch_template_version
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 0
    }

  dynamic "initial_lifecycle_hook" {
    for_each = var.create_asg && var.create_asg_with_initial_lifecycle_hook ? [1] : []
    content {
      name                    = var.initial_lifecycle_hook_name
      lifecycle_transition    = var.initial_lifecycle_hook_lifecycle_transition
      notification_metadata   = var.initial_lifecycle_hook_notification_metadata
      heartbeat_timeout       = var.initial_lifecycle_hook_heartbeat_timeout
      notification_target_arn = var.initial_lifecycle_hook_notification_target_arn
      role_arn                = var.initial_lifecycle_hook_role_arn
      default_result          = var.initial_lifecycle_hook_default_result
    }
  }

 lifecycle {
    create_before_destroy = true
    ignore_changes = [ load_balancers, target_group_arns ]
  }
}

//mixed_instances_policy {
   // instances_distribution {
    //  on_demand_base_capacity                  = 2
  //    on_demand_percentage_above_base_capacity = 0
//    }


//      launch_template {
  //      launch_template_specification {
    //      launch_template_name = local.launch_template
      //    version              = local.launch_template_version
        }

//          }
//}
//}

################################################################################
# Autoscaling group schedule
################################################################################
resource "aws_autoscaling_schedule" "this" {
  for_each = var.create_asg && var.create_schedule ? var.schedules : {}

  scheduled_action_name  = each.key
  autoscaling_group_name = aws_autoscaling_group.this[0].name

  min_size         = lookup(each.value, "min_size", null)
  max_size         = lookup(each.value, "max_size", null)
  desired_capacity = lookup(each.value, "desired_capacity", null)
  start_time       = lookup(each.value, "start_time", null)
  end_time         = lookup(each.value, "end_time", null)

  # [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]
  # Cron examples: https://crontab.guru/examples.html
  recurrence = lookup(each.value, "recurrence", null)
}
