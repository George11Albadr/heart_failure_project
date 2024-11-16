import pandas as pd
import os
from datetime import datetime
import json
from pydantic import BaseModel, ValidationError
from typing import Literal

# Ruta al dataset CSV
CSV_PATH = os.path.join("data", "heart.csv")

# Esquema de entrada usando Pydantic
class PredictionInput(BaseModel):
    Age: int
    Sex: Literal["M", "F"]  # Asegura que solo se acepten "M" o "F"
    ChestPainType: Literal["TA", "ATA", "NAP", "ASY"]
    RestingBP: int
    Cholesterol: int
    FastingBS: Literal[0, 1]
    RestingECG: Literal["Normal", "ST", "LVH"]
    MaxHR: int
    ExerciseAngina: Literal["Y", "N"]
    Oldpeak: float
    ST_Slope: Literal["Up", "Flat", "Down"]

# Mapeos para las variables categóricas
categorical_mappings = {
    "Sex": {"M": 1, "F": 0},
    "ChestPainType": {"TA": 0, "ATA": 1, "NAP": 2, "ASY": 3},
    "RestingECG": {"Normal": 0, "ST": 1, "LVH": 2},
    "ExerciseAngina": {"Y": 1, "N": 0},
    "ST_Slope": {"Up": 0, "Flat": 1, "Down": 2},
}

# Función para cargar datos desde un archivo CSV
def load_data(file_path: str):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"El archivo {file_path} no existe.")
    try:
        data = pd.read_csv(file_path)
        print(f"Datos cargados exitosamente desde {file_path}.")
        return data
    except Exception as e:
        raise ValueError(f"Error al cargar el archivo CSV: {e}")

# Función para seleccionar una muestra aleatoria de datos
def get_sample(data: pd.DataFrame):
    sample = data.sample(n=1, random_state=42).to_dict(orient="records")[0]  # Fila aleatoria como diccionario
    print("Muestra seleccionada:")
    print(sample)
    return sample

# Función para preprocesar los datos
def preprocess_input(data: dict) -> pd.DataFrame:
    try:
        # Convierte los datos categóricos en numéricos usando el mapeo
        data["Sex"] = categorical_mappings["Sex"][data["Sex"]]
        data["ChestPainType"] = categorical_mappings["ChestPainType"][data["ChestPainType"]]
        data["RestingECG"] = categorical_mappings["RestingECG"][data["RestingECG"]]
        data["ExerciseAngina"] = categorical_mappings["ExerciseAngina"][data["ExerciseAngina"]]
        data["ST_Slope"] = categorical_mappings["ST_Slope"][data["ST_Slope"]]

        # Convierte los datos en un DataFrame
        df = pd.DataFrame([data])

        return df
    except KeyError as e:
        raise ValueError(f"Valor inválido en los datos de entrada: {e}")

# Función para validar los datos y preprocesarlos
def process_data(data: dict) -> dict:
    try:
        # Valida los datos de entrada
        validated_data = PredictionInput(**data)
        print(f"Datos de entrada validados: {validated_data}")

        # Preprocesa los datos
        preprocessed_data = preprocess_input(validated_data.dict())
        print(f"Datos preprocesados: {preprocessed_data}")

        # Genera logs del procesamiento
        log_request_response(data, {"status": "processed", "data": preprocessed_data.to_dict()})

        return {"status": "success", "data": preprocessed_data.to_dict()}
    except ValidationError as ve:
        error_message = f"Error de validación: {ve.json()}"
        print(error_message)
        return {"status": "error", "message": error_message}
    except Exception as e:
        error_message = f"Error al procesar los datos: {str(e)}"
        print(error_message)
        return {"status": "error", "message": error_message}

# Función para generar logs
def log_request_response(request_data, response_data):
    try:
        log_dir = os.path.join("logs", "process")
        os.makedirs(log_dir, exist_ok=True)

        # Generar ruta del archivo log
        now = datetime.now()
        file_path = os.path.join(
            log_dir,
            f"year={now.year}",
            f"month={now.month:02d}",
            f"day={now.day:02d}",
            f"hour={now.hour:02d}"
        )
        os.makedirs(file_path, exist_ok=True)
        log_file = os.path.join(file_path, "log.json")

        # Escribir el log
        log_entry = {
            "timestamp": now.isoformat(),
            "request": request_data,
            "response": response_data
        }
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
    except Exception as log_error:
        print(f"Error al guardar el log: {str(log_error)}")

# Ejecuta la validación y preprocesamiento usando datos del CSV
if __name__ == "__main__":
    try:
        # Cargar datos desde el CSV
        data = load_data(CSV_PATH)

        # Seleccionar una muestra aleatoria
        sample_data = get_sample(data)

        # Validar y preprocesar la muestra
        result = process_data(sample_data)
        print(f"Resultado: {result}")
    except Exception as e:
        print(f"Error en la ejecución: {e}")