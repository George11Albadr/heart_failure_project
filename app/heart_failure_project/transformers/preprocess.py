if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

import pandas as pd

@transformer
def transform(data, *args, **kwargs):
    """
    Limpia y transforma los datos cargados en el bloque anterior.

    Args:
        data: DataFrame cargado desde el bloque de carga de datos.

    Returns:
        DataFrame procesado.
    """
    # Limpieza y transformación
    print("Limpieza y transformación de datos...")
    
    # Ejemplo de transformación de columnas categóricas
    data['Sex'] = data['Sex'].map({'M': 1, 'F': 0})
    data['ExerciseAngina'] = data['ExerciseAngina'].map({'Y': 1, 'N': 0})
    data['ChestPainType'] = data['ChestPainType'].map({'ATA': 0, 'NAP': 1, 'ASY': 2, 'TA': 3})
    data['RestingECG'] = data['RestingECG'].map({'Normal': 0, 'ST': 1, 'LVH': 2})
    data['ST_Slope'] = data['ST_Slope'].map({'Up': 0, 'Flat': 1, 'Down': 2})

    # Validaciones para verificar que no existan valores nulos
    print("Validando datos...")
    if data.isnull().sum().any():
        raise ValueError("Existen valores nulos en los datos después de la transformación.")

    # Guardar los datos procesados en un archivo CSV
    processed_csv_path = 'data/processed_data.csv'
    print(f"Guardando datos procesados en {processed_csv_path}...")
    data.to_csv(processed_csv_path, index=False)
    print("Datos procesados y guardados exitosamente.")
    
    return data

@test
def test_output(output, *args) -> None:
    """
    Test para validar que los datos procesados sean correctos.
    """
    assert output is not None, 'El DataFrame procesado está vacío'
    assert isinstance(output, pd.DataFrame), 'La salida debe ser un DataFrame'
    assert not output.empty, 'El DataFrame está vacío'
    assert 'Sex' in output.columns, "La columna 'Sex' no está en los datos procesados"
    assert 'ChestPainType' in output.columns, "La columna 'ChestPainType' no está en los datos procesados"