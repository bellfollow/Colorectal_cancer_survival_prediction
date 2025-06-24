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

# 데이터 파일 경로 설정
train_file <- "pre_process/암임상_라이브러리_합성데이터_train.csv"
test_file <- "pre_process/암임상_라이브러리_합성데이터_test.csv"

# 데이터 로드 및 18세 미만 필터링
train_data <- read.csv(train_file, fileEncoding = "UTF-8-BOM") %>%
  filter(진단시연령.AGE. >= 18)

test_data <- read.csv(test_file, fileEncoding = "UTF-8-BOM") %>%
  filter(진단시연령.AGE. >= 18)


# 99를 NA로 변환하는 함수
convert_99_to_na <- function(df) {
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      x[x == 99] <- NA
    }
    return(x)
  })
  return(df)
}

# 결측치 비율 계산 함수
calculate_missing_ratio <- function(x) {
  mean(is.na(x))
}

# 결측치 처리 함수
handle_missing_values <- function(df) {
  # TNM stage 변수 목록
  tnm_cols <- c("T_stage", "N_stage", "M_stage")
  tnm_cols <- intersect(tnm_cols, names(df))  # 데이터에 있는 TNM 변수만 선택
  
  # TNM stage 변수를 제외한 열들
  other_cols <- setdiff(names(df), tnm_cols)
  
  # 99를 NA로 변환 (TNM stage 변수 제외)
  df[other_cols] <- lapply(df[other_cols], function(x) {
    if (is.numeric(x)) {
      x[x == 99] <- NA
    }
    return(x)
  })
  
  # TNM stage 변수는 99를 NA로만 변환
  if (length(tnm_cols) > 0) {
    df[tnm_cols] <- lapply(df[tnm_cols], function(x) {
      if (is.factor(x)) {
        levels(x)[levels(x) == "99"] <- NA_character_
      } else if (is.character(x)) {
        x[x == "99"] <- NA_character_
      }
      return(x)
    })
  }
  
  # 결측치 비율 계산 (TNM stage 변수 제외)
  missing_ratios <- sapply(df[other_cols], calculate_missing_ratio)
  
  # 50% 이상 결측치가 있는 변수 제거 (TNM stage 변수 제외)
  high_missing_cols <- names(missing_ratios[missing_ratios >= 0.5])
  if (length(high_missing_cols) > 0) {
    # TNM stage 변수가 high_missing_cols에 포함되어 있는지 확인하고 제외
    high_missing_cols <- setdiff(high_missing_cols, tnm_cols)
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
      if (length(active_cols) == 0) return(NA_character_)
      
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
      if (length(active_cols) == 0) return(NA_character_)
      
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
      if (length(active_cols) == 0) return(NA_character_)
      
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

# 학습 및 테스트 데이터에서 0으로만 구성된 변수 제거
cat("\n=== 학습 데이터에서 0으로만 구성된 변수 제거 ===")
train_data <- remove_zero_vars(train_data)

cat("\n=== 테스트 데이터에서 0으로만 구성된 변수 제거 ===")
test_data <- remove_zero_vars(test_data)

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
