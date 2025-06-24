# 01_data_preparation.R
# 데이터 로드 및 전처리 스크립트

# 필요한 패키지 로드
library(dplyr)      # 데이터 조작
library(tidyr)      # 데이터 정리
library(readr)      # 데이터 읽기/쓰기
library(readxl)     # 엑셀 파일 읽기
library(stringr)    # 문자열 처리
library(purrr)      # 함수형 프로그래밍
library(tibble)     # 데이터프레임 개선
library(tidyselect) # tidy 선택 도우미
library(rlang)      # tidy evaluation
library(mice)       # 다중대치법을 위한 패키지

# 데이터 파일 경로 설정
train_file <- "pre_process/암임상_라이브러리_합성데이터_train.csv"
test_file <- "pre_process/암임상_라이브러리_합성데이터_test.csv"

# 데이터 로드 및 18세 미만 필터링
train_data <- read.csv(train_file, fileEncoding = "UTF-8-BOM") %>%
  filter(진단시연령.AGE. >= 18)

test_data <- read.csv(test_file, fileEncoding = "UTF-8-BOM") %>%
  filter(진단시연령.AGE. >= 18)

# 결측치 확인
cat("\n=== 학습 데이터 결측치 요약 ===\n")
print(colSums(is.na(train_data))[colSums(is.na(train_data)) > 0])
cat("\n총 결측치가 있는 변수 수:", sum(colSums(is.na(train_data)) > 0), "개\n")
cat("총 결측치 수:", sum(is.na(train_data)), "개\n")

cat("\n=== 테스트 데이터 결측치 요약 ===\n")
print(colSums(is.na(test_data))[colSums(is.na(test_data)) > 0])
cat("\n총 결측치가 있는 변수 수:", sum(colSums(is.na(test_data)) > 0), "개\n")
cat("총 결측치 수:", sum(is.na(test_data)), "개\n")


# 결측치 비율 계산 함수
calculate_missing_ratio <- function(x) {
  mean(is.na(x))
}

# 음주 변수 처리 함수 (99를 0으로 변환)
handle_drinking_variable <- function(df) {
  if ("음주종류.Type.of.Drink." %in% names(df)) {
    cat("\n=== 음주 변수(99)를 0으로 변환 ===\n")
    df$음주종류.Type.of.Drink.[df$음주종류.Type.of.Drink. == 99] <- 0
  }
  return(df)
}

# 면역병리 및 분자병리 변수에 대한 다중대치법 적용 함수
impute_molecular_data <- function(df) {
  # 면역병리 변수
  immune_vars <- c("면역병리EGFR검사코드.명.EGFR.")
  
  # 분자병리 변수
  molecular_vars <- c("분자병리MSI검사결과코드.명.MSI.",
                     "분자병리KRASMUTATION_EXON2검사결과코드.명.KRASMUTATION_EXON2.",
                     "분자병리KRASMUTATION검사결과코드.명.KRASMUTATION.",
                     "분자병리NRASMUTATION검사결과코드.명.NRASMUTATION.",
                     "분자병리BRAF_MUTATION검사결과코드.명.BRAF_MUTATION.")
  
  # 모든 처리할 변수 결합
  all_vars <- c(immune_vars, molecular_vars)
  
  # 데이터에 존재하는 변수만 선택
  all_vars <- intersect(all_vars, names(df))
  
  cat("\n=== 면역병리 및 분자병리 변수 처리 ===\n")
  cat("발견된 변수:", if(length(all_vars) > 0) paste(all_vars, collapse=", ") else "없음", "\n")
  
  if (length(all_vars) > 0) {
    # 99를 NA로 변환
    for (var in all_vars) {
      na_before <- sum(is.na(df[[var]]))
      df[[var]][df[[var]] == 99] <- NA
      na_after <- sum(is.na(df[[var]]))
      if (na_after > na_before) {
        cat("변환: ", var, "에서 99를 NA로 변환 (", na_after - na_before, "개)\n", sep="")
      }
    }
    
    # NA가 있는 변수만 선택
    vars_with_na <- all_vars[sapply(all_vars, function(x) any(is.na(df[[x]])))]
    
    if (length(vars_with_na) > 0) {
      cat("NA가 있는 변수:", paste(vars_with_na, collapse=", "), "\n")
      
      # 데이터 확인 및 변환
      temp_df <- df[, vars_with_na, drop=FALSE]
      
      # 각 변수를 팩터로 변환 (mice가 범주형 변수를 더 잘 처리하도록)
      for (var in vars_with_na) {
        if (!is.factor(temp_df[[var]])) {
          temp_df[[var]] <- as.factor(temp_df[[var]])
        }
      }
      
      # mice 실행
      tryCatch({
        temp_data <- mice::mice(
          data = temp_df,
          m = 5,
          maxit = 5,
          method = 'pmm',
          seed = 123,
          printFlag = FALSE
        )
        
        # 첫 번째 대체 데이터셋 사용
        imputed_data <- mice::complete(temp_data, 1)
        
        # 원래 데이터프레임에 대체된 값 적용
        for (var in vars_with_na) {
          df[[var]] <- imputed_data[[var]]
        }
        cat("다중대치법 적용 완료\n")
        
      }, error = function(e) {
        cat("다중대치법 적용 중 오류 발생:", e$message, "\n")
        cat("대신 중앙값/최빈값으로 대체합니다.\n")
        
        # 오류 발생 시 각 변수별로 중앙값 또는 최빈값으로 대체
        for (var in vars_with_na) {
          if (is.numeric(df[[var]])) {
            median_val <- median(df[[var]], na.rm = TRUE)
            df[[var]][is.na(df[[var]])] <- median_val
          } else {
            tab <- table(df[[var]])
            mode_val <- names(which.max(tab))
            df[[var]][is.na(df[[var]])] <- mode_val
          }
        }
      })
      
    } else {
      cat("결측치가 있는 변수가 없어 다중대치를 건너뜁니다.\n")
    }
  }
  
  return(df)
}

# 결측치 처리 함수
handle_missing_values <- function(df) {
  # 1. 음주 변수 처리 (99를 0으로 변환)
  if ("음주종류.Type.of.Drink." %in% names(df)) {
    cat("\n=== 음주 변수 처리 전 ===\n")
    print(table(df$`음주종류.Type.of.Drink.`, useNA = 'always'))
  }
  
  df <- handle_drinking_variable(df)
  
  if ("음주종류.Type.of.Drink." %in% names(df)) {
    cat("\n=== 음주 변수 처리 후 ===\n")
    print(table(df$`음주종류.Type.of.Drink`, useNA = 'always'))
  }
  
  # 2. 면역병리 및 분자병리 변수에 다중대치법 적용
  molecular_vars <- c("분자병리MSI검사결과코드.명.MSI.", 
                     "분자병리KRASMUTATION_EXON2검사결과코드.명.KRASMUTATION_EXON2.",
                     "분자병리KRASMUTATION검사결과코드.명.KRASMUTATION.",
                     "분자병리NRASMUTATION검사결과코드.명.NRASMUTATION.",
                     "분자병리BRAF_MUTATION검사결과코드.명.BRAF_MUTATION.")
  
  cat("\n=== 분자병리 변수 처리 전 (99/NA 개수) ===\n")
  for (var in molecular_vars) {
    if (var %in% names(df)) {
      cat(var, ": 99 =", sum(df[[var]] == 99, na.rm = TRUE), 
          ", NA =", sum(is.na(df[[var]])), "\n")
    }
  }
  
  df <- impute_molecular_data(df)
  
  cat("\n=== 분자병리 변수 처리 후 (NA 개수) ===\n")
  for (var in molecular_vars) {
    if (var %in% names(df)) {
      cat(var, ": NA =", sum(is.na(df[[var]])), "\n")
    }
  }
  
  # 면역병리 및 분자병리 변수 목록
  immune_vars <- c("면역병리EGFR검사코드.명.EGFR.")
  molecular_vars <- c(
    "분자병리MSI검사결과코드.명.MSI.",
    "분자병리KRASMUTATION_EXON2검사결과코드.명.KRASMUTATION_EXON2.",
    "분자병리KRASMUTATION검사결과코드.명.KRASMUTATION.",
    "분자병리NRASMUTATION검사결과코드.명.NRASMUTATION.",
    "분자병리BRAF_MUTATION검사결과코드.명.BRAF_MUTATION."
  )
  
  # 모든 처리할 변수 결합
  protected_vars <- c(immune_vars, molecular_vars)
  
  # 데이터에 존재하는 변수만 선택
  protected_vars <- intersect(protected_vars, names(df))
  
  # TNM stage 변수 목록
  tnm_cols <- c("T_stage", "N_stage", "M_stage")
  tnm_cols <- intersect(tnm_cols, names(df))
  
  # 보호할 변수들 (TNM stage + 면역/분자병리 변수)
  protected_cols <- unique(c(tnm_cols, protected_vars))
  
  # 보호할 변수를 제외한 열들
  other_cols <- setdiff(names(df), protected_cols)
  
  # 결측치 비율 계산 (보호 변수 제외)
  if (length(other_cols) > 0) {
    missing_ratios <- sapply(df[other_cols], calculate_missing_ratio)
    
    # 50% 이상 결측치가 있는 변수 제거 (보호 변수는 제외)
    high_missing_cols <- names(missing_ratios[missing_ratios >= 0.5])
    if (length(high_missing_cols) > 0) {
      cat("\n=== 결측치 50% 이상인 변수 제거 (총 ", length(high_missing_cols), "개) ===\n", sep="")
      print(high_missing_cols)
      df <- df[, !names(df) %in% high_missing_cols, drop = FALSE]
      # other_cols 업데이트
      other_cols <- setdiff(other_cols, high_missing_cols)
    }
  }
  
  # 각 변수에 대한 처리 (TNM stage 변수 제외)
  for (col in other_cols) {
    if (is.numeric(df[[col]])) {
      # 수치형 변수
      na_count <- sum(is.na(df[[col]]))
      if (na_count == 0) next
      
      na_ratio <- na_count / nrow(df)
      
      if (na_ratio >= 0.1) {
        # 10% 이상 결측치: 중앙값으로 대체
        median_val <- median(df[[col]], na.rm = TRUE)
        df[[col]][is.na(df[[col]])] <- median_val
        cat("\n[수치형] ", col, ": ", na_count, "개(상위 ", 
            round(na_ratio*100, 1), "%) 결측치를 중앙값(", 
            round(median_val, 2), ")으로 대체", sep="")
      } else {
        # 10% 미만: 행 삭제
        df <- df[!is.na(df[[col]]), ]
        cat("\n[수치형] ", col, ": ", na_count, "개(상위 ", 
            round(na_ratio*100, 1), "%) 결측치를 가진 행 삭제", sep="")
      }
    } else if (is.factor(df[[col]]) || is.character(df[[col]])) {
      # 범주형 변수
      na_count <- sum(is.na(df[[col]]) | df[[col]] == "")
      if (na_count == 0) next
      
      na_ratio <- na_count / nrow(df)
      
      if (na_ratio >= 0.1) {
        # 10% 이상 결측치: '미실시' 범주 추가
        df[[col]] <- as.character(df[[col]])
        df[[col]][is.na(df[[col]]) | df[[col]] == ""] <- "미실시"
        df[[col]] <- as.factor(df[[col]])
        cat("\n[범주형] ", col, ": ", na_count, "개(상위 ", 
            round(na_ratio*100, 1), "%) 결측치를 '미실시'로 대체", sep="")
      } else {
        # 10% 미만: 행 삭제
        df <- df[!(is.na(df[[col]]) | df[[col]] == ""), ]
        cat("\n[범주형] ", col, ": ", na_count, "개(상위 ", 
            round(na_ratio*100, 1), "%) 결측치를 가진 행 삭제", sep="")
      }
    }
  }
  
  # TNM stage 변수에 대한 로그만 남기기
  if (length(tnm_cols) > 0) {
    for (col in tnm_cols) {
      na_count <- sum(is.na(df[[col]]))
      if (na_count > 0) {
        na_ratio <- na_count / nrow(df)
        cat("\n[TNM Stage] ", col, ": ", na_count, "개(상위 ", 
            round(na_ratio*100, 1), "%) 결측치 유지 (TNM Stage 변수는 결측치 처리에서 제외됨)", sep="")
      }
    }
  }
  
  return(df)
}
process_tnm_stage <- function(df) {
  # T 병기 처리
  t_cols <- grep("^병기STAGE\\.T", names(df), value = TRUE)
  if (length(t_cols) > 0) {
    df$T_stage <- apply(df[t_cols], 1, function(x) {
      # 1이 있는 컬럼 찾기
      active_cols <- t_cols[!is.na(x) & x == 1]
      if (length(active_cols) == 0) return("T0")  # 결측치를 T0로 대체
      
      # 병기명 추출
      stages <- gsub("병기STAGE\\.(T[0-4][a-z]*|Tis)\\.?", "\\1", active_cols)
      
      # 상위 그룹으로 매핑
      stage_groups <- sapply(stages, function(s) {
        if (s == "Tis") return("Tis")
        if (grepl("^T1", s)) return("T1")
        if (grepl("^T2", s)) return("T2") 
        if (grepl("^T3", s)) return("T3")
        if (grepl("^T4", s)) return("T4")
        return(NA_character_)
      })
      
      # 가장 높은 단계 선택
      t_order <- c("Tis", "T1", "T2", "T3", "T4")
      valid_stages <- stage_groups[!is.na(stage_groups)]
      if (length(valid_stages) == 0) return(NA_character_)
      
      return(valid_stages[which.max(match(valid_stages, t_order))])
    })
    
    df$T_stage <- factor(df$T_stage, levels = c("Tis", "T1", "T2", "T3", "T4"))
    df <- df[, !names(df) %in% t_cols, drop = FALSE]
  }
  
  # N 병기 처리 (유사하게 수정)
  n_cols <- grep("^병기STAGE\\.N", names(df), value = TRUE)
  if (length(n_cols) > 0) {
    df$N_stage <- apply(df[n_cols], 1, function(x) {
      active_cols <- n_cols[!is.na(x) & x == 1]
      if (length(active_cols) == 0) return("N0")  # 결측치를 N0로 대체
      
      stages <- gsub("병기STAGE\\.(N[0-3][a-z]*)\\.?", "\\1", active_cols)
      
      # 상위 그룹으로 매핑
      stage_groups <- sapply(stages, function(s) {
        if (s == "N0") return("N0")
        if (grepl("^N1", s)) return("N1")
        if (grepl("^N2", s)) return("N2")
        if (grepl("^N3", s)) return("N3")
        return(NA_character_)
      })
      
      n_order <- c("N0", "N1", "N2", "N3")
      valid_stages <- stage_groups[!is.na(stage_groups)]
      if (length(valid_stages) == 0) return(NA_character_)
      
      return(valid_stages[which.max(match(valid_stages, n_order))])
    })
    
    df$N_stage <- factor(df$N_stage, levels = c("N0", "N1", "N2", "N3"))
    df <- df[, !names(df) %in% n_cols, drop = FALSE]
  }
  
  # M 병기 처리 (유사하게 수정)
  m_cols <- grep("^병기STAGE\\.M", names(df), value = TRUE)
  if (length(m_cols) > 0) {
    df$M_stage <- apply(df[m_cols], 1, function(x) {
      active_cols <- m_cols[!is.na(x) & x == 1]
      if (length(active_cols) == 0) return("M0")  # 결측치를 M0로 대체
      
      stages <- gsub("병기STAGE\\.(M[01][a-z]*)\\.?", "\\1", active_cols)
      
      stage_groups <- sapply(stages, function(s) {
        if (s == "M0") return("M0")
        if (grepl("^M1", s)) return("M1")
        return(NA_character_)
      })
      
      m_order <- c("M0", "M1")
      valid_stages <- stage_groups[!is.na(stage_groups)]
      if (length(valid_stages) == 0) return(NA_character_)
      
      return(valid_stages[which.max(match(valid_stages, m_order))])
    })
    
    df$M_stage <- factor(df$M_stage, levels = c("M0", "M1"))
    df <- df[, !names(df) %in% m_cols, drop = FALSE]
  }
  
  return(df)
}

  
# TNM 병기 처리 (결측치 처리 전에 실행)
cat("\n=== 학습 데이터 TNM 병기 처리 ===")
train_data <- process_tnm_stage(train_data)

cat("\n=== 테스트 데이터 TNM 병기 처리 ===")
test_data <- process_tnm_stage(test_data)


# 결측치 처리 (99를 NA로 변환 및 결측치 처리)
cat("\n=== 학습 데이터 결측치 처리 ===")
train_data <- handle_missing_values(train_data)

cat("\n\n=== 테스트 데이터 결측치 처리 ===")
test_data <- handle_missing_values(test_data)

# EOCRC(50세 이하)와 LOCRC(50세 초과)로 분류
train_data <- train_data %>%
  mutate(cancer_type = ifelse(진단시연령.AGE. <= 50, "EOCRC", "LOCRC"),
         cancer_type = factor(cancer_type, levels = c("EOCRC", "LOCRC")))

test_data <- test_data %>%
  mutate(cancer_type = ifelse(진단시연령.AGE. <= 50, "EOCRC", "LOCRC"),
         cancer_type = factor(cancer_type, levels = c("EOCRC", "LOCRC")))

# 각 그룹별 환자 수 확인
cat("\n=== EOCRC/LOCRC 분포 ===\n")
cat("Train 데이터:\n")
train_counts <- table(train_data$cancer_type)
print(train_counts)
cat("\nTest 데이터:\n")
test_counts <- table(test_data$cancer_type)
print(test_counts)

# 데이터셋 분리
train_eocrc <- train_data %>% filter(cancer_type == "EOCRC")
train_locrc <- train_data %>% filter(cancer_type == "LOCRC")

test_eocrc <- test_data %>% filter(cancer_type == "EOCRC")
test_locrc <- test_data %>% filter(cancer_type == "LOCRC")

# 결과 디렉토리 생성 (없는 경우)
if (!dir.exists("data")) {
  dir.create("data", recursive = TRUE)
}

# 각 그룹별 데이터 저장
write.csv(train_eocrc, "data/1_train_EOCRC.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(train_locrc, "data/1_train_LOCRC.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(test_eocrc, "data/1_test_EOCRC.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(test_locrc, "data/1_test_LOCRC.csv", row.names = FALSE, fileEncoding = "UTF-8")

# 요약 정보 출력
cat("\n=== 데이터셋 요약 ===\n")
cat("\n[Train 데이터]")
cat("\n- EOCRC (50세 이하) :", train_counts["EOCRC"], "건")
cat("\n- LOCRC (50세 초과) :", train_counts["LOCRC"], "건")

cat("\n\n[Test 데이터]")
cat("\n- EOCRC (50세 이하) :", test_counts["EOCRC"], "건")
cat("\n- LOCRC (50세 초과) :", test_counts["LOCRC"], "건")

EOCRC_tr_data <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8")

cat("\n=== 데이터 기본 정보 ===\n")
cat("데이터 차원:", dim(EOCRC_tr_data), "\n")
cat("변수명:\n")
print(names(EOCRC_tr_data))
