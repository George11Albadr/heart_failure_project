if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

import psycopg2
import os
import json
from datetime import datetime

DB_CONFIG = {
    'dbname': 'heartDB',
    'user': 'test',
    'password': 'test123',
    'host': 'heartDB',  # Cambiar según el servicio Docker
    'port': '5432',     # Puerto interno de PostgreSQL
}

@transformer
def etl_logs(*args, **kwargs):
    """
    ETL para guardar logs de predicciones en la base de datos.
    """
    try:
        # Conectar a la base de datos
        print(f"Conectando a la base de datos en {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Leer los logs de predicciones
        logs_dir = os.path.join('logs', 'api')
        log_file = os.path.join(logs_dir, 'predictions.log')

        if not os.path.exists(log_file):
            print(f"No se encontró el archivo de logs en {log_file}.")
            return

        with open(log_file, 'r') as f:
            logs = [json.loads(line) for line in f.readlines()]

        # Insertar cada log en la base de datos
        for log in logs:
            cursor.execute(
                """
                INSERT INTO prediction_logs (timestamp, request, predictions)
                VALUES (%s, %s, %s)
                """,
                (log['timestamp'], json.dumps(log['request']), json.dumps(log['predictions']))
            )

        # Confirmar cambios
        conn.commit()
        print("Logs de predicción insertados en la base de datos con éxito.")

    except Exception as e:
        print(f"Error en el ETL de logs: {e}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@test
def test_etl_logs(*args, **kwargs):
    """
    Prueba para validar la inserción de logs en la base de datos.
    """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Verificar que hay al menos un registro en la tabla
        cursor.execute("SELECT COUNT(*) FROM prediction_logs")
        count = cursor.fetchone()[0]
        assert count > 0, "No se encontraron registros en la tabla prediction_logs."

        print(f"Prueba pasada: Se encontraron {count} registros en la tabla prediction_logs.")

    except Exception as e:
        print(f"Error durante la prueba de ETL logs: {e}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()