# 02_01_exploratory_analysis_final.R
# 대장암 환자의 생존 예측을 위한 탐색적 데이터 분석 (최종 버전)

# 필요한 패키지 로드
library(survival)
library(survminer)
library(dplyr)
library(ggplot2)

# === 데이터 로드 (간소화) ===
load_data <- function(file_path = "pre_process/암임상_라이브러리_합성데이터_train.csv") {
  data <- read.csv(file_path)
  cat("데이터 로드 완료:", nrow(data), "건\n")
  return(data)
}

# === 안전한 생존 분석 함수 ===
safe_survival_analysis <- function(data, group_var, group_name) {
  cat("\n", rep("=", 60), "\n")
  cat("분석:", group_name, "\n")
  cat(rep("=", 60), "\n")
  
  # 데이터 유효성 검사
  if(!group_var %in% names(data)) {
    cat("오류: 변수", group_var, "가 없습니다.\n")
    return(NULL)
  }
  
  # 유효한 데이터 필터링
  valid_data <- data %>%
    filter(
      !is.na(.data[[group_var]]),
      !is.na(`암진단후생존일수.Survival.period.`),
      !is.na(`사망여부.Death.`),
      `암진단후생존일수.Survival.period.` > 0
    )
  
  if(nrow(valid_data) == 0) {
    cat("유효한 데이터가 없습니다.\n")
    return(NULL)
  }
  
  cat("유효 데이터:", nrow(valid_data), "건\n")
  
  # 그룹별 분포
  cat("\n=== 그룹별 분포 ===\n")
  group_table <- table(valid_data[[group_var]], useNA = "ifany")
  print(group_table)
  
  # 기본 통계량
  cat("\n=== 그룹별 생존 통계 ===\n")
  stats <- valid_data %>%
    group_by(across(all_of(group_var))) %>%
    summarize(
      환자수 = n(),
      평균생존일수 = round(mean(`암진단후생존일수.Survival.period.`), 1),
      중앙값생존일수 = round(median(`암진단후생존일수.Survival.period.`), 1),
      사망자수 = sum(`사망여부.Death.`),
      사망률 = round(mean(`사망여부.Death.`) * 100, 1),
      .groups = 'drop'
    )
  print(stats)
  
  # 생존 분석 실행
  tryCatch({
    # 생존 객체 생성
    surv_obj <- Surv(
      time = valid_data$`암진단후생존일수.Survival.period.`,
      event = valid_data$`사망여부.Death.`
    )
    
    # 생존 곡선 적합
    formula_str <- paste("surv_obj ~", group_var)
    surv_fit <- survfit(as.formula(formula_str), data = valid_data)
    
    # Log-rank test
    surv_diff <- survdiff(as.formula(formula_str), data = valid_data)
    
    # p-value 계산
    p_value <- 1 - pchisq(surv_diff$chisq, length(surv_diff$n) - 1)
    
    cat("\n=== Log-rank Test 결과 ===\n")
    cat("p-value:", round(p_value, 4), "\n")
    cat("통계적 유의성:", ifelse(p_value < 0.05, "유의함", "유의하지 않음"), "\n")
    
    # p-value가 0.05 미만인 경우에만 시각화
    if (p_value < 0.05) {
      # 생존 곡선 시각화
      plot <- ggsurvplot(
        surv_fit,
        data = valid_data,
        conf.int = TRUE,
        pval = TRUE,
        risk.table = TRUE,
        title = paste(group_name, "생존 분석 (p =", round(p_value, 4), ")"),
        xlab = "생존 시간 (일)",
        ylab = "생존 확률",
        legend.title = group_name,
        palette = "jco"
      )
      
      print(plot)
    } else {
      plot <- NULL
      cat("\n통계적으로 유의하지 않아 시각화를 건너뜁니다 (p > 0.05)\n")
    }
    
    cat("\n", group_name, "분석 완료! (p =", round(p_value, 4), ")\n")
    cat(rep("=", 60), "\n\n")
    
    # 결과 반환 (p-value 포함)
    result <- list(
      group_name = group_name,
      variable = group_var,
      stats = stats,
      fit = surv_fit,
      test = surv_diff,
      p_value = p_value,
      plot = plot,
      is_significant = p_value < 0.05
    )
    
    # 유의미한 결과만 반환
    if (result$is_significant) {
      cat("\n[유의미한 결과] ", group_name, "(p =", round(p_value, 4), ")\n")
      return(result)
    } else {
      cat("\n[제외] ", group_name, "는 통계적으로 유의하지 않습니다 (p =", round(p_value, 4), ")\n")
      return(NULL)
    }
    
  }, error = function(e) {
    cat("분석 오류:", e$message, "\n")
    return(NULL)
  })
}

# === 개별 분석 함수들 ===

# 1. T 병기 분석
analyze_t_stage <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("1. T 병기 분석\n")
  cat(rep("#", 80), "\n")
  
  # T 병기 통합[1]
  t_data <- data %>%
    mutate(
      T_Stage = case_when(
        `병기STAGE.Tis.` == 1 ~ "Tis",
        `병기STAGE.T1.` == 1 | `병기STAGE.T1a.` == 1 | `병기STAGE.T1b.` == 1 | `병기STAGE.T1c.` == 1 ~ "T1",
        `병기STAGE.T2.` == 1 | `병기STAGE.T2a.` == 1 | `병기STAGE.T2b.` == 1 | `병기STAGE.T2C.` == 1 ~ "T2",
        `병기STAGE.T3.` == 1 | `병기STAGE.T3a.` == 1 | `병기STAGE.T3b.` == 1 ~ "T3",
        `병기STAGE.T4.` == 1 | `병기STAGE.T4a.` == 1 | `병기STAGE.T4b.` == 1 ~ "T4",
        TRUE ~ "Unknown"
      )
    ) %>%
    filter(T_Stage != "Unknown")
  
  result <- safe_survival_analysis(t_data, "T_Stage", "T 병기")
  readline("계속하려면 Enter...")
  return(result)
}

# 2. N 병기 분석
analyze_n_stage <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("2. N 병기 분석\n")
  cat(rep("#", 80), "\n")
  
  # N 병기 통합[1]
  n_data <- data %>%
    mutate(
      N_Stage = case_when(
        `병기STAGE.N1.` == 1 | `병기STAGE.N1a.` == 1 | `병기STAGE.N1b.` == 1 | `병기STAGE.N1c.` == 1 ~ "N1",
        `병기STAGE.N2.` == 1 | `병기STAGE.N2a.` == 1 | `병기STAGE.N2b.` == 1 | `병기STAGE.N2c.` == 1 ~ "N2",
        `병기STAGE.N3.` == 1 | `병기STAGE.N3a.` == 1 | `병기STAGE.N3b.` == 1 ~ "N3",
        TRUE ~ "N0"
      )
    )
  
  result <- safe_survival_analysis(n_data, "N_Stage", "N 병기")
  readline("계속하려면 Enter...")
  return(result)
}

# 3. M 병기 분석
analyze_m_stage <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("3. M 병기 분석\n")
  cat(rep("#", 80), "\n")
  
  # M 병기 통합[1]
  m_data <- data %>%
    mutate(
      M_Stage = case_when(
        `병기STAGE.M1.` == 1 | `병기STAGE.M1a.` == 1 | `병기STAGE.M1b.` == 1 | `병기STAGE.M1c.` == 1 ~ "M1",
        TRUE ~ "M0"
      )
    )
  
  result <- safe_survival_analysis(m_data, "M_Stage", "M 병기")
  readline("계속하려면 Enter...")
  return(result)
}

# 4. 흡연 분석
analyze_smoking <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("4. 흡연 분석\n")
  cat(rep("#", 80), "\n")
  
  # 흡연 그룹 생성[1]
  smoke_data <- data %>%
    mutate(
      흡연상태 = case_when(
        `흡연여부.Smoke.` == 0 ~ "비흡연",
        `흡연여부.Smoke.` == 1 ~ "현재흡연",
        `흡연여부.Smoke.` == 2 ~ "과거흡연",
        TRUE ~ "미상"
      )
    ) %>%
    filter(흡연상태 != "미상")
  
  result <- safe_survival_analysis(smoke_data, "흡연상태", "흡연 상태")
  readline("계속하려면 Enter...")
  return(result)
}

# 5. 음주 분석
analyze_drinking <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("5. 음주 분석\n")
  cat(rep("#", 80), "\n")
  
  # 음주 그룹 생성[1]
  drink_data <- data %>%
    mutate(
      음주종류 = case_when(
        `음주종류.Type.of.Drink.` == 1 ~ "맥주",
        `음주종류.Type.of.Drink.` == 2 ~ "소주",
        `음주종류.Type.of.Drink.` == 3 ~ "양주",
        `음주종류.Type.of.Drink.` == 99 ~ "기타",
        TRUE ~ "미상"
      )
    ) %>%
    filter(음주종류 != "미상")
  
  result <- safe_survival_analysis(drink_data, "음주종류", "음주 종류")
  readline("계속하려면 Enter...")
  return(result)
}

# 6. 수술 치료 분석
analyze_surgery <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("6. 수술 치료 분석\n")
  cat(rep("#", 80), "\n")
  
  # 수술 여부 그룹[1]
  surgery_data <- data %>%
    mutate(
      수술여부 = case_when(
        `대장암.수술.여부.Operation.` == 0 ~ "수술안함",
        `대장암.수술.여부.Operation.` == 1 ~ "수술함",
        TRUE ~ "미상"
      )
    ) %>%
    filter(수술여부 != "미상")
  
  result <- safe_survival_analysis(surgery_data, "수술여부", "수술 여부")
  readline("계속하려면 Enter...")
  return(result)
}

# 7. 항암제 치료 분석
analyze_chemotherapy <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("7. 항암제 치료 분석\n")
  cat(rep("#", 80), "\n")
  
  # 항암제 치료 그룹[1]
  chemo_data <- data %>%
    mutate(
      항암제치료 = case_when(
        `항암제.치료.여부.Chemotherapy.` == 0 ~ "치료안함",
        `항암제.치료.여부.Chemotherapy.` == 1 ~ "치료함",
        TRUE ~ "미상"
      )
    ) %>%
    filter(항암제치료 != "미상")
  
  result <- safe_survival_analysis(chemo_data, "항암제치료", "항암제 치료")
  readline("계속하려면 Enter...")
  return(result)
}

# 8. 방사선 치료 분석
analyze_radiotherapy <- function(data) {
  cat("\n", rep("#", 80), "\n")
  cat("8. 방사선 치료 분석\n")
  cat(rep("#", 80), "\n")
  
  # 방사선 치료 그룹[1]
  radio_data <- data %>%
    mutate(
      방사선치료 = case_when(
        `방사선치료.여부.Radiation.Therapy.` == 0 ~ "치료안함",
        `방사선치료.여부.Radiation.Therapy.` == 1 ~ "치료함",
        TRUE ~ "미상"
      )
    ) %>%
    filter(방사선치료 != "미상")
  
  result <- safe_survival_analysis(radio_data, "방사선치료", "방사선 치료")
  readline("계속하려면 Enter...")
  return(result)
}

# === 메인 실행 함수 ===
main_analysis <- function() {
  # 간소화된 데이터 로드
  data <- load_data()
  
  cat("\n분석 메뉴:\n")
  cat("1. T 병기\n2. N 병기\n3. M 병기\n4. 흡연\n5. 음주\n")
  cat("6. 수술\n7. 항암제\n8. 방사선\n9. 전체\n")
  
  choice <- readline("선택 (1-9): ")
  
  results <- list()
  significant_results <- list()
  
  # 분석 함수 실행
  switch(choice,
    "1" = { results$t_stage <- analyze_t_stage(data) },
    "2" = { results$n_stage <- analyze_n_stage(data) },
    "3" = { results$m_stage <- analyze_m_stage(data) },
    "4" = { results$smoking <- analyze_smoking(data) },
    "5" = { results$drinking <- analyze_drinking(data) },
    "6" = { results$surgery <- analyze_surgery(data) },
    "7" = { results$chemotherapy <- analyze_chemotherapy(data) },
    "8" = { results$radiotherapy <- analyze_radiotherapy(data) },
    "9" = {
      results$t_stage <- analyze_t_stage(data)
      results$n_stage <- analyze_n_stage(data)
      results$m_stage <- analyze_m_stage(data)
      results$smoking <- analyze_smoking(data)
      results$drinking <- analyze_drinking(data)
      results$surgery <- analyze_surgery(data)
      results$chemotherapy <- analyze_chemotherapy(data)
      results$radiotherapy <- analyze_radiotherapy(data)
    },
    { results$t_stage <- analyze_t_stage(data) }
  )
  
  # NULL이 아닌 결과만 필터링
  valid_results <- Filter(Negate(is.null), results)
  
  # p-value가 0.05 미만인 결과만 필터링
  significant_results <- Filter(function(x) x$p_value < 0.05, valid_results)
  
  # 유의미한 결과가 있는 경우에만 처리
  if (length(significant_results) > 0) {
    # 유의미한 결과 요약 출력
    cat("\n\n", rep("=", 80), "\n", sep="")
    cat("유의미한 분석 결과 요약 (p < 0.05)\n")
    cat(rep("=", 80), "\n\n", sep="")
    
    # 유의미한 결과를 데이터프레임으로 변환
    sig_data_list <- list()
    
    for (i in seq_along(significant_results)) {
      res <- significant_results[[i]]
      cat("[", i, "] ", res$group_name, " (p = ", 
          formatC(res$p_value, format = "e", digits = 2), ")\n", sep="")
      
      # 원본 데이터에서 해당 변수에 해당하는 데이터 추출
      var_name <- res$variable
      group_levels <- unique(data[[var_name]])
      
      # 각 그룹별로 데이터 필터링
      for (level in group_levels) {
        group_data <- data[data[[var_name]] == level, ]
        group_data$분석_변수 <- res$group_name
        group_data$그룹_수준 <- level
        group_data$p_value <- res$p_value
        sig_data_list[[paste0(res$group_name, "_", level)]] <- group_data
      }
    }
    
    # 모든 유의미한 데이터를 하나의 데이터프레임으로 결합
    if (length(sig_data_list) > 0) {
      significant_data <- do.call(rbind, sig_data_list)
      
      # CSV로 저장 (UTF-8 인코딩으로 한국어 지원)
      write.csv(significant_data, 
                "significant_survival_data.csv", 
                row.names = FALSE, 
                fileEncoding = "UTF-8")
      
      # 요약 통계 생성
      sig_summary <- do.call(rbind, lapply(significant_results, function(x) {
        data.frame(
          분석_변수 = x$group_name,
          변수명 = x$variable,
          p_value = x$p_value,
          평균_생존일 = mean(x$stats$평균생존일수, na.rm = TRUE),
          중앙값_생존일 = mean(x$stats$중앙값생존일수, na.rm = TRUE),
          총_환자수 = sum(x$stats$환자수, na.rm = TRUE)
        )
      }))
      
      # p-value 기준으로 정렬
      sig_summary <- sig_summary[order(sig_summary$p_value), ]
      
      # 요약 통계 저장
      write.csv(sig_summary, 
                "significant_survival_summary.csv", 
                row.names = FALSE, 
                fileEncoding = "UTF-8")
      
      cat("\n\n유의미한 분석 결과가 다음 파일들로 저장되었습니다:\n")
      cat("- significant_survival_data.csv: 유의미한 변수들의 원본 데이터\n")
      cat("- significant_survival_summary.csv: 유의미한 변수들의 요약 통계\n")
    }
  } else {
    cat("\n\n유의미한 분석 결과가 없습니다 (p < 0.05 기준).\n")
  }
  
  cat("\n분석이 완료되었습니다.\n")
  
  # 유의미한 결과 반환
  if (exists("significant_data")) {
    return(list(summary = sig_summary, data = significant_data))
  } else {
    return(NULL)
  }
}

# 실행
analysis_results <- main_analysis()
