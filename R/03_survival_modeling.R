# 03_survival_modeling.R
# 생존분석 모델링 스크립트

# 필요한 패키지 로드
library(survival)
library(survminer)

# 데이터 로드
train_data <- read_csv("pre_process/암임상_라이브러리_합성데이터_train.csv")

# 생존 객체 생성
surv_obj <- Surv(time = train_data$`Survival period`, event = train_data$Death)

# 1. Cox 비례위험모델
cox_model <- coxph(surv_obj ~ ., data = train_data)
print(summary(cox_model))

# 2. Kaplan-Meier 생존곡선
km_fit <- survfit(surv_obj ~ 1)
print("\nKaplan-Meier 생존곡선:")
ggsurvplot(km_fit, data = train_data,
           xlab = "Time (days)", ylab = "Survival Probability")

# 3. 모델 성능 평가
print("\n모델 성능 지표:")
print(concordance(cox_model))
