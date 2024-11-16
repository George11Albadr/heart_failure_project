if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

import pandas as pd

@data_loader
def load_data(*args, **kwargs):
    """
    Carga datos desde un archivo CSV local.

    Returns:
        DataFrame con los datos cargados.
    """
    # Ruta al archivo CSV
    csv_path = 'data/heart.csv'

    # Carga el dataset
    try:
        data = pd.read_csv(csv_path)
        print(f"Datos cargados exitosamente: {data.shape[0]} filas, {data.shape[1]} columnas.")
        return data
    except FileNotFoundError as e:
        raise FileNotFoundError(f"No se encontró el archivo en la ruta especificada: {csv_path}")
    except Exception as e:
        raise ValueError(f"Error al cargar el archivo CSV: {str(e)}")

@test
def test_output(output, *args) -> None:
    """
    Test para verificar que los datos se cargaron correctamente.
    """
    assert output is not None, 'La salida es indefinida'
    assert isinstance(output, pd.DataFrame), 'La salida debe ser un DataFrame'
    assert not output.empty, 'El DataFrame está vacío'