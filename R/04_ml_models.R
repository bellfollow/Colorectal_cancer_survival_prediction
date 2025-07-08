# 04_ml_models.R
# 머신러닝 모델링 스크립트

# 필요한 패키지 로드
library(tidyverse)
library(survival)
library(randomForestSRC)
library(xgboost)
library(gbm)
library(caret)
library(smotefamily)
library(survminer)
library(timeROC)
library(patchwork)


# 훈련 및 테스트 데이터 로드 (EOCRC와 LOCRC)
eocrc_train <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8-BOM")
locrc_train <- read.csv("data/1_train_LOCRC.csv", fileEncoding = "UTF-8-BOM")
eocrc_test <- read.csv("data/1_test_EOCRC.csv", fileEncoding = "UTF-8-BOM")
locrc_test <- read.csv("data/1_test_LOCRC.csv", fileEncoding = "UTF-8-BOM")

# 유의한 변수 불러오기 ---------------------------------------------------
cat("\n유의한 변수 목록을 불러오는 중...\n")

# 유의 변수 파일 경로
eocrc_var_file <- "results/eocrc_multivariate_significant_vars_p025.csv"
locrc_var_file <- "results/locrc_multivariate_significant_vars_p025.csv"

# 유의 변수 로드
eocrc_significant_vars <- read.csv(eocrc_var_file, fileEncoding = "UTF-8")
locrc_significant_vars <- read.csv(locrc_var_file, fileEncoding = "UTF-8")

# 변수 이름 표준화 함수 (03_survival_modeling.R과 동일)
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

# 생존 시간 및 상태 변수명 설정
time_col <- "암진단후생존일수.Survival.period."
status_col <- "사망여부.Death."

# 데이터를 리스트로 구성
eocrc_data <- list(train = eocrc_train, test = eocrc_test)
locrc_data <- list(train = locrc_train, test = locrc_test)

# 1, 3, 5년 생존 여부 변수 추가 (Died/Survived 팩터)
add_survival_status <- function(df) {
  df %>%
    dplyr::mutate(
      survived_1yr = factor(ifelse(!!sym(time_col) > 365, "Survived", ifelse(!!sym(status_col) == 1, "Died", NA)), levels = c("Died", "Survived")),
      survived_3yr = factor(ifelse(!!sym(time_col) > 365 * 3, "Survived", ifelse(!!sym(status_col) == 1, "Died", NA)), levels = c("Died", "Survived")),
      survived_5yr = factor(ifelse(!!sym(time_col) > 365 * 5, "Survived", ifelse(!!sym(status_col) == 1, "Died", NA)), levels = c("Died", "Survived"))
    )
}

eocrc_train <- add_survival_status(eocrc_train)
eocrc_test <- add_survival_status(eocrc_test)
locrc_train <- add_survival_status(locrc_train)
locrc_test <- add_survival_status(locrc_test)

# 연도별 생존 라벨 생성 함수
create_survival_labels <- function(data, time_col, status_col, years = c(1, 3, 5)) {
  # 일수를 연도로 변환 (1년 = 365.25일)
  data <- data %>%
    mutate(survival_years = .data[[time_col]] / 365.25)
  
  # 각 연도별로 생존 여부 생성
  for (year in years) {
    # 1: 해당 기간 내 사망, 0: 생존, NA: 추적 관찰 기간 부족
    data[[paste0("survived_", year, "yr")]] <- ifelse(
      data$survival_years >= year,  # 생존 기간이 해당 연수 이상
      1,                            # 1: 생존
      ifelse(
        data[[status_col]] == 1 & data$survival_years < year,  # 해당 기간 내 사망
        0,                            # 0: 사망
        NA                            # 추적 관찰 기간 부족
      )
    )
  }
  
  return(data)
}

# EOCRC와 LOCRC 데이터에 적용
eocrc_data$train <- create_survival_labels(eocrc_data$train, time_col, status_col)
eocrc_data$test <- create_survival_labels(eocrc_data$test, time_col, status_col)
locrc_data$train <- create_survival_labels(locrc_data$train, time_col, status_col)
locrc_data$test <- create_survival_labels(locrc_data$test, time_col, status_col)

# 클래스 불균형 확인
check_class_balance <- function(data, group_name) {
  cat("\n[클래스 분포 확인 -", group_name, "]\n")
  for (year in c(1, 3, 5)) {
    col_name <- paste0("survived_", year, "yr")
    tab <- table(data[[col_name]], useNA = "ifany")
    cat(sprintf("\n%d년 생존 여부:\n", year))
    print(tab)
    if (length(tab) > 1) {
      ratio <- round(tab[1] / tab[2], 2)
      cat(sprintf("사망:생존 비율 = 1:%.2f\n", ratio))
    }
  }
}

# 훈련 데이터의 클래스 불균형 확인
check_class_balance(eocrc_data$train, "EOCRC 훈련 데이터")
check_class_balance(locrc_data$train, "LOCRC 훈련 데이터")

# SMOTE 적용 함수
apply_smote_if_needed <- function(data, target_col, predictor_vars, group_name) {
  cat(sprintf("\n--- SMOTE 적용 검토: %s, %s ---\n", group_name, target_col))

  # 1. NA를 포함하는 행 전체 제거 (분석에 사용할 열만 선택)
  data_for_smote <- data %>% 
    dplyr::select(all_of(c(predictor_vars, target_col))) %>% 
    na.omit()

  if (nrow(data_for_smote) < 10) {
    cat("NA 제거 후 유효 데이터가 너무 적어 SMOTE를 건너<binary data, 1 bytes>니다.\n")
    return(data) # 원본 데이터 반환
  }

  class_counts <- table(data_for_smote[[target_col]])
  cat("정제된 데이터의 클래스 분포:\n")
  print(class_counts)

  if (length(class_counts) < 2) {
    cat("클래스가 하나뿐이라 SMOTE를 건너<binary data, 1 bytes>니다.\n")
    return(data) # 원본 데이터 반환
  }

  minority_class_label <- names(which.min(class_counts))
  majority_class_label <- names(which.max(class_counts))
  ratio <- class_counts[majority_class_label] / class_counts[minority_class_label]
  cat(sprintf("클래스 비율 (다수/소수): %.2f\n", ratio))

  if (ratio >= 5) {
    cat("클래스 불균형이 심각하여 (비율 >= 5) SMOTE를 적용합니다.\n")

    # target_col이 팩터 '0', '1'을 가질 수 있으므로, 숫자 0에 해당하는 클래스를 0으로 변환
    target_numeric <- ifelse(data_for_smote[[target_col]] == levels(data_for_smote[[target_col]])[1], 0, 1)
    smote_X <- data_for_smote[, predictor_vars, drop = FALSE] %>% 
      dplyr::mutate(dplyr::across(everything(), as.numeric))

    minority_size <- min(sum(target_numeric == 0), sum(target_numeric == 1))
    k_val <- min(5, minority_size - 1)

    if (k_val < 1) {
      cat("소수 클래스 샘플이 너무 적어 SMOTE를 건너<binary data, 1 bytes>니다.\n")
      return(data) # 원본 데이터 반환
    }

    smote_result <- smotefamily::SMOTE(
      X = smote_X,
      target = target_numeric,
      K = k_val,
      dup_size = 0
    )

    # SMOTE 결과 데이터프레임 생성
    oversampled_data <- smote_result$data
    # 'class' 열을 원래 타겟 변수 이름으로 변경하고, 팩터로 변환
    oversampled_data <- oversampled_data %>% 
      dplyr::rename(!!target_col := class) %>% 
      dplyr::mutate(!!sym(target_col) := factor(!!sym(target_col), levels = c(0, 1), labels = c("Died", "Survived")))
    
    cat(sprintf("SMOTE 적용 후 데이터 크기: %d행, %d열\n", nrow(oversampled_data), ncol(oversampled_data)))
    print(table(oversampled_data[[target_col]]))
    
    return(oversampled_data)

  } else {
    cat("클래스 불균형이 심각하지 않아 SMOTE를 적용하지 않습니다.\n")
    return(data) # 원본 데이터 반환
  }
}

# 각 연도별로 SMOTE 적용을 위한 데이터셋 리스트 생성
eocrc_smote_train <- list()
locrc_smote_train <- list()

years_to_process <- c(1, 3, 5)

for (year in years_to_process) {
  target_col_name <- paste0("survived_", year, "yr")
  
  # EOCRC
  eocrc_smote_train[[target_col_name]] <- apply_smote_if_needed(
    data = eocrc_data$train,
    target_col = target_col_name,
    predictor_vars = eocrc_vars,
    group_name = "EOCRC"
  )
  
  # LOCRC
  locrc_smote_train[[target_col_name]] <- apply_smote_if_needed(
    data = locrc_data$train,
    target_col = target_col_name,
    predictor_vars = locrc_vars,
    group_name = "LOCRC"
  )
}

# --- Random Survival Forest (RSF) 모델링 ---

# RSF 모델 학습 및 평가 함수
# 1. Random Survival Forest 모델링 함수
# ----------------------------------------------------------------------------
train_evaluate_rsf <- function(train_data, test_data, time_col, status_col, predictor_vars, group_name) {
  cat(sprintf("\n--- RSF 모델링 시작: %s ---\n", group_name))
  
  # 생존 분석에 필요한 데이터만 선택 및 전처리
  

  # 생존 분석에 필요한 데이터만 선택 및 전처리
  train_surv <- train_data %>% 
    dplyr::select(all_of(c(time_col, status_col, predictor_vars))) %>%
    dplyr::mutate(dplyr::across(where(is.character), as.factor)) %>% # 문자형을 팩터형으로 변환
    na.omit()
  
  test_surv <- test_data %>%
    dplyr::select(all_of(c(time_col, status_col, predictor_vars))) %>% 
    dplyr::mutate(dplyr::across(where(is.character), as.factor)) %>% # 문자형을 팩터형으로 변환
    na.omit()
  
  # NA 값 중앙값으로 대체
  for(i in predictor_vars){
    if(any(is.na(train_surv[[i]]))) train_surv[is.na(train_surv[[i]]), i] <- median(train_surv[[i]], na.rm = TRUE)
    if(any(is.na(test_surv[[i]]))) test_surv[is.na(test_surv[[i]]), i] <- median(test_surv[[i]], na.rm = TRUE)
  }

  # 모델 공식
  formula_rsf <- as.formula(paste("Surv(", time_col, ",", status_col, ") ~ ."))

  # RSF 모델 학습
  rsf_model <- rfsrc(formula = formula_rsf, data = train_surv, ntree = 1000, importance = TRUE)

  cat("RSF 모델 학습 완료\n")
  print(rsf_model)

  # 테스트셋 평가
  prediction <- predict(rsf_model, newdata = test_surv)
  
  # C-index 계산
  c_index <- concordance(Surv(test_surv[[time_col]], test_surv[[status_col]]) ~ prediction$predicted)$concordance
  cat(sprintf("\n테스트셋 C-index: %.3f\n", c_index))

  # 변수 중요도 추출 및 시각화
  vimp_result <- randomForestSRC::vimp(rsf_model)
  vimp_df <- data.frame(
    Variable = names(vimp_result$importance),
    Importance = vimp_result$importance
  )
  
  vimp_plot <- ggplot(vimp_df, aes(x = reorder(Variable, Importance), y = Importance)) +
    geom_col(fill = "skyblue") +
    coord_flip() +
    labs(
      title = paste("RSF Variable Importance -", group_name),
      x = "Variables",
      y = "Permutation Importance"
    ) +
    theme_minimal()
  
  print(vimp_plot)

  return(list(model = rsf_model, c_index = c_index, vimp_plot = vimp_plot))
}

# EOCRC와 LOCRC에 대해 RSF 모델링 수행
eocrc_rsf_result <- train_evaluate_rsf(
  train_data = eocrc_data$train, # RSF는 자체적으로 생존시간을 다루므로 SMOTE 적용 전 원본 데이터 사용
  test_data = eocrc_data$test,
  time_col = time_col,
  status_col = status_col,
  predictor_vars = eocrc_vars,
  group_name = "EOCRC"
)

locrc_rsf_result <- train_evaluate_rsf(
  train_data = locrc_data$train,
  test_data = locrc_data$test,
  time_col = time_col,
  status_col = status_col,
  predictor_vars = locrc_vars,
  group_name = "LOCRC"
)

# --- Classification Models ---

# 분류 모델 학습 및 평가 함수
train_evaluate_classifier <- function(train_data, test_data, target_col, predictor_vars, group_name, model_method) {
  cat(sprintf("\n--- %s 모델링 시작: %s, %s ---\n", toupper(model_method), group_name, target_col))

  # 훈련 데이터 준비
  train_df <- train_data[, c(predictor_vars, target_col)]
  # NA 값을 중앙값으로 대체
  for(i in predictor_vars){
    if(any(is.na(train_df[[i]]))) train_df[is.na(train_df[[i]]), i] <- median(train_df[[i]], na.rm = TRUE)
  }
  train_df <- na.omit(train_df) # 타겟 변수에 NA가 있는 경우 행 제거

  if (length(unique(train_df[[target_col]])) < 2) {
    cat("훈련 데이터에 클래스가 하나뿐이라 모델링을 건너<binary data, 1 bytes>니다.\n")
    return(NULL)
  }

  train_df[[target_col]] <- as.factor(train_df[[target_col]])
  levels(train_df[[target_col]]) <- make.names(levels(train_df[[target_col]]))

  # 테스트 데이터 준비
  test_df <- test_data[, c(predictor_vars, target_col)]
  for(i in predictor_vars){
    if(any(is.na(test_df[[i]]))) test_df[is.na(test_df[[i]]), i] <- median(test_df[[i]], na.rm = TRUE)
  }
  test_df <- na.omit(test_df) # 타겟 변수에 NA가 있는 경우 행 제거
  test_df[[target_col]] <- as.factor(test_df[[target_col]])
  # 훈련 데이터와 동일한 레벨을 적용하기 전에, 훈련 데이터에서 이미 변환된 유효한 레벨을 사용합니다.
  levels(test_df[[target_col]]) <- levels(train_df[[target_col]])

  # 모델 학습 (caret 사용)
  set.seed(123)
  fit_control <- caret::trainControl(method = "cv", number = 5, classProbs = TRUE, summaryFunction = caret::twoClassSummary)

  model <- caret::train(
    as.formula(paste(target_col, "~ .")),
    data = train_df,
    method = model_method, # 'rf', 'xgbTree', 'gbm' 등
    trControl = fit_control,
    metric = "ROC",
    preProcess = c("center", "scale"),
    tuneLength = 3
  )

  # 예측 및 평가
  predictions <- predict(model, newdata = test_df)
  pred_probs <- predict(model, newdata = test_df, type = "prob")

  # 혼동 행렬
  cm <- caret::confusionMatrix(predictions, test_df[[target_col]])
  cat("\nConfusion Matrix:\n")
  print(cm)

  # AUC
  # roc 객체를 생성할 때, 예측 확률의 두 번째 열(긍정 클래스)을 사용합니다.
  # 열 이름이 X0, X1으로 변경되었기 때문에 하드코딩 대신 위치 기반으로 선택합니다.
  roc_obj <- pROC::roc(test_df[[target_col]], pred_probs[, 2])
  auc_val <- pROC::auc(roc_obj)
  cat(sprintf("\nTest Set AUC: %.3f\n", auc_val))

  return(list(model = model, confusion_matrix = cm, auc = auc_val))
}

# 각 연도별, 그룹별, 모델별로 모델링 수행
model_methods <- c("rf", "xgbTree", "gbm") # Random Forest, XGBoost, Gradient Boosting
classification_results <- list()

for (model_method in model_methods) {
  classification_results[[model_method]] <- list()
  for (year in years_to_process) {
    target_col_name <- paste0("survived_", year, "yr")
    
    # EOCRC
    classification_results[[model_method]][[paste0("eocrc_", year, "yr")]] <- train_evaluate_classifier(
      train_data = eocrc_smote_train[[target_col_name]],
      test_data = eocrc_data$test,
      target_col = target_col_name,
      predictor_vars = eocrc_vars,
      group_name = "EOCRC",
      model_method = model_method
    )
    
    # LOCRC
    classification_results[[model_method]][[paste0("locrc_", year, "yr")]] <- train_evaluate_classifier(
      train_data = locrc_smote_train[[target_col_name]],
      test_data = locrc_data$test,
      target_col = target_col_name,
      predictor_vars = locrc_vars,
      group_name = "LOCRC",
      model_method = model_method
    )
  }
}

# --- 결과 저장 ---
cat("\n--- 모델링 결과 저장 중 ---\n")

# 결과 저장 디렉토리 생성
if (!dir.exists("results/models")) {
  dir.create("results/models", recursive = TRUE)
}

# 생존 분석 모델 결과 저장
saveRDS(eocrc_rsf_result, file = "results/models/eocrc_rsf_result.rds")
saveRDS(locrc_rsf_result, file = "results/models/locrc_rsf_result.rds")

# 분류 모델 결과 저장
saveRDS(classification_results, file = "results/models/classification_results.rds")

cat("모든 모델링 결과가 'results/models/' 폴더에 저장되었습니다.\n")
