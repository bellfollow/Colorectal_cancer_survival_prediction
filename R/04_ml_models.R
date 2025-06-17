# 04_ml_models.R
# 머신러닝 모델링 스크립트

# 필요한 패키지 로드
library(tidyverse)
library(randomForestSRC)
library(xgboost)

# 데이터 로드
train_data <- read_csv("../pre_process/암임상_라이브러리_합성데이터_train.csv")

# 1. Random Forest
rf_model <- rfsrc(Surv(time = `Survival period`, status = Death) ~ ., 
                 data = train_data)
print(summary(rf_model))

# 2. XGBoost
xgb_model <- xgboost(
  data = as.matrix(train_data %>% select(-c("Survival period", "Death"))),
  label = train_data$`Survival period`,
  objective = "survival:cox",
  nrounds = 100
)

# 3. 모델 성능 비교
print("\n모델 성능 지표:")
# 추가 코드 필요
