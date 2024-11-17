#!/bin/bash

# Inicia MageAI en segundo plano
echo "Iniciando MageAI en el puerto 6789..."
mage start heart_failure_project > mageai_logs.log 2>&1 &

# Espera unos segundos para asegurarse de que MageAI está listo
sleep 10

# Inicia el servidor FastAPI en el puerto 8000
echo "Iniciando FastAPI en el puerto 8000..."
uvicorn asgi:app --host 0.0.0.0 --port 8000