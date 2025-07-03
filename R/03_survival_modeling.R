# 03_survival_modeling.R-
# 생존분석 모델링 스크립트

# 필요한 패키지 로드
library(survival)
library(survminer)
library(tidyverse)
library(timeROC)

# 1. 데이터 로드 -------------------------------------------------------------
cat("데이터 로드 중...\n")

# 훈련 및 테스트 데이터 로드 (EOCRC와 LOCRC)
train_eocrc <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8-BOM")
train_locrc <- read.csv("data/1_train_LOCRC.csv", fileEncoding = "UTF-8-BOM")
test_eocrc <- read.csv("data/1_test_EOCRC.csv", fileEncoding = "UTF-8-BOM")
test_locrc <- read.csv("data/1_test_LOCRC.csv", fileEncoding = "UTF-8-BOM")

# 2. 유의한 변수 불러오기 ---------------------------------------------------
cat("\n유의한 변수 목록을 불러오는 중...\n")

# 결과 디렉토리 확인 및 생성
if (!dir.exists("results")) {
  stop("results 디렉토리를 찾을 수 없습니다. 먼저 02_03_exploratory_analysis.R을 실행해주세요.")
}

# 유의한 변수 파일 경로
eocrc_var_file <- "results/eocrc_multivariate_significant_vars_p025.csv"
locrc_var_file <- "results/locrc_multivariate_significant_vars_p025.csv"

# 파일 존재 여부 확인
if (!file.exists(eocrc_var_file) || !file.exists(locrc_var_file)) {
  stop("유의 변수 파일을 찾을 수 없습니다. 먼저 02_03_exploratory_analysis.R을 실행해주세요.")
}

# 유의 변수 로드
eocrc_significant_vars <- read.csv(eocrc_var_file, fileEncoding = "UTF-8")
locrc_significant_vars <- read.csv(locrc_var_file, fileEncoding = "UTF-8")

# 변수 이름 표준화 함수
standardize_stage_vars <- function(vars) {
  # T_stage, N_stage, M_stage 관련 변수명을 표준화
  vars <- gsub(".*T_stage.*", "T_stage", vars)
  vars <- gsub(".*N_stage.*", "N_stage", vars)
  vars <- gsub(".*M_stage.*", "M_stage", vars)
  return(unique(vars))  # 중복 제거
}

# 변수 목록 추출 및 표준화
eocrc_vars <- standardize_stage_vars(as.character(eocrc_significant_vars$Variable))
locrc_vars <- standardize_stage_vars(as.character(locrc_significant_vars$Variable))

# 데이터프레임의 컬럼명도 동일하게 변경
standardize_df_cols <- function(df) {
  colnames(df) <- gsub(".*T_stage.*", "T_stage", colnames(df))
  colnames(df) <- gsub(".*N_stage.*", "N_stage", colnames(df))
  colnames(df) <- gsub(".*M_stage.*", "M_stage", colnames(df))
  return(df)
}

# 모든 데이터프레임에 컬럼명 표준화 적용
train_eocrc <- standardize_df_cols(train_eocrc)
train_locrc <- standardize_df_cols(train_locrc)
test_eocrc <- standardize_df_cols(test_eocrc)
test_locrc <- standardize_df_cols(test_locrc)

cat("\n[EOCRC 유의 변수 (p < 0.25)]\n")
print(eocrc_vars)
cat("\n[LOCRC 유의 변수 (p < 0.25)]\n")
print(locrc_vars)

# 3. 생존 분석 함수 정의 ----------------------------------------------------

# 생존 분석 수행 함수
perform_survival_analysis <- function(data, vars, group_name) {
  cat("\n[생존 분석 시작: ", group_name, "]\n", sep="")
  
  # 생존 객체 생성
  surv_obj <- Surv(time = data$암진단후생존일수.Survival.period., 
                  event = data$사망여부.Death.)
  
  # 공식 생성
  if (length(vars) > 0) {
    formula_str <- paste("surv_obj ~", paste(vars, collapse = " + "))
    formula_obj <- as.formula(formula_str)
    
    # Cox 비례위험모델 적합
    cat("\nCox 비례위험모델 적합 중...\n")
    cox_model <- coxph(formula_obj, data = data)
    
    # 결과 요약
    cat("\n[모델 요약]\n")
    print(summary(cox_model))
    
    # 모델 성능 평가
    c_index <- concordance(cox_model)$concordance
    cat("\n[모델 성능]\n")
    cat("Harrell's C-index:", round(c_index, 3), "\n")
    
    # Kaplan-Meier 생존곡선
    cat("\nKaplan-Meier 생존곡선 생성 중...\n")
    km_fit <- survfit(surv_obj ~ 1, data = data)
    print(km_fit)
    
    # 생존곡선 시각화
    plot(km_fit, main = paste("Kaplan-Meier Survival Curve -", group_name),
         xlab = "Time (days)", ylab = "Survival Probability")
    
    return(list(cox_model = cox_model, km_fit = km_fit, c_index = c_index))
  } else {
    cat("\n유의한 변수가 없어 모델을 적합할 수 없습니다.\n")
    return(NULL)
  }
}

# 4. 각 그룹별로 생존 분석 수행 ---------------------------------------------

# EOCRC 생존 분석
if (length(eocrc_vars) > 0) {
  eocrc_result <- perform_survival_analysis(train_eocrc, eocrc_vars, "EOCRC")
}

# LOCRC 생존 분석
if (length(locrc_vars) > 0) {
  locrc_result <- perform_survival_analysis(train_locrc, locrc_vars, "LOCRC")
}

# 4. Kaplan-Meier 생존곡선 및 log-rank test -----------------------------------
cat("\n[4. Kaplan-Meier 생존곡선 및 log-rank test]\n")

# 생존 분석 함수 업데이트 (log-rank test 추가)
perform_survival_analysis <- function(data, vars, group_name) {
  cat("\n[생존 분석 시작: ", group_name, "]\n", sep="")
  
  # 생존 객체 생성
  surv_obj <- Surv(time = data$암진단후생존일수.Survival.period., 
                  event = data$사망여부.Death.)
  
  # 공식 생성
  if (length(vars) > 0) {
    formula_str <- paste("surv_obj ~", paste(vars, collapse = " + "))
    formula_obj <- as.formula(formula_str)
    
    # Cox 비례위험모델 적합
    cat("\nCox 비례위험모델 적합 중...\n")
    cox_model <- coxph(formula_obj, data = data)
    
    # 결과 요약
    cat("\n[모델 요약]\n")
    print(summary(cox_model))
    
    # 모델 성능 평가
    c_index <- concordance(cox_model)$concordance
    cat("\n[모델 성능]\n")
    cat("Harrell's C-index:", round(c_index, 3), "\n")
    
    # Kaplan-Meier 생존곡선
    cat("\nKaplan-Meier 생존곡선 생성 중...\n")
    # Create survival object directly in survfit
    km_fit <- survfit(Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~ 1, data = data)
    
    # 생존곡선 시각화
    km_plot <- ggsurvplot(km_fit, 
                         data = data,
                         title = paste("Kaplan-Meier Survival Curve -", group_name),
                         xlab = "Time (days)", 
                         ylab = "Survival Probability",
                         risk.table = TRUE,
                         pval = TRUE,
                         conf.int = TRUE,
                         ggtheme = theme_minimal())
    
    # 위험군 분류를 위한 중위수 기준점 계산
    risk_scores <- predict(cox_model, type = "risk")
    median_risk <- median(risk_scores, na.rm = TRUE)
    data$risk_group <- ifelse(risk_scores > median_risk, "High Risk", "Low Risk")
    
    # 위험군별 생존곡선 및 log-rank test
    if (length(unique(na.omit(data$risk_group))) > 1) {
      km_risk_fit <- survfit(Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~ risk_group, 
                            data = data)
      
      # Log-rank test
      logrank_test <- survdiff(Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~ risk_group, 
                              data = data)
      p_value <- 1 - pchisq(logrank_test$chisq, length(logrank_test$n) - 1)
      
      # 위험군별 생존곡선 플롯
      risk_plot <- ggsurvplot(km_risk_fit, 
                             data = data,
                             title = paste("Risk Group Survival -", group_name),
                             xlab = "Time (days)",
                             ylab = "Survival Probability",
                             pval = TRUE,
                             pval.method = TRUE,
                             risk.table = TRUE,
                             legend.labs = c("High Risk", "Low Risk"),
                             palette = c("red", "blue"),
                             ggtheme = theme_minimal())
      
      cat("\n[Log-rank Test 결과]\n")
      cat("p-value:", format.pval(p_value, digits = 3), "\n")
    } else {
      risk_plot <- NULL
      cat("\n경고: 위험군 분류를 위한 충분한 데이터가 없습니다.\n")
    }
    
    return(list(cox_model = cox_model, 
                km_fit = km_fit,
                km_plot = km_plot,
                risk_plot = risk_plot,
                c_index = c_index,
                risk_scores = risk_scores,
                data = data))
  } else {
    cat("\n유의한 변수가 없어 모델을 적합할 수 없습니다.\n")
    return(NULL)
  }
}

# 5. 위험점수 기반 고/저위험군 분류 및 KM 곡선 ------------------------------
cat("\n[5. 위험점수 기반 고/저위험군 분류]\n")

# EOCRC와 LOCRC에 대해 분석 수행
if (length(eocrc_vars) > 0) {
  eocrc_result <- perform_survival_analysis(train_eocrc, eocrc_vars, "EOCRC")
  print(eocrc_result$km_plot)
  if (!is.null(eocrc_result$risk_plot)) {
    print(eocrc_result$risk_plot)
  }
}

if (length(locrc_vars) > 0) {
  locrc_result <- perform_survival_analysis(train_locrc, locrc_vars, "LOCRC")
  print(locrc_result$km_plot)
  if (!is.null(locrc_result$risk_plot)) {
    print(locrc_result$risk_plot)
  }
}

# 6. 테스트셋 평가 ---------------------------------------------------------
cat("\n[6. 테스트셋 평가]\n")

# 테스트셋 평가 함수
evaluate_test_set <- function(model, test_data, group_name) {
  if (is.null(model)) return(NULL)
  
  cat("\n[테스트셋 평가 - ", group_name, "]\n", sep="")
  
  # 위험 점수 계산
  test_risk_scores <- predict(model, newdata = test_data, type = "risk")
  
  # 위험 점수 요약
  cat("\n[위험 점수 요약]\n")
  print(summary(test_risk_scores))
  
  # 위험군 분류
  median_risk <- median(predict(model, type = "risk"), na.rm = TRUE)
  test_data$risk_group <- ifelse(test_risk_scores > median_risk, "High Risk", "Low Risk")
  
  # 생존 객체 생성
  test_surv_obj <- Surv(time = test_data$암진단후생존일수.Survival.period., 
                       event = test_data$사망여부.Death.)
  
  # Concordance index 계산
  test_concordance <- concordance(test_surv_obj ~ test_risk_scores)
  cat("\n[Concordance Index]\n")
  print(test_concordance)
  
  # 시간 의존적 ROC 곡선 (1년, 3년, 5년 생존률)
  library(timeROC)
  
  # 1년, 3년, 5년 생존률 예측
  times <- c(365, 1095, 1825)  # 1년, 3년, 5년 (일 단위)
  
  roc_results <- lapply(times, function(t) {
    roc <- timeROC(T = test_data$암진단후생존일수.Survival.period.,
                   delta = test_data$사망여부.Death.,
                   marker = test_risk_scores,
                   cause = 1,
                   times = t,
                   ROC = TRUE)
    return(roc)
  })
  
  # ROC 곡선 시각화
  plot(roc_results[[1]]$FP[,2], roc_results[[1]]$TP[,2], 
       type = "l", lwd = 2, col = "red",
       xlab = "1 - Specificity", ylab = "Sensitivity",
       main = paste("Time-dependent ROC Curves -", group_name))
  lines(roc_results[[2]]$FP[,2], roc_results[[2]]$TP[,2], 
        lwd = 2, col = "blue")
  lines(roc_results[[3]]$FP[,2], roc_results[[3]]$TP[,2], 
        lwd = 2, col = "green")
  abline(0, 1, lty = 2)
  legend("bottomright", 
         legend = c(paste0("1-year (AUC = ", round(roc_results[[1]]$AUC[2], 3), ")"),
                   paste0("3-year (AUC = ", round(roc_results[[2]]$AUC[2], 3), ")"),
                   paste0("5-year (AUC = ", round(roc_results[[3]]$AUC[2], 3), ")")),
         col = c("red", "blue", "green"), lwd = 2, bty = "n")
  
  # 정확도 계산 (예: 1년 생존 예측)
  predicted_survival <- ifelse(test_risk_scores > median_risk, 0, 1)  # 위험이 높으면 생존률 낮음
  actual_survival <- ifelse(test_data$암진단후생존일수.Survival.period. > 365 & 
                            test_data$사망여부.Death. == 0, 1, 0)
  
  accuracy <- mean(predicted_survival == actual_survival, na.rm = TRUE)
  cat("\n[1년 생존 예측 정확도]", round(accuracy, 3), "\n")
  
  return(list(risk_scores = test_risk_scores,
              roc_results = roc_results,
              accuracy = accuracy))
}

# 테스트셋 평가 실행
if (exists("eocrc_result") && !is.null(eocrc_result)) {
  eocrc_test_result <- evaluate_test_set(eocrc_result$cox_model, test_eocrc, "EOCRC")
}

if (exists("locrc_result") && !is.null(locrc_result)) {
  locrc_test_result <- evaluate_test_set(locrc_result$cox_model, test_locrc, "LOCRC")
}

# 7. 변수 중요도 시각화 (선택) ---------------------------------------------
cat("\n[7. 변수 중요도 시각화]\n")

# 변수 중요도 시각화 함수
plot_variable_importance <- function(model, title) {
  if (is.null(model)) return(NULL)
  
  # 계수 추출
  coef_df <- data.frame(
    Variable = names(coef(model)),
    Coef = coef(model),
    stringsAsFactors = FALSE
  )
  
  # 계수 절대값으로 정렬
  coef_df <- coef_df[order(abs(coef_df$Coef), decreasing = TRUE), ]
  coef_df$Variable <- factor(coef_df$Variable, levels = rev(coef_df$Variable))
  
  # 시각화
  p <- ggplot(coef_df, aes(x = Coef, y = Variable, fill = Coef > 0)) +
    geom_col() +
    geom_vline(xintercept = 0, linetype = "dashed") +
    labs(title = paste("Variable Importance -", title),
         x = "Coefficient",
         y = "") +
    theme_minimal() +
    theme(legend.position = "none")
  
  print(p)
  return(p)
}

# 변수 중요도 시각화 실행
if (exists("eocrc_result") && !is.null(eocrc_result)) {
  plot_variable_importance(eocrc_result$cox_model, "EOCRC")
}

if (exists("locrc_result") && !is.null(locrc_result)) {
  plot_variable_importance(locrc_result$cox_model, "LOCRC")
}
 