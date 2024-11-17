from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import os
import pandas as pd
import joblib
import json
from typing import List, Dict

app = FastAPI()

# Ruta al modelo entrenado
MODEL_PATH = "models/trained_model.joblib"

# Validar la existencia del modelo
if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"No se encontró el modelo en {MODEL_PATH}. Por favor, entrena el modelo primero.")

# Cargar el modelo
model = joblib.load(MODEL_PATH)

# Validar las columnas esperadas
EXPECTED_FEATURES = model.feature_names_in_

# Ruta para guardar métricas del modelo
METRICS_FILE = "logs/metrics.json"

# Endpoint básico para verificar el estado
@app.get("/", summary="Root endpoint", description="Verifica si la API está activa.")
async def root():
    return {"message": "API para procesamiento de datos activa."}

# Endpoint para realizar predicciones individuales o en lote
@app.post(
    "/predict", 
    summary="Realiza predicciones",
    description="Realiza predicciones utilizando el modelo entrenado. Recibe una lista de registros como entrada."
)
async def predict(data: List[Dict]):
    try:
        # Convertir la entrada a un DataFrame
        df = pd.DataFrame(data)

        # Validar que todas las columnas esperadas estén presentes
        missing_features = set(EXPECTED_FEATURES) - set(df.columns)
        if missing_features:
            raise HTTPException(
                status_code=400,
                detail=f"Faltan las columnas necesarias para el modelo: {missing_features}",
            )

        # Generar predicciones
        predictions = model.predict(df[EXPECTED_FEATURES])
        df["Prediction"] = predictions

        # Guardar las predicciones en logs
        save_prediction_logs(data, df["Prediction"].tolist())

        # Retornar las predicciones
        return JSONResponse(content=df.to_dict(orient="records"))

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint para métricas del modelo
@app.get(
    "/metrics",
    summary="Obtén métricas del modelo",
    description="Devuelve las métricas actuales del modelo, como la precisión y la última actualización."
)
async def metrics():
    try:
        if not os.path.exists(METRICS_FILE):
            return {"message": "No se encontraron métricas registradas."}

        with open(METRICS_FILE, "r") as f:
            metrics_data = json.load(f)

        return metrics_data

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener métricas: {str(e)}")

# Función para guardar logs de predicciones
def save_prediction_logs(request_data, predictions):
    logs_dir = "logs/api"
    os.makedirs(logs_dir, exist_ok=True)
    log_file = os.path.join(logs_dir, "predictions.log")

    log_entry = {
        "request": request_data,
        "predictions": predictions,
        "timestamp": pd.Timestamp.now().isoformat(),
    }
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")

# Función para registrar métricas del modelo
def save_metrics(accuracy: float):
    """
    Guarda las métricas del modelo en un archivo JSON.
    """
    os.makedirs(os.path.dirname(METRICS_FILE), exist_ok=True)

    metrics_data = {
        "accuracy": accuracy,
        "last_updated": pd.Timestamp.now().isoformat(),
    }

    with open(METRICS_FILE, "w") as f:
        json.dump(metrics_data, f)

# Registrar métricas iniciales del modelo (si están disponibles)
try:
    save_metrics(accuracy=0.87)  # Cambia esto si tienes otra métrica calculada
except Exception as e:
    print(f"Error al guardar métricas iniciales: {e}")