# ui.R
library(shiny)
library(shinydashboard)

# 대시보드 UI
ui <- dashboardPage(
  dashboardHeader(title = "대장암 생존 예측 시스템"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("데이터 탐색", tabName = "eda", icon = icon("chart-line")),
      menuItem("생존 예측", tabName = "prediction", icon = icon("calculator")),
      menuItem("의료 상담", tabName = "consultation", icon = icon("comments"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # 데이터 탐색 탭
      tabItem(tabName = "eda",
              fluidRow(
                box(title = "생존곡선", width = 12,
                    plotOutput("survival_plot"))
              )
      ),
      
      # 생존 예측 탭
      tabItem(tabName = "prediction",
              fluidRow(
                box(title = "환자 정보 입력", width = 6,
                    textInput("age", "나이", ""),
                    selectInput("gender", "성별", choices = c("남성", "여성")),
                    numericInput("stage", "병기", min = 1, max = 4, value = 1)
                ),
                box(title = "예측 결과", width = 6,
                    plotOutput("prediction_plot"),
                    verbatimTextOutput("prediction_text")
                )
              )
      ),
      
      # 의료 상담 탭
      tabItem(tabName = "consultation",
              fluidRow(
                box(title = "의료 상담", width = 12,
                    textInput("consultation_input", "질문 입력", ""),
                    actionButton("submit", "질문하기"),
                    br(),
                    verbatimTextOutput("consultation_output")
                )
              )
      )
    )
  )
)
