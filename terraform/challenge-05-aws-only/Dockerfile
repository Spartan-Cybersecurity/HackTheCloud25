# Dockerfile para compilar el binario en Linux x86_64
FROM --platform=linux/amd64 gcc:latest

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    make \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /build

# Copiar archivos fuente
COPY medicloudx_exporter.c .
COPY Makefile .

# Build arguments para credenciales AWS
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

# Compilar el binario con credenciales inyectadas
RUN AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" make

# Comando por defecto
CMD ["./medicloudx_exporter", "--version"]
