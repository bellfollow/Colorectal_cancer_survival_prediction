# server.R
library(shiny)
library(survival)

# 모델 로드
load("../models/cox_model.rds")

# 서버 로직
server <- function(input, output, session) {
  
  # 생존곡선 플롯
  output$survival_plot <- renderPlot({
    km_fit <- survfit(Surv(time = `Survival period`, event = Death) ~ 1, 
                    data = read_csv("../../pre_process/암임상_라이브러리_합성데이터_train.csv"))
    plot(km_fit, xlab = "Time (days)", ylab = "Survival Probability")
  })
  
  # 예측 결과
  output$prediction_plot <- renderPlot({
    if (input$age == "" || input$gender == "") return(NULL)
    
    # 예측 데이터 준비
    new_data <- data.frame(
      AGE = as.numeric(input$age),
      GENDER = ifelse(input$gender == "남성", 1, 0),
      STAGE = input$stage
    )
    
    # 예측
    prediction <- predict(cox_model, newdata = new_data)
    
    # 플롯 생성
    plot(prediction, xlab = "Time (days)", ylab = "Survival Probability")
  })
  
  # 예측 텍스트 결과
  output$prediction_text <- renderText({
    if (input$age == "" || input$gender == "") return("")
    
    paste("예측 결과:", 
          "\n생존 확률: ", round(predict(cox_model, newdata = data.frame(
            AGE = as.numeric(input$age),
            GENDER = ifelse(input$gender == "남성", 1, 0),
            STAGE = input$stage
          )), 2))
    )
  })
  
  # 의료 상담
  output$consultation_output <- renderText({
    if (input$consultation_input == "") return("")
    
    paste("질문: ", input$consultation_input)
  })
}
