[
  {
    "name": "${env}-app-id",
    "image": "${app_image}",
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/app",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
      
      "name": "${env}-app-8000-tcp",
        "containerPort": 8000,
        "hostPort": 8000,
        "protocol": "tcp",
        "appProtocol": "http"
      },
      {
        "name": "${env}-app",
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp",
        "appProtocol": "http"
    
      }
    ],
    "essential": true,
    "secrets": [
      {
        "name": "DATABASE_URL",
        "valueFrom": "${secret_id}:DATABASE_URL::"
      },
      {
        "name": "DB_HOST",
        "valueFrom": "${secret_id}:DB_HOST::"
      },
      {
        "name": "DB_NAME",
        "valueFrom": "${secret_id}:DB_NAME::"
      },
      {
        "name": "DB_PASSWORD",
        "valueFrom": "${secret_id}:DB_PASSWORD::"
      },
      {
        "name": "DB_USER",
        "valueFrom": "${secret_id}:DB_USER::"
      }
    ]
  }
]
