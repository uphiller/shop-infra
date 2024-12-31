provider "aws" {
  region = "ap-northeast-2" # 원하는 Region 설정
}

# VPC 생성
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "shop"
  }
}

# Subnet 생성
resource "aws_subnet" "ecs_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-subnet"
  }
}

resource "aws_subnet" "ecs_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-subnet"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "ecs_internet_gateway" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-igw"
  }
}

# 라우트 테이블 생성
resource "aws_route_table" "ecs_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # 인터넷 전체와 통신 가능
    gateway_id = aws_internet_gateway.ecs_internet_gateway.id
  }

  tags = {
    Name = "ecs-route-table"
  }
}

# 라우트 테이블 - 서브넷 연결
resource "aws_route_table_association" "ecs_route_table_association_1" {
  subnet_id      = aws_subnet.ecs_subnet_1.id
  route_table_id = aws_route_table.ecs_route_table.id
}

resource "aws_route_table_association" "ecs_route_table_association_2" {
  subnet_id      = aws_subnet.ecs_subnet_2.id
  route_table_id = aws_route_table.ecs_route_table.id
}

# Security Group 생성
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

# ECS 클러스터 생성
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "example-ecs-cluster"
}

# ECS 태스크 정의
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "example_task"
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name  = "example-container"
      image = "nginx:latest"
      memory = 512
      cpu    = 256
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  memory                   = "512"
  cpu                      = "256"
}

# ECS 실행 역할 설정
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS 서비스 생성
resource "aws_ecs_service" "ecs_service" {
  name            = "example-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    subnets         = [aws_subnet.ecs_subnet_1.id]     # 퍼블릭 서브넷
    security_groups = [aws_security_group.ecs_sg.id] # 보안 그룹
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "example-container"
    container_port   = 80
  }
}

resource "aws_lb" "ecs_alb" {
  name               = "example-alb"
  internal           = false                  # 외부에 노출할 ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_alb_sg.id]
  subnets            = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id] # 퍼블릭 서브넷 사용

  enable_deletion_protection = false

  tags = {
    Name = "example-alb"
  }
}

resource "aws_security_group" "ecs_alb_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-alb-sg"
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "example-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
  }

  tags = {
    Name = "example-tg"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}