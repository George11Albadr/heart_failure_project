import psycopg2
import pandas as pd
from psycopg2.extras import execute_values
from sklearn.metrics import roc_auc_score, precision_score, recall_score, accuracy_score
import json

# Definir DB_CONFIG
DB_CONFIG = {
    "dbname": "heartDB",
    "user": "test",
    "password": "test123",
    "host": "heartDB",  # Nombre del servicio en Docker
    "port": 5432,       # Puerto interno del contenedor PostgreSQL
}

# Importar los decoradores si no están ya en el entorno global
if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

def calculate_metrics(y_true, y_pred):
    """
    Calcula las métricas de evaluación para un modelo.
    """
    return {
        "auc": roc_auc_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred),
        "recall": recall_score(y_true, y_pred),
        "accuracy": accuracy_score(y_true, y_pred),
    }

@transformer
def transform(data, *args, **kwargs):
    """
    Extrae logs de predicciones de la base de datos, calcula métricas y las guarda en la tabla `evaluations`.
    """
    conn = None
    cursor = None
    try:
        # Conectar a la base de datos
        print(f"Conectando a la base de datos en {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Obtener registros de `prediction_logs`
        cursor.execute("SELECT request, predictions FROM prediction_logs;")
        logs = cursor.fetchall()

        print(f"Se encontraron {len(logs)} registros en `prediction_logs`.")

        # Procesar los logs
        y_true = []
        y_pred = []

        for log in logs:
            # Verificar el tipo de datos y deserializar si es necesario
            if isinstance(log[0], str):
                request = json.loads(log[0])  # Convierte la cadena JSON a un dict o lista
            else:
                request = log[0]  # Ya es un dict o lista

            if isinstance(log[1], str):
                predictions = json.loads(log[1])  # Convierte la cadena JSON a una lista
            else:
                predictions = log[1]  # Ya es una lista

            # Manejar el caso en que 'request' es una lista
            if isinstance(request, list):
                request_data = request[0]
            else:
                request_data = request

            # Validar que 'HeartDisease' está presente
            if "HeartDisease" not in request_data:
                print(f"Advertencia: 'HeartDisease' no está presente en el registro: {request_data}")
                continue  # Saltar este registro

            # Validar 'predictions'
            if not isinstance(predictions, list) or len(predictions) == 0:
                print(f"Advertencia: 'predictions' no es una lista o está vacía: {predictions}")
                continue  # Saltar este registro

            # Agregar las predicciones y valores reales
            y_true.append(request_data["HeartDisease"])
            y_pred.append(predictions[0])  # Primera predicción

        # Verificar que hay datos para calcular métricas
        if len(y_true) == 0:
            raise ValueError("No hay datos suficientes para calcular las métricas.")

        # Calcular las métricas
        metrics = calculate_metrics(y_true, y_pred)
        print(f"Métricas calculadas: {metrics}")

        # Insertar métricas en la tabla `evaluations`
        query = """
        INSERT INTO evaluations (timestamp, auc, precision, recall, accuracy)
        VALUES (NOW(), %(auc)s, %(precision)s, %(recall)s, %(accuracy)s);
        """
        cursor.execute(query, metrics)
        conn.commit()

        print("Métricas insertadas en la tabla `evaluations` con éxito.")

    except Exception as e:
        print(f"Error en el ETL de evaluaciones: {e}")
        raise e  # Vuelve a lanzar la excepción

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@test
def test_output(*args, **kwargs) -> None:
    """
    Prueba para validar que las métricas se insertaron correctamente.
    """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        cursor.execute("SELECT COUNT(*) FROM evaluations;")
        count = cursor.fetchone()[0]

        assert count > 0, "No se encontraron registros en la tabla `evaluations`."
        print(f"Prueba pasada: Se encontraron {count} registros en la tabla `evaluations`.")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()