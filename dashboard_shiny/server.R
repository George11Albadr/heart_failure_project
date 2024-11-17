library(shiny)
library(DBI)
library(RPostgres)
library(ggplot2)
library(DT)
library(httr)  # Para solicitudes HTTP
library(jsonlite)  # Para manejar JSON

server <- function(input, output, session) {
  # Conexión a la base de datos
  db_conn <- dbConnect(
    RPostgres::Postgres(),
    dbname = "heartDB",
    host = "localhost",
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
    avg_time <- dbGetQuery(
      db_conn,
      "SELECT AVG(EXTRACT(EPOCH FROM (NOW() - timestamp))) AS avg_time 
       FROM prediction_logs"
    )
    valueBox(
      sprintf("%.2f s", avg_time$avg_time),  # Mostrar en segundos
      "Tiempo Promedio de Predicción",
      icon = icon("clock"),
      color = "orange"
    )
  })

  # Gráfica: Filas predichas por día
  output$rows_by_day <- renderPlot({
    rows_data <- dbGetQuery(db_conn, "
      SELECT 
        DATE(timestamp) AS prediction_date, 
        COUNT(*) AS total_rows
      FROM prediction_logs
      GROUP BY prediction_date
      ORDER BY prediction_date DESC
      LIMIT 30
    ")
    ggplot(rows_data, aes(x = prediction_date, y = total_rows)) +
      geom_bar(stat = "identity", fill = "darkgreen") +
      labs(
        title = "Filas Predichas por Día (Últimos 30 días)",
        x = "Fecha",
        y = "Número de Filas Predichas"
      ) +
      theme_minimal()
  })
  
  # Gráfica: Tiempo promedio de predicción por día
  output$avg_prediction_time_plot <- renderPlot({
    avg_time_data <- dbGetQuery(db_conn, "
      SELECT 
        DATE(timestamp) AS prediction_date,
        AVG(EXTRACT(EPOCH FROM (NOW() - timestamp))) AS avg_time
      FROM prediction_logs
      GROUP BY prediction_date
      ORDER BY prediction_date DESC
      LIMIT 30
    ")
    ggplot(avg_time_data, aes(x = prediction_date, y = avg_time)) +
      geom_line(color = "orange", size = 1) +
      labs(
        title = "Tiempo Promedio de Predicción por Día",
        x = "Fecha",
        y = "Tiempo Promedio (s)"
      ) +
      theme_minimal()
  })
  
  # Gráfica: Distribución del tiempo promedio de respuesta por día
  output$response_time_dist <- renderPlot({
    response_data <- dbGetQuery(db_conn, "
      SELECT 
        EXTRACT(EPOCH FROM (NOW() - timestamp)) AS response_time
      FROM prediction_logs
      LIMIT 100
    ")
    ggplot(response_data, aes(x = response_time)) +
      geom_histogram(binwidth = 0.1, fill = "dodgerblue", color = "black") +
      labs(
        title = "Distribución del Tiempo de Respuesta",
        x = "Tiempo de Respuesta (s)",
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
      LIMIT 15
    ")
    ggplot(conf_data, aes(x = predicted, y = actual)) +
      geom_jitter(aes(color = factor(actual)), alpha = 0.6) +
      labs(
        title = "Matriz de Confusión (Limitada a 15 registros)",
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
      LIMIT 15
    ")
    ggplot(roc_data, aes(x = actual, y = predicted)) +
      geom_smooth(color = "blue") +
      geom_abline(linetype = "dashed") +
      labs(
        title = "Curva ROC (Limitada a 15 registros)",
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
  
  # Atomic Scoring Test con Inputs Individuales
  observeEvent(input$predict_atomic, {
    req(
      input$age, input$sex, input$chest_pain_type, input$resting_bp,
      input$cholesterol, input$fasting_bs, input$resting_ecg,
      input$max_hr, input$exercise_angina, input$oldpeak,
      input$st_slope, input$heart_disease
    )
    
    tryCatch({
      # Construir JSON desde los inputs individuales
      start_time <- Sys.time()
      user_input <- list(
        list(
          Age = as.integer(input$age),
          Sex = as.integer(input$sex),
          ChestPainType = as.integer(input$chest_pain_type),
          RestingBP = as.integer(input$resting_bp),
          Cholesterol = as.integer(input$cholesterol),
          FastingBS = as.integer(input$fasting_bs),
          RestingECG = as.integer(input$resting_ecg),
          MaxHR = as.integer(input$max_hr),
          ExerciseAngina = as.integer(input$exercise_angina),
          Oldpeak = as.numeric(input$oldpeak),
          ST_Slope = as.integer(input$st_slope),
          HeartDisease = as.integer(input$heart_disease)
        )
      )
      
      # Debug: Imprime el JSON enviado al endpoint
      print(jsonlite::toJSON(user_input, auto_unbox = TRUE))
      
      # Endpoint de predicción
      mage_endpoint <- "http://0.0.0.0:8000/predict"
      
      # Enviar solicitud al endpoint de Mage.ai
      response <- httr::POST(
        url = mage_endpoint,
        body = jsonlite::toJSON(user_input, auto_unbox = TRUE),
        encode = "json"
      )
      
      # Verificar el estado de la respuesta
      if (response$status_code != 200) {
        stop(paste(
          "Error en la predicción. Código de estado:", response$status_code,
          "\nDetalles:", content(response, "text", encoding = "UTF-8")
        ))
      }
      
      # Procesar la respuesta del modelo
      prediction <- httr::content(response, as = "parsed", type = "application/json")
      
      # Extraer solo el valor de la predicción y formatearlo como array
      prediction_value <- jsonlite::toJSON(list(prediction[[1]]$Prediction), auto_unbox = TRUE)
      
      # Insertar el JSON original y la predicción en la base de datos
      end_time <- Sys.time()
      response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      prediction_value <- prediction[[1]]$Prediction
      dbExecute(db_conn, "
        INSERT INTO prediction_logs (timestamp, request, predictions)
        VALUES (NOW(), $1, $2)
      ", params = list(
        jsonlite::toJSON(user_input, auto_unbox = TRUE), 
        jsonlite::toJSON(list(prediction_value), auto_unbox = TRUE)
      ))
      output$atomic_prediction <- renderText({
        paste("Predicción realizada con éxito. Resultado:", prediction_value,
              "\nTiempo de Respuesta:", sprintf("%.2f s", response_time))
      })
    }, error = function(e) {
      output$atomic_prediction <- renderText({
        paste("Error:", e$message)
      })
    })
  })
  
  # Cerrar conexión a la base de datos
  onSessionEnded(function() {
    dbDisconnect(db_conn)
  })
}