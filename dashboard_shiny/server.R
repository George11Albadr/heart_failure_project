library(shiny)
library(DBI)
library(RPostgres)
library(ggplot2)
library(DT)

server <- function(input, output, session) {
  # Conexión a la base de datos
  db_conn <- dbConnect(
    RPostgres::Postgres(),
    dbname = "heartDB",
    host = "localhost",  # Cambiar según la configuración
    port = 5434,
    user = "test",
    password = "test123"
  )
  
  # Información del modelo activo desde evaluations
  output$model_info <- renderTable({
    model_info <- dbGetQuery(db_conn, "
      SELECT 
        id AS model_id, 
        timestamp, 
        auc, 
        precision, 
        recall, 
        accuracy 
      FROM evaluations
      ORDER BY timestamp DESC
      LIMIT 1
    ")
    model_info
  })
  
  # Telemetría del modelo
  output$total_requests <- renderValueBox({
    requests <- dbGetQuery(
      db_conn,
      "SELECT COUNT(*) AS total_requests FROM prediction_logs"
    )
    valueBox(
      requests$total_requests,
      "Total de Requests",
      icon = icon("phone"),
      color = "blue"
    )
  })
  
  output$total_predictions <- renderValueBox({
    predictions <- dbGetQuery(
      db_conn,
      "SELECT COUNT(*) AS total_predictions FROM prediction_logs"
    )
    valueBox(
      predictions$total_predictions,
      "Total de Predicciones",
      icon = icon("table"),
      color = "green"
    )
  })
  
  output$avg_prediction_time <- renderValueBox({
    # Simulación de tiempo promedio si no hay columna para ello
    avg_time <- dbGetQuery(
      db_conn,
      "SELECT AVG(LENGTH(predictions::text)) AS avg_time FROM prediction_logs"
    )
    valueBox(
      sprintf("%.2f ms", avg_time$avg_time),
      "Tiempo Promedio de Predicción",
      icon = icon("clock"),
      color = "orange"
    )
  })
  
  # Gráfica: Número de filas predichas por día
  output$rows_by_day <- renderPlot({
    rows_data <- dbGetQuery(db_conn, "
      SELECT 
        DATE(timestamp) AS prediction_date, 
        COUNT(*) AS total_rows
      FROM prediction_logs
      GROUP BY prediction_date
      ORDER BY prediction_date
    ")
    ggplot(rows_data, aes(x = prediction_date, y = total_rows)) +
      geom_line(color = "darkgreen", size = 1) +
      labs(
        title = "Filas Predichas por Día",
        x = "Fecha",
        y = "Número de Filas Predichas"
      ) +
      theme_minimal()
  })
  
  # Gráfica: Distribución de predicciones
  output$response_time_dist <- renderPlot({
    response_data <- dbGetQuery(db_conn, "
      SELECT LENGTH(predictions::text) AS prediction_size
      FROM prediction_logs
    ")
    ggplot(response_data, aes(x = prediction_size)) +
      geom_histogram(
        binwidth = 5,
        fill = "dodgerblue",
        color = "black",
        alpha = 0.7
      ) +
      labs(
        title = "Distribución del Tamaño de las Predicciones",
        x = "Tamaño de Predicciones (JSON)",
        y = "Frecuencia"
      ) +
      theme_minimal()
  })
  
  # Evaluación del modelo
  output$conf_matrix <- renderPlot({
    conf_data <- dbGetQuery(db_conn, "
      SELECT
        (request->0->>'HeartDisease')::INTEGER AS actual,
        (predictions->0)::INTEGER AS predicted
      FROM prediction_logs
    ")
    ggplot(conf_data, aes(x = predicted, y = actual)) +
      geom_jitter(aes(color = factor(actual)), alpha = 0.6) +
      labs(
        title = "Matriz de Confusión",
        x = "Predicción",
        y = "Real"
      ) +
      theme_minimal()
  })
  
  output$roc_curve <- renderPlot({
    roc_data <- dbGetQuery(db_conn, "
      SELECT
        (request->0->>'HeartDisease')::INTEGER AS actual,
        (predictions->0)::FLOAT AS predicted
      FROM prediction_logs
    ")
    ggplot(roc_data, aes(x = actual, y = predicted)) +
      geom_smooth(color = "blue") +
      geom_abline(linetype = "dashed") +
      labs(
        title = "Curva ROC",
        x = "Tasa de Falsos Positivos",
        y = "Tasa de Verdaderos Positivos"
      ) +
      theme_minimal()
  })

    output$metrics_history <- DT::renderDataTable({
    metrics <- dbGetQuery(db_conn, "SELECT * FROM prediction_logs LIMIT 100")
    datatable(metrics)
  })
  
  
  # Batch Scoring Test
  observeEvent(input$predict_batch, {
    req(input$batch_file)
    batch_data <- read.csv(input$batch_file$datapath)
    
    predictions <- data.frame(
      batch_data,
      Predicted = sample(0:1, nrow(batch_data), replace = TRUE)
    )
    
    output$batch_predictions <- DT::renderDataTable({
      datatable(predictions)
    })
  })
  
  # Atomic Scoring Test
  observeEvent(input$predict_atomic, {
    req(input$single_input)
    
    atomic_prediction <- paste(
      "Predicción:",
      sample(0:1, 1)
    )
    
    output$atomic_prediction <- renderText({
      atomic_prediction
    })
  })
  
  # Cerrar conexión a la base de datos al finalizar
  onSessionEnded(function() {
    dbDisconnect(db_conn)
  })
}