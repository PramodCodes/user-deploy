# way of issue fixing
# if you are running remote exec , the machiene you run must have access to it, 
# in other words , if you are running on windows you need to have vpn connection if you are trying to exec remote exec on private instance
# if issue is between instances check with ping or telent
# if it fails check ports , security groups, vpn peering connection , and firewall blocking in instances
resource "aws_lb_target_group" "catalogue" {
  name     = "${local.name}-${var.tags.Componenet}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  # deregistration delay is the time it takes to deregister the instance from the target group,
  #  the instance will not recieve any new requests and complete pending requests before deregistration
  deregistration_delay = 30
  health_check {
    healthy_threshold = 2
    interval = 10
    unhealthy_threshold = 3
    timeout = 5
    path = "/health"
    port = 8080
    matcher = "200-299"
  }
  # tags = merge(
  #   var.common_tags,
  #   var.tags
  # )
}
module "catalogue" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name = "${local.name}-${var.tags.Componenet}-ami"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id              = element(split(",",data.aws_ssm_parameter.private_subnets_ids.value),0)
  # the following will attach a ec2 file
  iam_instance_profile = "ec2-role-shell-script"
  tags = merge(
    var.common_tags,
    var.tags
  )
}

resource "null_resource" "catalogue" {
  # depends_on = [null_resource.wait_for_instance]
  triggers = {
    instance_id = module.catalogue.id
  }

  connection {
    host = module.catalogue.private_ip
    type = "ssh"
    user = "centos"
    password = "DevOps321"
    # timeout     = "5m" # timeout for connection you can reduce or increase 

  }
  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh catalogue dev ${var.app_version}" # you need to provide the arguments for shell script to get it executed by remote-exec
    ]
  }
}

# we need to write dependence on the running of catalogue service 
# other wise the instance will stop at the end of the terraform apply which is not desired
resource "aws_ec2_instance_state" "catalogue_instance_state_stop" {
  instance_id = module.catalogue.id
  state       = "stopped"
  depends_on = [ null_resource.catalogue ]
}
# we will add timestamp to the ami name to make it unique and to understand when it was created
resource "aws_ami_from_instance" "catalogue" {
  name               = "${local.name}-${var.tags.Componenet}-${local.current_time}"
  source_instance_id = module.catalogue.id
  # not sure if the following is needed
  depends_on         = [ aws_ec2_instance_state.catalogue_instance_state_stop ]
}

# terminate instance after creating ami
resource "null_resource" "catalogue_terminate" {
  # we are changing the trigger from every change of ami, instead we must do it instance
  # ami id will keep changing when timestamp changes, what happening is this instance will be terminated when instance is being configured
  # now the trigger (deletion) happens when catalogue isntance id changes
  
  triggers = {
  #   ami_id = aws_ami_from_instance.catalogue.id
    instance_id = module.catalogue.id
  }
# we already have a connection to the instance so we don't need remote exec we can use local exec
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.catalogue.id}"
  }
  depends_on = [ aws_ami_from_instance.catalogue ]
}

# now that we have ami created and deleted the instance lets create the launch template
resource "aws_launch_template" "catalogue_template" {
  name = "${local.name}-${var.tags.Componenet}"
  image_id = aws_ami_from_instance.catalogue.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro" 
  update_default_version = true # this will update the default version of the launch template for each new version of the launch template creation
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name}-${var.tags.Componenet}"
    }
  }
    depends_on         = [ null_resource.catalogue_terminate ]
}


# now that we have launch template lets create the autoscaling group

resource "aws_autoscaling_group" "catalogue" {
  name                      = "${local.name}-${var.tags.Componenet}"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "ELB"
  desired_capacity          = 2
  # we will use launch template instead of launch configuration
  vpc_zone_identifier       = split(",",data.aws_ssm_parameter.private_subnets_ids.value)
  # where to place the launch template
  target_group_arns = [aws_lb_target_group.catalogue.arn]
  launch_template {
    id      = aws_launch_template.catalogue_template.id
    version = aws_launch_template.catalogue_template.latest_version
  }
  # instance refresh means recreate the instance with the new launch template
  instance_refresh {
    strategy = "Rolling"
    preferences { 
    # this means that to refresh to happen the 50% of the existing instances must be healthy
      min_healthy_percentage = 50
    }
  # what triggers the refresh - change in launch template
    triggers = ["launch_template"]
  }
  
  tag {
    key                 = "Name"
    value               = "${local.name}-${var.tags.Componenet}"
    propagate_at_launch = true
  }
# instance must be created with in the time out
  timeouts {
    delete = "15m"
  }

}
# aws lb listener rules
# what does listener do ? and how it works?
# listener is the entry point for the load balancer, it listens to the requests and forwards them to the target group
resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listner_arn.value
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }
  condition {
    host_header {
      values = ["${var.tags.Componenet}.app-${var.environment}.${var.zone_name}"]
    }
  }
}

# we need to check average cpu utilization and scale the instances based on that we will use policy to do so
resource "aws_autoscaling_policy" "catalogue" {
  depends_on = [aws_autoscaling_group.catalogue]
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name                   = "${local.name}-${var.tags.Componenet}"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # this means that the average cpu utilization must be 50% if it goes above 5% it will scale out , 
    # scale out means it will start creating instances
    target_value = 50.0 
  }
}