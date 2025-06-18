# 02_01_exploratory_analysis.R
#
# 대장암 환자의 생존 예측을 위한 추가 탐색적 데이터 분석(EDA) 코드
#
# 주요 분석:
# 1. 병기와 생존일수의 상관관계 분석
# 2. 흡연·음주와 생존일수의 관계 분석
# 3. 항암제·방사선 치료와 생존일수의 상관관계 분석

# 필요한 패키지 로드
library(survival)
library(survminer)
library(dplyr)

# 데이터 로드
data <- read.csv("pre_process/암임상_라이브러리_합성데이터_train.csv")

# 1. 병기와 생존일수의 상관관계 분석
analyze_stage_survival <- function(data) {
  if(ncol(data) > 1 &&
     all(c("암진단후생존일수.Survival.period.",
           "사망여부.Death.") %in% names(data))) {

    cat("\n=== 병기와 생존일수의 상관관계 분석 ===\n")

    # 병기 변수들 선택
    stage_vars <- data %>%
      select(starts_with("병기"))

    # 병기 변수들 출력
    cat("\n=== 병기 변수들 ===\n")
    print(names(stage_vars))

    if(ncol(stage_vars) > 0) {
      # 각 병기별 분석
      for(stage in names(stage_vars)) {
        # 병기 변수의 유효성 체크
        if(any(data[[stage]] == 1)) {
          cat("\n===", stage, "분석 ===\n")

          # 생존자/사망자 그룹 분리
          survival_group <- data %>%
            filter(`사망여부.Death.` == 0) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(stage))

          death_group <- data %>%
            filter(`사망여부.Death.` == 1) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(stage))

          # 각 그룹의 생존일수 통계량
          cat("\n=== 생존자 그룹 통계량 ===\n")
          print(survival_group %>%
                group_by(all_of(stage)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          cat("\n=== 사망자 그룹 통계량 ===\n")
          print(death_group %>%
                group_by(all_of(stage)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          # 생존 분석
          surv_fit <- tryCatch({
            survfit(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[stage]]),
              data = data
            )
          }, error = function(e) {
            cat("\n생존 분석 오류 발생:\n")
            print(e)
            return(NULL)
          })

          if(!is.null(surv_fit)) {
            # Log-rank test 결과 출력
            surv_diff <- survdiff(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[stage]]),
              data = data
            )
            cat("\n=== Log-rank test 결과 ===\n")
            print(surv_diff)

            # ggsurvplot을 사용한 향상된 플롯
            ggsurvplot(
              surv_fit,
              data = data,
              conf.int = TRUE,
              pval = TRUE,
              risk.table = TRUE,
              title = paste(stage, "과 생존의 관련성"),
              xlab = "생존 시간 (일)",
              ylab = "생존 확률"
            )
          }
        }
      }
    }
  }
}
analyze_stage_survival(data)


# 2. 흡연·음주와 생존일수의 관계 분석
analyze_lifestyle_survival <- function(data) {
  if(ncol(data) > 1 &&
     all(c("암진단후생존일수.Survival.period.",
           "사망여부.Death.") %in% names(data))) {

    cat("\n=== 흡연·음주와 생존일수의 관계 분석 ===\n")

    # 흡연 변수 선택
    smoking_vars <- data %>%
      select(`흡연여부.Smoke.`)

    # 음주 관련 변수들 선택
    drinking_vars <- data %>%
      select(starts_with("음주"))

    if(ncol(smoking_vars) > 0 || ncol(drinking_vars) > 0) {
      # 흡연 분석
      for(smoke in names(smoking_vars)) {
        if(any(data[[smoke]] == 1)) {
          cat("\n===", smoke, "분석 ===\n")

          # 생존자/사망자 그룹 분리
          survival_smoke <- data %>%
            filter(`사망여부.Death.` == 0) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(smoke))

          death_smoke <- data %>%
            filter(`사망여부.Death.` == 1) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(smoke))

          # 각 그룹의 생존일수 통계량
          cat("\n=== 생존자 그룹 통계량 ===\n")
          print(survival_smoke %>%
                group_by(all_of(smoke)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          cat("\n=== 사망자 그룹 통계량 ===\n")
          print(death_smoke %>%
                group_by(all_of(smoke)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          # 생존 분석
          surv_fit <- tryCatch({
            survfit(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[smoke]]),
              data = data
            )
          }, error = function(e) {
            cat("\n생존 분석 오류 발생:\n")
            print(e)
            return(NULL)
          })

          if(!is.null(surv_fit)) {
            # Log-rank test 결과 출력
            surv_diff <- survdiff(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[smoke]]),
              data = data
            )
            cat("\n=== Log-rank test 결과 ===\n")
            print(surv_diff)

            # ggsurvplot을 사용한 향상된 플롯
            ggsurvplot(
              surv_fit,
              data = data,
              conf.int = TRUE,
              pval = TRUE,
              risk.table = TRUE,
              title = paste(smoke, "과 생존의 관련성"),
              xlab = "생존 시간 (일)",
              ylab = "생존 확률"
            )
          }
        }
      }

      # 음주 분석
      for(drink in names(drinking_vars)) {
        if(any(data[[drink]] == 1)) {
          cat("\n===", drink, "분석 ===\n")

          # 생존자/사망자 그룹 분리
          survival_drink <- data %>%
            filter(`사망여부.Death.` == 0) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(drink))

          death_drink <- data %>%
            filter(`사망여부.Death.` == 1) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(drink))

          # 각 그룹의 생존일수 통계량
          cat("\n=== 생존자 그룹 통계량 ===\n")
          print(survival_drink %>%
                group_by(all_of(drink)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          cat("\n=== 사망자 그룹 통계량 ===\n")
          print(death_drink %>%
                group_by(all_of(drink)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          # 생존 분석
          surv_fit <- tryCatch({
            survfit(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[drink]]),
              data = data
            )
          }, error = function(e) {
            cat("\n생존 분석 오류 발생:\n")
            print(e)
            return(NULL)
          })

          if(!is.null(surv_fit)) {
            # Log-rank test 결과 출력
            surv_diff <- survdiff(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[drink]]),
              data = data
            )
            cat("\n=== Log-rank test 결과 ===\n")
            print(surv_diff)

            # ggsurvplot을 사용한 향상된 플롯
            ggsurvplot(
              surv_fit,
              data = data,
              conf.int = TRUE,
              pval = TRUE,
              risk.table = TRUE,
              title = paste(drink, "과 생존의 관련성"),
              xlab = "생존 시간 (일)",
              ylab = "생존 확률"
            )
          }
        }
      }
    }
  }
}

analyze_lifestyle_survival(data)

# 3. 항암제·방사선 치료와 생존일수의 상관관계 분석
analyze_treatment_survival <- function(data) {
  if(ncol(data) > 1 &&
     all(c("암진단후생존일수.Survival.period.",
           "사망여부.Death.") %in% names(data))) {

    cat("\n=== 항암제·방사선 치료와 생존일수의 상관관계 분석 ===\n")

    # 항암제 치료 변수 선택
    chemo_vars <- data %>%
      select(starts_with("항암제"))

    # 방사선 치료 변수 선택
    radio_vars <- data %>%
      select(starts_with("방사선"))

    if(ncol(chemo_vars) > 0 || ncol(radio_vars) > 0) {
      # 항암제 치료 분석
      for(chemo in names(chemo_vars)) {
        if(any(data[[chemo]] == 1)) {
          cat("\n===", chemo, "분석 ===\n")

          # 생존자/사망자 그룹 분리
          survival_chemo <- data %>%
            filter(`사망여부.Death.` == 0) %>%
            select(`암진단후생존일수.Survival.period.`, chemo)

          death_chemo <- data %>%
            filter(`사망여부.Death.` == 1) %>%
            select(`암진단후생존일수.Survival.period.`, chemo)

          # 각 그룹의 생존일수 통계량
          cat("\n=== 생존자 그룹 통계량 ===\n")
          print(survival_chemo %>%
                group_by(chemo) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          cat("\n=== 사망자 그룹 통계량 ===\n")
          print(death_chemo %>%
                group_by(chemo) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          # 생존 분석
          surv_fit <- tryCatch({
            survfit(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[chemo]]),
              data = data
            )
          }, error = function(e) {
            cat("\n생존 분석 오류 발생:\n")
            print(e)
            return(NULL)
          })

          if(!is.null(surv_fit)) {
            # Log-rank test 결과 출력
            surv_diff <- survdiff(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[chemo]]),
              data = data
            )
            cat("\n=== Log-rank test 결과 ===\n")
            print(surv_diff)

            # ggsurvplot을 사용한 향상된 플롯
            ggsurvplot(
              surv_fit,
              data = data,
              conf.int = TRUE,
              pval = TRUE,
              risk.table = TRUE,
              title = paste(chemo, "과 생존의 관련성"),
              xlab = "생존 시간 (일)",
              ylab = "생존 확률"
            )
          }
        }
      }

      # 방사선 치료 분석
      for(radio in names(radio_vars)) {
        if(any(data[[radio]] == 1)) {
          cat("\n===", radio, "분석 ===\n")

          # 생존자/사망자 그룹 분리
          survival_radio <- data %>%
            filter(`사망여부.Death.` == 0) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(radio))

          death_radio <- data %>%
            filter(`사망여부.Death.` == 1) %>%
            select(`암진단후생존일수.Survival.period.`, all_of(radio))

          # 각 그룹의 생존일수 통계량
          cat("\n=== 생존자 그룹 통계량 ===\n")
          print(survival_radio %>%
                group_by(all_of(radio)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          cat("\n=== 사망자 그룹 통계량 ===\n")
          print(death_radio %>%
                group_by(all_of(radio)) %>%
                summarize(
                  평균 = mean(`암진단후생존일수.Survival.period.`),
                  중앙값 = median(`암진단후생존일수.Survival.period.`),
                  표준편차 = sd(`암진단후생존일수.Survival.period.`)
                ))

          # 생존 분석
          surv_fit <- tryCatch({
            survfit(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[radio]]),
              data = data
            )
          }, error = function(e) {
            cat("\n생존 분석 오류 발생:\n")
            print(e)
            return(NULL)
          })

          if(!is.null(surv_fit)) {
            # Log-rank test 결과 출력
            surv_diff <- survdiff(
              Surv(`암진단후생존일수.Survival.period.`,
                   `사망여부.Death.` == 1) ~
                as.factor(data[[radio]]),
              data = data
            )
            cat("\n=== Log-rank test 결과 ===\n")
            print(surv_diff)

            # ggsurvplot을 사용한 향상된 플롯
            ggsurvplot(
              surv_fit,
              data = data,
              conf.int = TRUE,
              pval = TRUE,
              risk.table = TRUE,
              title = paste(radio, "과 생존의 관련성"),
              xlab = "생존 시간 (일)",
              ylab = "생존 확률"
            )
          }
        }
      }
    }
  }
}

# 전체 분석 실행
analyze_treatment_survival(data)

cat("\n=== EDA 완료 ===\n")
