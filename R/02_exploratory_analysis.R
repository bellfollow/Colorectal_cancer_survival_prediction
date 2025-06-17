# 02_exploratory_analysis.R

# 필요한 패키지 로드
library(tidyverse)
library(VIM)
library(survival)
library(survminer)
library(corrplot)
library(GGally)
library(gridExtra)

# 데이터 로드 및 기본 정보 출력
train_data <- read.csv("pre_process/암임상_라이브러리_합성데이터_train.csv")
cat("데이터 차원:", dim(train_data), "\n")
cat("변수명:\n")
print(names(train_data))

# 변수 간 상관관계 분석 (개선된 버전)

# 3. 변수 간 상관관계 분석 (개선된 버전)
cat("\n=== 변수 간 상관관계 분석 ===\n")

# 수치형 변수만 선택하고 표준편차가 0인 열 제거
numeric_data <- train_data %>%
  select(where(is.numeric)) %>%
  select_if(~sd(.x, na.rm = TRUE) > 0)

cat("분석 대상 수치형 변수 개수:", ncol(numeric_data), "\n")

if(ncol(numeric_data) > 1) {
  # 상관관계 매트릭스 계산
  cor_matrix <- cor(numeric_data, use = "complete.obs")

  # 그래픽 디바이스 초기화
  plot.new()
  
  # 상관관계 시각화
  corrplot(cor_matrix, method = "color", type = "upper", 
           order = "hclust", 
           tl.cex = 0.7,  # 텍스트 크기를 더 작게 조정
           tl.col = "black",
           mar = c(0,0,0,0))  # 마진 설정

  # 생존 변수와의 상관관계가 높은 변수들 찾기
  if("암진단후생존일수.Survival.period." %in% colnames(cor_matrix)) {
    survival_cor <- cor_matrix[, "암진단후생존일수.Survival.period."]
    survival_cor <- survival_cor[names(survival_cor) != "암진단후생존일수.Survival.period."]
    survival_cor <- sort(abs(survival_cor), decreasing = TRUE)

    cat("\n생존일수와 상관관계가 높은 변수들 (상위 10개):\n")
    print(head(survival_cor, 10))
  }
}

# 4. 피처 그룹별 상관관계 분석 (개선된 버전)
cat("\n=== 피처 그룹별 상관관계 분석 ===\n")

# 피처 그룹 정의 (정규표현식 개선)
feature_groups <- list(
  clinical = grep("진단시연령|신장|체중", names(train_data), value = TRUE, ignore.case = TRUE),
  pathology = grep("조직학적|면역병리|분자병리", names(train_data), value = TRUE, ignore.case = TRUE),
  lifestyle = grep("음주|흡연", names(train_data), value = TRUE, ignore.case = TRUE),
  treatment = grep("수술|치료|방사선", names(train_data), value = TRUE, ignore.case = TRUE),
  stage = grep("병기|STAGE|TNM", names(train_data), value = TRUE, ignore.case = TRUE)
)

# 생존 관련 변수
survival_vars <- c("암진단후생존일수.Survival.period.", "사망여부.Death.")

# 그룹별 분석 결과 저장
group_results <- list()

for(group_name in names(feature_groups)) {
  cat("\n", toupper(group_name), "그룹 분석:\n")

  group_vars <- feature_groups[[group_name]]
  if(length(group_vars) > 0) {
    cat("포함된 변수들:", paste(group_vars, collapse = ", "), "\n")

    # 그룹 변수와 생존 변수 결합
    analysis_vars <- c(group_vars, survival_vars)
    group_data <- train_data %>%
      select(all_of(analysis_vars)) %>%
      select(where(is.numeric)) %>%
      select_if(~sd(.x, na.rm = TRUE) > 0)

    if(ncol(group_data) > 1 && "암진단후생존일수.Survival.period." %in% names(group_data)) {
      # 상관관계 계산
      group_cor <- cor(group_data, use = "complete.obs")
      survival_correlations <- group_cor[, "암진단후생존일수.Survival.period."]
      survival_correlations <- survival_correlations[names(survival_correlations) != "암진단후생존일수.Survival.period."]

      if(length(survival_correlations) > 0) {
        # 절댓값 기준으로 정렬
        survival_correlations <- sort(abs(survival_correlations), decreasing = TRUE)

        cat("생존일수와의 상관관계:\n")
        print(round(survival_correlations, 3))

        # 결과 저장
        group_results[[group_name]] <- data.frame(
          Variable = names(survival_correlations),
          Correlation = as.numeric(survival_correlations),
          Group = group_name
        )
      }
    } else {
      cat("분석 가능한 수치형 변수가 없습니다.\n")
    }
  } else {
    cat("해당 패턴과 일치하는 변수가 없습니다.\n")
  }
}

# 모든 그룹 결과 통합
if(length(group_results) > 0) {
  all_correlations <- do.call(rbind, group_results)
  all_correlations <- all_correlations[order(abs(all_correlations$Correlation), decreasing = TRUE), ]

  cat("\n=== 전체 그룹별 생존일수 상관관계 요약 ===\n")
  print(all_correlations)
}

# 5. 생존분석 시각화 (개선된 버전)
cat("\n=== 생존분석 시각화 ===\n")

# 생존 객체 생성
if("암진단후생존일수.Survival.period." %in% names(train_data) &&
   "사망여부.Death." %in% names(train_data)) {

  surv_obj <- Surv(time = train_data$`암진단후생존일수.Survival.period.`,
                   event = train_data$`사망여부.Death.`)

  # Kaplan-Meier 추정
  km_fit <- survfit(surv_obj ~ 1)

  # 기본 생존곡선 플롯
  plot(km_fit,
       xlab = "Time (days)",
       ylab = "Survival Probability",
       main = "Kaplan-Meier Survival Curve",
       conf.int = TRUE)

  # ggsurvplot을 사용한 향상된 플롯 (survminer 패키지)
  if("survminer" %in% rownames(installed.packages())) {
    ggsurvplot(
      km_fit,
      data = train_data,  # 데이터 명시적으로 전달
      conf.int = TRUE,
      pval = TRUE,
      risk.table = TRUE,
      xlim = c(0, max(train_data$`암진단후생존일수.Survival.period.`, na.rm = TRUE)),
      title = "Kaplan-Meier Survival Curve",
      xlab = "Time (days)",
      ylab = "Survival Probability"
    )
  }

  # 생존 요약 통계
  cat("\n생존 요약 통계:\n")
  print(summary(km_fit))
}

# 6. 추가 탐색적 분석
cat("\n=== 추가 탐색적 분석 ===\n")

# 범주형 변수 분석
categorical_vars <- train_data %>%
  select(where(is.character)) %>%
  names()

if(length(categorical_vars) > 0) {
  cat("범주형 변수들:\n")
  for(var in categorical_vars) {
    cat("\n", var, ":\n")
    print(table(train_data[[var]], useNA = "ifany"))
  }
}

# 수치형 변수 분포 확인
if(ncol(numeric_data) > 0) {
  cat("\n수치형 변수 분포 요약:\n")
  numeric_summary <- numeric_data %>%
    summarise_all(list(
      mean = ~mean(.x, na.rm = TRUE),
      median = ~median(.x, na.rm = TRUE),
      sd = ~sd(.x, na.rm = TRUE),
      min = ~min(.x, na.rm = TRUE),
      max = ~max(.x, na.rm = TRUE)
    ))

  print(t(numeric_summary))
}

cat("\n=== 탐색적 데이터 분석 완료 ===\n")
