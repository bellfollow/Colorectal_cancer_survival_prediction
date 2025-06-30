# 대장암 생존 분석을 위한 다변량 Cox 회귀 분석 스크립트
# EOCRC(Early-Onset Colorectal Cancer)와 LOCRC(Late-Onset Colorectal Cancer) 다변량 분석

# 필수 패키지 로드
library(tidyverse)    # 데이터 조작 및 시각화
library(survival)     # 생존 분석
library(survminer)    # 생존 분석 시각화
library(knitr)        # 표 출력을 위한 패키지
library(broom)        # 모델 결과 정리를 위한 패키지
library(car)          # 다중공선성 검사

# 데이터 로드 (상대 경로 사용)
cat("데이터 로드 중...\n")
eocrc_data <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8-BOM")
locrc_data <- read.csv("data/1_train_LOCRC.csv", fileEncoding = "UTF-8-BOM")

# 각 그룹별로 유의한 변수 정의 (p < 0.25)
eocrc_significant_vars <- c(
  "조직학적진단명.코드.설명.signet.ring.cell.",
  "조직학적진단명.코드.설명.Neoplasm.malignant.",
  "체중측정값.Weight.",
  "조직학적진단명.코드.설명.carcinoide.tumor.",
  "항암제.치료.여부.Chemotherapy."
)

locrc_significant_vars <- c(
  "체중측정값.Weight.",
  "조직학적진단명.코드.설명.Neuroendocrine.carcinoma.",
  "분자병리MSI검사결과코드.명.MSI.",
  "조직학적진단명.코드.설명.carcinoide.tumor.",
  "진단시연령.AGE.",
  "M_stage",
  "항암제.치료.여부.Chemotherapy."
)

# 다변량 Cox 회귀 분석 함수 정의
perform_multivariate_analysis <- function(data, group_name) {
  # 데이터 프레임으로 변환 및 복사
  analysis_data <- as.data.frame(data)
  
  # M_stage가 있으면 더미 변수 생성
  if ("M_stage" %in% names(analysis_data)) {
    # M_stage를 factor로 변환 (명시적 레벨 지정)
    analysis_data$M_stage <- factor(analysis_data$M_stage, levels = c("M0", "M1"))
    # 더미 변수 생성 (M1에 대한 더미)
    analysis_data$M_stage_M1 <- as.numeric(analysis_data$M_stage == "M1")
  }

  cat("\n=== ", group_name, "그룹 다변량 Cox 회귀 분석 (p < 0.25 유의변수 기반) ===\n")
  
  # 그룹에 따라 유의한 변수 선택
  if (group_name == "EOCRC") {
    vars_to_analyze <- eocrc_significant_vars
  } else {
    # M_stage 대신 M_stage_M1 사용
    vars_to_analyze <- gsub("M_stage", "M_stage_M1", locrc_significant_vars)
  }
  
  # 종속변수와 분석변수만 선택
  analysis_data <- analysis_data[, c("암진단후생존일수.Survival.period.", 
                                   "사망여부.Death.", 
                                   vars_to_analyze)]
  
  # 결측치가 있는 행 제거
  complete_cases <- complete.cases(analysis_data)
  analysis_data <- analysis_data[complete_cases, ]
  
  # 모델 공식 생성 (선택된 변수들만 포함)
  formula_str <- paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", 
                      paste(vars_to_analyze, collapse = " + "))
  
  # 다변량 Cox 회귀 모델 적합
  tryCatch({
    cox_model <- coxph(as.formula(formula_str), data = analysis_data)
      
    # 모델 요약
    cox_summary <- summary(cox_model)
    
    # 결과 추출
    results <- data.frame(
      Variable = rownames(cox_summary$coefficients),
      HR = exp(cox_model$coefficients),
      CI_lower = exp(cox_summary$conf.int[, 3]),
      CI_upper = exp(cox_summary$conf.int[, 4]),
      p_value = cox_summary$coefficients[, 5],
      stringsAsFactors = FALSE
    )
    
    # 결과 정렬 (p-value 기준)
    results <- results[order(results$p_value), ]
    
    # 결과 출력
    cat("\n[다변량 분석 결과]\n")
    print(kable(results, digits = 3, format = "simple"))
    
    # 유의한 변수 필터링 (p < 0.25)
    significant_vars <- results$Variable[results$p_value < 0.25]
    
    if (length(significant_vars) > 0) {
      cat("\n[유의미한 변수 (p < 0.25)]\n")
      print(kable(results[results$p_value < 0.25, ], digits = 3, format = "simple"))
      
      # 유의한 변수만으로 모델 재적합
      formula_sig <- as.formula(paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", 
                                     paste(significant_vars, collapse = " + ")))
      sig_model <- coxph(formula_sig, data = analysis_data)
      
      # 모델 적합도 검정 (Likelihood ratio test)
      lrtest <- anova(sig_model, test = "Chisq")
      cat("\n[모델 적합도 검정 (Likelihood ratio test)]\n")
      print(lrtest)
      
      # 모델의 Harrell's C-index 계산
      c_index <- concordance(sig_model)$concordance
      cat("\n[모델의 Harrell's C-index]", round(c_index, 3), "\n")
      
      return(list(
        full_model = cox_model,
        significant_model = sig_model,
        results = results,
        significant_results = results[results$p_value < 0.25, ],
        c_index = c_index
      ))
    } else {
      cat("\n유의미한 변수가 없습니다.\n")
      return(NULL)
    }
    
  }, error = function(e) {
    cat("다변량 분석 중 오류 발생:", conditionMessage(e), "\n")
    return(NULL)
  })
}

# EOCRC 그룹 다변량 분석
eocrc_mv_results <- perform_multivariate_analysis(eocrc_data, "EOCRC")

# LOCRC 그룹 다변량 분석
locrc_mv_results <- perform_multivariate_analysis(locrc_data, "LOCRC")

# 다중공선성 검사 함수 (VIF 계산)
check_multicollinearity <- function(model) {
  if (require(car)) {
    vif_values <- car::vif(model)
    return(vif_values)
  } else {
    install.packages("car")
    library(car)
    vif_values <- car::vif(model)
    return(vif_values)
  }
}

# EOCRC 모델에 대한 다중공선성 검사 (유의한 변수가 있는 경우)
if (!is.null(eocrc_mv_results)) {
  cat("\n=== EOCRC 모델 다중공선성 검사 (VIF) ===\n")
  tryCatch({
    vif_eocrc <- check_multicollinearity(eocrc_mv_results$significant_model)
    print(vif_eocrc)
  }, error = function(e) {
    cat("다중공선성 검사 중 오류:", conditionMessage(e), "\n")
  })
}

# LOCRC 모델에 대한 다중공선성 검사 (유의한 변수가 있는 경우)
if (!is.null(locrc_mv_results)) {
  cat("\n=== LOCRC 모델 다중공선성 검사 (VIF) ===\n")
  tryCatch({
    vif_locrc <- check_multicollinearity(locrc_mv_results$significant_model)
    print(vif_locrc)
  }, error = function(e) {
    cat("다중공선성 검사 중 오류:", conditionMessage(e), "\n")
  })
}
