# predict_model.py

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

import pandas as pd
import joblib
import os


@transformer
def predict_model(*args, **kwargs):
    """
    Realiza predicciones utilizando el modelo entrenado y los datos de prueba guardados,
    y guarda los resultados en un archivo CSV.

    Args:
        No requiere argumentos, ya que los datos de prueba y el modelo se cargan desde disco.
    """
    # Cargar los datos de prueba
    test_data_path = 'data/test_data.csv'
    if not os.path.exists(test_data_path):
        raise FileNotFoundError(f"No se encontró el archivo de datos de prueba en {test_data_path}. Por favor, entrena el modelo primero.")

    print("Cargando los datos de prueba...")
    test_data = pd.read_csv(test_data_path)

    # Verificar que 'HeartDisease' esté presente en los datos de prueba
    target_column = 'HeartDisease'
    if target_column not in test_data.columns:
        raise ValueError(f"La columna objetivo '{target_column}' no está presente en los datos de prueba.")

    # Separar características y etiquetas verdaderas
    X_test = test_data.drop(columns=[target_column])
    y_true = test_data[target_column]

    # Cargar el modelo entrenado
    model_path = 'models/trained_model.joblib'
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"No se encontró el modelo entrenado en {model_path}. Por favor, entrena el modelo primero.")

    print("Cargando el modelo entrenado...")
    model = joblib.load(model_path)

    # Validar que las columnas coincidan con las esperadas por el modelo
    expected_features = model.feature_names_in_
    if not set(expected_features).issubset(X_test.columns):
        missing_features = set(expected_features) - set(X_test.columns)
        raise ValueError(f"Faltan las siguientes columnas necesarias para el modelo: {missing_features}")

    # Generar predicciones
    print("Generando predicciones...")
    y_pred = model.predict(X_test[expected_features])

    # Crear un DataFrame con los resultados
    results = X_test.copy()
    results[target_column] = y_true
    results['Predictions'] = y_pred

    # Vista previa de las predicciones (máximo 10 filas)
    print("Vista previa de predicciones:")
    print(results.head(10))

    # Guardar las predicciones en un archivo
    output_path = 'data/predictions.csv'
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    print(f"Guardando predicciones en {output_path}...")
    results.to_csv(output_path, index=False)

    print("Predicciones generadas y guardadas con éxito.")


@test
def test_output(*args, **kwargs) -> None:
    """
    Validar que las predicciones se guardaron correctamente.
    """
    output_path = 'data/predictions.csv'
    assert os.path.exists(output_path), f"No se generó el archivo de predicciones en {output_path}."
    predictions = pd.read_csv(output_path)
    assert not predictions.empty, "El archivo de predicciones está vacío."
    required_columns = ['HeartDisease', 'Predictions']
    for col in required_columns:
        assert col in predictions.columns, f"La columna '{col}' no está presente en el archivo de predicciones."
    print("Prueba pasada: El archivo de predicciones se generó correctamente y contiene las columnas necesarias.")