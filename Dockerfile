FROM python:3.9-slim

# Instala dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    git \  # Agregar git aquí
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Copia los archivos de requerimientos e instálalos
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copia el código del proyecto en el contenedor
COPY . .

# Exponer los puertos necesarios
EXPOSE 8000
EXPOSE 6789

# Comando de inicio del contenedor
CMD ["mage", "start", "heart_failure_project"]