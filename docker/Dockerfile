# Usa Python 3.9-slim como base
FROM python:3.9-slim

LABEL authors="georgealbadr"

# Instala las dependencias del sistema necesarias para compilar paquetes de Python
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    python3-dev \
    linux-libc-dev \
    build-essential \
    git \
    curl \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Establece un directorio de trabajo en el contenedor
WORKDIR /app

# Copia el archivo de requerimientos desde la carpeta docker
COPY docker/requirements.txt .

# Instala las dependencias de Python
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copia el resto del proyecto al contenedor
COPY ./app /app

# Copia la carpeta `models` al contenedor
COPY ./models /app/models

# Asegúrate de que el archivo `start.sh` tenga permisos de ejecución
RUN chmod +x /app/start.sh

# Exponer los puertos necesarios para MageAI y FastAPI
EXPOSE 8000  
EXPOSE 5434  
EXPOSE 6789  

# Comando de inicio usando el script start.sh
CMD ["/bin/bash", "/app/start.sh"]