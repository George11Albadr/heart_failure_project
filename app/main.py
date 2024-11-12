from fastapi import FastAPI
import pandas as pd
import joblib
import os

app = FastAPI()

# Ruta al modelo preentrenado
model_path = os.path.join("models", "modelo_random_forest.joblib")
model = joblib.load(model_path)  # Carga el modelo preentrenado

@app.get("/")
async def root():
    return {"message": "Heart Failure Prediction API"}

@app.post("/predict")
async def predict(data: dict):
    # Convierte los datos de entrada en un DataFrame
    df = pd.DataFrame([data])

    # Realiza la predicción
    prediction = model.predict(df)

    # Retorna la predicción como un valor JSON
    return {"prediction": int(prediction[0])}