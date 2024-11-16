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
    
    # Aquí deberías conectar con tu modelo para realizar predicciones
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
    
    # Aquí deberías conectar con tu modelo para realizar una predicción
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