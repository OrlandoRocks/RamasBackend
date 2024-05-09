# Usar una imagen base de Ruby
FROM ruby:3.2.2

# Instalar PostgreSQL Client
RUN apt-get update -qq && apt-get install -y postgresql-client

# Instalar dependencias
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Crear el directorio de la aplicación
RUN mkdir /RamasBackend
WORKDIR /RamasBackend

# Copiar el Gemfile y Gemfile.lock para instalar dependencias
COPY Gemfile Gemfile.lock /RamasBackend/
RUN bundle install

# Copiar el resto de la aplicación
COPY . /RamasBackend

# Crear alias de comandos para facilitar el uso
RUN echo 'alias be="bundle exec"' >> ~/.bashrc

# Exponer el puerto 3000 para Rails
EXPOSE 3000
