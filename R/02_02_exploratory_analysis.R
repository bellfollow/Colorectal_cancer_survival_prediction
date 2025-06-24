# 대장암 생존 분석을 위한 단변량 Cox 회귀 분석 스크립트
# EOCRC(Early-Onset Colorectal Cancer)와 LOCRC(Late-Onset Colorectal Cancer) 단변량 분석

# 필수 패키지 로드
library(tidyverse)    # 데이터 조작 및 시각화
library(survival)     # 생존 분석
library(survminer)    # 생존 분석 시각화
library(knitr)        # 표 출력을 위한 패키지
library(broom)        # 모델 결과 정리를 위한 패키지

# 데이터 로드 (상대 경로 사용)
cat("데이터 로드 중...\n")
eocrc_data <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8-BOM")
locrc_data <- read.csv("data/1_train_LOCRC.csv", fileEncoding = "UTF-8-BOM")

# 생존 시간(일)을 연 단위로 변환 (선택사항)
# eocrc_data$Survival.years <- eocrc_data$암진단후생존일수.Survival.period. / 365.25
# locrc_data$Survival.years <- locrc_data$암진단후생존일수.Survival.period. / 365.25

# 단변량 Cox 회귀 분석 함수 정의
perform_univariate_analysis <- function(data, group_name) {
  cat("\n=== ", group_name, "그룹 단변량 Cox 회귀 분석 ===\n")
  
  # 분석에서 제외할 변수들
  exclude_vars <- c("순번.No.", "cancer_type", "암진단후생존일수.Survival.period.")
  
  # 분석에 사용할 변수들 선택
  vars_to_analyze <- setdiff(names(data), c(exclude_vars, "사망여부.Death."))
  
  # 결과를 저장할 데이터프레임 초기화
  results <- data.frame(
    Variable = character(),
    HR = numeric(),
    CI_lower = numeric(),
    CI_upper = numeric(),
    p_value = numeric(),
    stringsAsFactors = FALSE
  )
  
  # 각 변수별로 단변량 Cox 회귀 분석 수행
  for (var in vars_to_analyze) {
    # 결측치가 있는 경우 제외
    temp_data <- data[!is.na(data[[var]]), ]
    
    # 종속변수에 0이 없는 경우 (분모가 0이 되는 것 방지)
    if (all(temp_data[[var]] == 0)) next
    
    # 모델 공식 생성
    formula <- as.formula(paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", var))
    
    # Cox 회귀 모델 적합
    tryCatch({
      cox_model <- coxph(formula, data = temp_data)
      
      # 모델 요약
      cox_summary <- summary(cox_model)
      
      # 결과 추출
      hr <- cox_summary$coefficients[2]  # 위험비(HR)
      ci <- cox_summary$conf.int[1, c(3,4)]  # 95% 신뢰구간
      p_value <- cox_summary$coefficients[5]  # p-value
      
      # 결과 저장
      results <- rbind(results, data.frame(
        Variable = var,
        HR = hr,
        CI_lower = ci[1],
        CI_upper = ci[2],
        p_value = p_value,
        stringsAsFactors = FALSE
      ))
    }, error = function(e) {
      # 오류가 발생한 경우 건너뜀
      cat("변수", var, "에서 오류 발생:", conditionMessage(e), "\n")
    })
  }
  
  # p-value 기준으로 정렬
  results <- results[order(results$p_value), ]
  
  # 유의한 변수만 필터링 (p < 0.05)
  significant_results <- results[results$p_value < 0.05, ]
  
  # 결과 출력
  cat("\n[전체 변수 분석 결과]\n")
  print(kable(results, digits = 3, format = "simple"))
  
  cat("\n[유의미한 변수 (p < 0.05)]\n")
  if (nrow(significant_results) > 0) {
    print(kable(significant_results, digits = 3, format = "simple"))
    
    # 유의미한 변수에 대한 생존곡선 그리기 (범주형 변수만)
    cat("\n유의미한 범주형 변수에 대한 생존곡선을 그립니다...\n")
    for (var in significant_results$Variable) {
      # 변수가 범주형인지 확인 (고유값이 10개 이하)
      if (length(unique(na.omit(data[[var]]))) <= 10 && !is.numeric(data[[var]])) {
        tryCatch({
          formula <- as.formula(paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", var))
          fit <- surv_fit(formula, data = data)
          p <- ggsurvplot(fit, data = data, pval = TRUE, risk.table = TRUE,
                         title = paste("생존곡선 -", var, "(", group_name, ")"),
                         legend = "bottom")
          print(p)
        }, error = function(e) {
          cat("생존곡선을 그리는 중 오류 발생 (", var, "):", conditionMessage(e), "\n")
        })
      }
    }
  } else {
    cat("유의미한 변수가 없습니다.\n")
  }
  
  return(list(all_results = results, significant_results = significant_results))
}

# EOCRC 그룹 분석
eocrc_results <- perform_univariate_analysis(eocrc_data, "EOCRC")

# LOCRC 그룹 분석
locrc_results <- perform_univariate_analysis(locrc_data, "LOCRC")
