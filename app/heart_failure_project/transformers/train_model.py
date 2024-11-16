# train_model.py

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib
import os


@transformer
def train_model(preprocessed_data: pd.DataFrame, *args, **kwargs):
    """
    Entrena un modelo Random Forest con los datos procesados y devuelve el DataFrame original junto con metadatos del modelo.

    Args:
        preprocessed_data: DataFrame procesado (salida del bloque `preprocess`).
    """
    # Validar entrada
    if not isinstance(preprocessed_data, pd.DataFrame):
        raise ValueError(f"Se esperaba un DataFrame, pero se recibió: {type(preprocessed_data)}.")

    print(f"Datos recibidos para entrenamiento: {preprocessed_data.shape}")
    print("Vista previa de los datos:")
    print(preprocessed_data.head(10))

    # Verificar que 'HeartDisease' esté presente en los datos
    target_column = 'HeartDisease'  # Cambia esto según tu dataset
    if target_column not in preprocessed_data.columns:
        raise ValueError(f"La columna objetivo '{target_column}' no está presente en los datos.")

    # Separar características (X) y etiqueta (y)
    X = preprocessed_data.drop(columns=[target_column])
    y = preprocessed_data[target_column]

    # Dividir datos en entrenamiento y prueba
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Entrenar el modelo
    print("Entrenando el modelo Random Forest...")
    model = RandomForestClassifier(random_state=42)
    model.fit(X_train, y_train)

    # Evaluar el modelo
    print("Evaluando el modelo...")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Precisión del modelo: {accuracy:.2f}")

    # Guardar el modelo en disco
    model_path = 'models/trained_model.joblib'
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    print(f"Guardando el modelo en {model_path}...")
    joblib.dump(model, model_path)

    print("Entrenamiento completado con éxito. Modelo guardado.")

    # Guardar los datos de prueba para futuras evaluaciones
    test_data = X_test.copy()
    test_data[target_column] = y_test
    test_data_path = 'data/test_data.csv'
    os.makedirs(os.path.dirname(test_data_path), exist_ok=True)
    test_data.to_csv(test_data_path, index=False)
    print(f"Datos de prueba guardados en {test_data_path}.")

    # Devuelve el DataFrame original junto con metadatos del modelo
    return {
        "data": preprocessed_data,
        "status": "success",
        "accuracy": accuracy,
        "model_path": model_path,
        "test_data_path": test_data_path,
    }


@test
def test_output(output, *args, **kwargs) -> None:
    """
    Prueba para validar que el modelo y los datos de prueba fueron guardados correctamente en disco.
    """
    assert output is not None, "El bloque `train_model` no devolvió ningún output."
    assert 'model_path' in output, "No se encontró la ruta del modelo en la salida del bloque."
    assert os.path.exists(output['model_path']), f"El modelo no se guardó correctamente en {output['model_path']}."
    assert 'test_data_path' in output, "No se encontró la ruta de los datos de prueba en la salida del bloque."
    assert os.path.exists(output['test_data_path']), f"Los datos de prueba no se guardaron correctamente en {output['test_data_path']}."
    print("Prueba pasada: El modelo y los datos de prueba se guardaron correctamente.")