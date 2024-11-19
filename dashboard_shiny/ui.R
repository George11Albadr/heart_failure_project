library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "Monitoreo del Modelo"),
  dashboardSidebar(
    sidebarMenu(
      menuItem(
        "Telemetría del Modelo",
        tabName = "telemetry",
        icon = icon("tachometer-alt")
      ),
      menuItem(
        "Evaluación del Modelo",
        tabName = "evaluation",
        icon = icon("chart-line")
      ),
      menuItem(
        "Métricas",
        tabName = "metrics",
        icon = icon("chart-bar")
      ),
      menuItem(
        "Batch Scoring Test",
        tabName = "batch_scoring",
        icon = icon("file-upload")
      ),
      menuItem(
        "Atomic Scoring Test",
        tabName = "atomic_scoring",
        icon = icon("cogs")
      )
    )
  ),
  dashboardBody(
    tabItems(
      # Telemetría del Modelo
      tabItem(
        tabName = "telemetry",
        fluidRow(
          valueBoxOutput("total_requests"),
          valueBoxOutput("total_predictions"),
          valueBoxOutput("avg_prediction_time")
        ),
        fluidRow(
          box(
            title = "Información del Modelo Activo",
            tableOutput("model_info"),
            width = 12
          )
        ),
        fluidRow(
          box(
            title = "Filas Predichas por Día",
            plotOutput("rows_by_day"),
            width = 6
          ),
          box(
            title = "Tiempo Promedio de Predicción por Día",
            plotOutput("avg_prediction_time_plot"),
            width = 6
          )
        ),
        fluidRow(
          box(
            title = "Distribución del Tiempo de Respuesta",
            plotOutput("response_time_dist"),
            width = 12
          )
        )
      ),
      
      # Evaluación del Modelo
      tabItem(
        tabName = "evaluation",
        fluidRow(
          box(
            plotOutput("conf_matrix"),
            width = 6,
            title = "Matriz de Confusión"
          ),
          box(
            plotOutput("roc_curve"),
            width = 6,
            title = "Curva ROC"
          )
        ),
        fluidRow(
          DT::dataTableOutput("metrics_history")
        )
      ),

            # Métricas
      tabItem(
        tabName = "metrics",
        fluidRow(
          column(
            6,
            box(
              title = "Histórico de AUC",
              plotOutput("auc_plot"),
              width = 12
            )
          ),
          column(
            6,
            box(
              title = "Histórico de Precisión",
              plotOutput("precision_plot"),
              width = 12
            )
          )
        ),
        fluidRow(
          column(
            6,
            box(
              title = "Histórico de Recall",
              plotOutput("recall_plot"),
              width = 12
            )
          ),
          column(
            6,
            box(
              title = "Histórico de Accuracy",
              plotOutput("accuracy_plot"),
              width = 12
            )
          )
        )
      ),
      
      # Métricas
      tabItem(
        tabName = "metrics",
        fluidRow(
          column(
            6,
            box(
              title = "Histórico de AUC",
              plotOutput("auc_plot"),
              width = 12
            )
          ),
          column(
            6,
            box(
              title = "Histórico de Precisión",
              plotOutput("precision_plot"),
              width = 12
            )
          )
        ),
        fluidRow(
          column(
            6,
            box(
              title = "Histórico de Recall",
              plotOutput("recall_plot"),
              width = 12
            )
          ),
          column(
            6,
            box(
              title = "Histórico de Accuracy",
              plotOutput("accuracy_plot"),
              width = 12
            )
          )
        )
      ),
      
      # Batch Scoring Test
      tabItem(
        tabName = "batch_scoring",
        fileInput(
          "batch_file",
          "Cargar archivo CSV para predicción"
        ),
        actionButton("predict_batch", "Realizar Predicción"),
        DT::dataTableOutput("batch_predictions")
      ),
      
      # Atomic Scoring Test
      tabItem(
        tabName = "atomic_scoring",
        fluidRow(
          box(
            title = "Entrada de Datos para Predicción",
            width = 12,
            fluidRow(
              column(
                6, numericInput(
                  "age", "Edad:", value = 55,
                  min = 1, max = 120
                )
              ),
              column(
                6, selectInput(
                  "sex", "Sexo:",
                  choices = c("Masculino" = 1, "Femenino" = 0)
                )
              )
            ),
            fluidRow(
              column(
                6, numericInput(
                  "chest_pain_type", "Tipo de Dolor Torácico:",
                  value = 2, min = 0, max = 3
                )
              ),
              column(
                6, numericInput(
                  "resting_bp", "Presión Arterial en Reposo:",
                  value = 130, min = 80, max = 200
                )
              )
            ),
            fluidRow(
              column(
                6, numericInput(
                  "cholesterol", "Colesterol:",
                  value = 250, min = 100, max = 600
                )
              ),
              column(
                6, numericInput(
                  "fasting_bs", "Glucosa en Ayunas (>120 mg/dl):",
                  value = 1, min = 0, max = 1
                )
              )
            ),
            fluidRow(
              column(
                6, numericInput(
                  "resting_ecg", "ECG en Reposo:",
                  value = 1, min = 0, max = 2
                )
              ),
              column(
                6, numericInput(
                  "max_hr", "Frecuencia Cardiaca Máxima:",
                  value = 140, min = 50, max = 220
                )
              )
            ),
            fluidRow(
              column(
                6, numericInput(
                  "exercise_angina", "Angina por Ejercicio (Sí=1/No=0):",
                  value = 0, min = 0, max = 1
                )
              ),
              column(
                6, numericInput(
                  "oldpeak", "Depresión del ST:",
                  value = 1.5, min = 0, max = 6
                )
              )
            ),
            fluidRow(
              column(
                6, numericInput(
                  "st_slope", "Pendiente del ST:",
                  value = 2, min = 0, max = 2
                )
              ),
              column(
                6, numericInput(
                  "heart_disease", "Enfermedad Cardíaca (Sí=1/No=0):",
                  value = 1, min = 0, max = 1
                )
              )
            ),
            actionButton("predict_atomic", "Realizar Predicción")
          )
        ),
        fluidRow(
          box(
            title = "Resultado de la Predicción",
            verbatimTextOutput("atomic_prediction"),
            width = 12
          )
        )
      )
    )
  )
)