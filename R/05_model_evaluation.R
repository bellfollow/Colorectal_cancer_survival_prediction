# 05_model_evaluation.R
# 모델 평가 스크립트

# 필요한 패키지 로드
library(survival)
library(survminer)
library(pROC)

# 데이터 로드
test_data <- read_csv("../pre_process/암임상_라이브러리_합성데이터_test.csv")

# 1. Cox 모델 성능 평가
cox_model <- readRDS("../models/cox_model.rds")
predictions <- predict(cox_model, newdata = test_data)

# 2. ROC Curve
roc_obj <- roc(test_data$Death, predictions)
plot(roc_obj, main = "ROC Curve")

# 3. Concordance Index
print("\nConcordance Index:")
print(concordance(cox_model, newdata = test_data))
