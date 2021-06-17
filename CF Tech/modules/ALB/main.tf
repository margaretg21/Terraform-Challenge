resource "aws_lb" "this" {
  count = var.create_lb ? 1 : 0

  name        = var.name
  name_prefix = var.name_prefix

  load_balancer_type = "application"
  internal           = false
  security_groups    = var.security_groups
  subnets            = var.subnets

}

resource "aws_lb_target_group" "main" {
  count = var.create_lb ? length(var.target_groups) : 0

  name        = "target-group"

  vpc_id           = var.vpc_id
  port             = 80
  protocol         = "HTTP"

  health_check {
   interval            = 30
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }

  depends_on = [aws_lb.this]

}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_lb.this[0].arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.main[0].arn}"
    type             = "forward"
  }
}
