# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Requisitos
Docker y Docker Compose instalados

# .env
PORT=3000
RAILS_ENV=development
WEB_CONCURRENCY=0
RAILS_MAX_THREADS=5

SECRET_KEY_BASE=xxxxx

BASE_ROUTE=localhost
# Database 
DATABASE_URL=postgres://user:changeme@localhost
REDIS_URL=redis://localhost:6379/1    # action cable
REDIS_PROVIDER=redis://localhost:6379 # sidekiq

# AWS 
AWS_REGION = add-region
AWS_ACCESS_KEY_ID = xxx
AWS_SECRET_ACCESS_KEY = xxxx
S3_BUCKET_NAME = bucket-name

# construir y ejecutar el proyecto
docker-compose build
docker-compose up -d

# Crear la base de datos
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate

# comandos utiles
docker-compose up -d   ## Iniciar los contenedores en segundo plano
docker-compose down    ## Detener los contenedores
docker-compose exec web bash   ## Acceder a una consola Bash dentro del contenedor web

# postgres
brew services start postgresql
brew services stop postgresql