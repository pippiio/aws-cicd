data "aws_subnet" "this" {
  for_each = local.config.subnet_ids

  id = each.value
}

data "aws_vpc" "this" {
  count = length(data.aws_subnet.this) > 0 ? 1 : 0

  id = one(toset([for s in data.aws_subnet.this : s.vpc_id]))
}

resource "aws_security_group" "this" {
  count = length(data.aws_vpc.this) > 0 ? 1 : 0

  name        = "${local.name_prefix}codebuild"
  description = "Used for ${local.name_prefix}codebuild projects"
  vpc_id      = data.aws_vpc.this[count.index].id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}codebuild"
  })
}
