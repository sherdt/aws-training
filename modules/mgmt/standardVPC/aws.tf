data "aws_availability_zones" "available" {
  state = "available"

  depends_on = [null_resource.dependency_getter]
}

resource "aws_vpc" "default" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true

  tags = local.vpc_tags

  depends_on = [null_resource.dependency_getter]
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = local.default_tags

  depends_on = [null_resource.dependency_getter]
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.default.id

  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = local.public_subnet_tags

  lifecycle {
    ignore_changes = [availability_zone]
  }

  depends_on = [null_resource.dependency_getter]
}
resource "aws_subnet" "additional_public_subnets" {
  count  = length(var.aws_additional_public_subnet_cidrs)
  vpc_id = aws_vpc.default.id

  cidr_block              = var.aws_additional_public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % (length(data.aws_availability_zones.available.names) - 1) + 1]
  map_public_ip_on_launch = true

  tags = var.aws_kubernetes_tagging ? map(
    "kubernetes.io/cluster/${var.aws_kubernetes_cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
    "stageName", var.stage_name,
    "projectName", var.project_name,
    "Name", var.aws_additional_public_subnet_names[count.index],
    ) : {
    stageName   = var.stage_name
    projectName = var.project_name
    Name        = var.aws_additional_public_subnet_names[count.index]
  }

  lifecycle {
    ignore_changes = [availability_zone]
  }

  depends_on = [null_resource.dependency_getter, aws_subnet.private_subnets]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = local.default_tags

  depends_on = [null_resource.dependency_getter]
}
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id

  depends_on = [null_resource.dependency_getter, aws_internet_gateway.default]
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id

  depends_on = [null_resource.dependency_getter]
}
resource "aws_route_table_association" "additional_public_subnet" {
  count          = length(var.aws_additional_public_subnet_cidrs)
  subnet_id      = aws_subnet.additional_public_subnets[count.index].id
  route_table_id = aws_route_table.public.id

  depends_on = [null_resource.dependency_getter]
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.default.id

  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % (length(data.aws_availability_zones.available.names) - 1) + 1]

  tags = var.aws_kubernetes_tagging ? map(
    "kubernetes.io/cluster/${var.aws_kubernetes_cluster_name}", "shared",
    "kubernetes.io/role/internal-elb", "1",
    "stageName", var.stage_name,
    "projectName", var.project_name,
    "Name", var.private_subnet_names[count.index],
    ) : {
    stageName   = var.stage_name
    projectName = var.project_name
    Name        = var.private_subnet_names[count.index]
  }

  lifecycle {
    ignore_changes = [availability_zone]
  }

  depends_on = [null_resource.dependency_getter]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id

  tags = local.default_tags

  depends_on = [null_resource.dependency_getter]
}

resource "aws_route" "nat" {
  count          = var.aws_create_nat ? 1 : 0
  route_table_id = aws_route_table.private.id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id

  depends_on = [null_resource.dependency_getter]
}

resource "aws_route_table_association" "private_subnets" {
  count          = var.aws_create_nat ? length(var.private_subnet_cidrs) : 0
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id

  depends_on = [null_resource.dependency_getter]
}

# NAT Gateway
resource "aws_eip" "nat_gateway_ip" {
  count = var.aws_create_nat ? 1 : 0
  vpc   = true

  tags = local.default_tags

  depends_on = [null_resource.dependency_getter]
}

resource "aws_nat_gateway" "nat" {
  count         = var.aws_create_nat ? 1 : 0
  allocation_id = var.nat_gateway_ip == "" ? aws_eip.nat_gateway_ip[0].id : var.nat_gateway_ip
  subnet_id     = aws_subnet.public_subnet.id

  tags = local.default_tags

  depends_on = [null_resource.dependency_getter, aws_internet_gateway.default]
}

# ------------------------------------------------------------------------------
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ------------------------------------------------------------------------------
resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
    command = "echo ${length(var.dependencies)}"
  }
}
