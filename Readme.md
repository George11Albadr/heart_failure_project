shiny::runApp("/Users/georgealbadr/GitHub/heart_failure_project/dashboard_shiny") 



incersion sql


================================================================

CREATE TABLE prediction_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    request JSONB NOT NULL,
    predictions JSONB NOT NULL
);

----------------------------------------------------------------

----------------------------------------------------------------

CREATE TABLE evaluations (
    id SERIAL PRIMARY KEY,       -- ID autoincremental
    timestamp TIMESTAMP NOT NULL, -- Marca de tiempo
    auc FLOAT NOT NULL,           -- Área bajo la curva ROC
    precision FLOAT NOT NULL,     -- Precisión del modelo
    recall FLOAT NOT NULL,        -- Sensibilidad/Recall del modelo
    accuracy FLOAT NOT NULL       -- Exactitud del modelo
);

________________________________________________________________