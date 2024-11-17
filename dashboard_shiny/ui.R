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
            title = "Distribución de Tamaño de Predicciones",
            plotOutput("response_time_dist"),
            width = 6
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
        textInput("single_input", "Entrada para predicción"),
        actionButton("predict_atomic", "Realizar Predicción"),
        verbatimTextOutput("atomic_prediction")
      )
    )
  )
)