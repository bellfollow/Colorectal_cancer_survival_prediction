# 02_exploratory_analysis.R
# 
# 대장암 환자의 생존 예측을 위한 탐색적 데이터 분석(EDA) 코드
# 
# 주요 분석 순서:
# 1. 데이터 전반적인 이해
# 2. 임상 변수들 간의 상관관계 분석
# 3. 병기와 생존 관련성 분석
# 4. 생존 분석

# 필요한 패키지 로드
library(survival)
library(survminer)
library(corrplot)

# 데이터 로드 및 기본 정보 출력
data <- read.csv("pre_process/암임상_라이브러리_합성데이터_train.csv")

cat("\n=== 데이터 기본 정보 ===\n")
cat("데이터 차원:", dim(data), "\n")
cat("변수명:\n")
print(names(data))

# 전체 분석 실행
cat("\n=== EDA 시작 ===\n")

# 1. 임상 변수들 간의 상관관계 분석
analyze_clinical <- function(data) {
  # 임상적으로 의미 있는 연속형 변수들 선택
  clinical_vars <- data %>% 
    select(
      # 연령
      `진단시연령.AGE.`,
      # 신체계측
      `신장값.Height.`,
      `체중측정값.Weight.`,
      # 생존
      `암진단후생존일수.Survival.period.`
    ) %>%
    select_if(~sd(.x, na.rm = TRUE) > 0)
  
  if(ncol(clinical_vars) > 1) {
    cat("\n=== 임상 변수들 간의 상관관계 ===\n")
    cat("분석 대상 변수 수:", ncol(clinical_vars), "개\n")
    
    # 상관관계 계산
    cor_matrix <- cor(clinical_vars, use = "complete.obs")
    
    # 상관관계 시각화
    if(!is.null(cor_matrix)) {
      # 새 플롯 창 생성
      plot.new()
      
      # corrplot 시각화
      corrplot(cor_matrix, method = "circle", 
               type = "upper", diag = FALSE,
               tl.col = "black", tl.srt = 45, 
               tl.cex = 0.8,  # 텍스트 크기 조정
               mar = c(0, 0, 1, 0))  # 마진 조정
    }
    
    # 상관관계가 높은 변수들 출력
    high_cor <- cor_matrix[upper.tri(cor_matrix)]
    high_cor <- high_cor[abs(high_cor) > 0.3]
    if(length(high_cor) > 0) {
      cat("\n상관관계가 높은 변수들 (절대값 > 0.3):\n")
      print(sort(abs(high_cor), decreasing = TRUE))
    }
  }
}
analyze_clinical(data)

# 2. 병기와 생존 관련성 분석
analyze_stage_survival <- function(data) {
  if(ncol(data) > 1 && 
     all(c("암진단후생존일수.Survival.period.", 
           "사망여부.Death.") %in% names(data))) {
    
    cat("\n=== 병기와 생존 관련성 분석 ===\n")
    
    # 병기 변수들 선택
    stage_vars <- data %>% 
      select(starts_with("병기"))
    
    # 병기 변수들 출력
    cat("\n=== 병기 변수들 ===\n")
    print(names(stage_vars))
    
    if(ncol(stage_vars) > 0) {
      # 각 병기별 생존 분석
      for(stage in names(stage_vars)) {
        # 병기 변수의 유효성 체크
        if(any(data[[stage]] == 1)) {
          cat("\n===", stage, "과 생존의 관련성 ===\n")
          
          # 데이터프레임 행 수 확인
          cat("데이터프레임 행 수:", nrow(data), "\n")
          
          # 병기 변수의 정확한 이름 확인
          cat("분석 중인 병기 변수:", stage, "\n")
          
          # 병기 변수의 값 확인
          cat("병기 변수 값 분포:\n")
          print(table(data[[stage]]))
          
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
            
            # Kaplan-Meier 생존 곡선
            plot(surv_fit, 
                 col = c("red", "blue"),
                 xlab = "생존 시간 (일)", 
                 ylab = "생존 확률",
                 main = paste(stage, "과 생존의 관련성"))
            
            # 범주별 레전드
            stage_levels <- unique(data[[stage]])
            legend("topright", 
                   paste("", stage_levels), 
                   col = c("red", "blue"), 
                   lty = 1)
            
            # 생존 분석 결과
            cat("\n=== 생존 분석 결과 ===\n")
            print(summary(surv_fit))
            
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
        } else {
          cat("\n", stage, "변수에 유효한 값이 없습니다.\n")
        }
      }
    }
  }
}
analyze_stage_survival(data)

# 4. 생존 분석
analyze_survival <- function(data) {
  if(ncol(data) > 1 && 
     all(c("암진단후생존일수.Survival.period.", 
           "사망여부.Death.", 
           "대장암.수술.여부.Operation.") %in% names(data))) {
    
    cat("\n=== 생존 예측 분석 ===\n")
    
    # 생존 분석
    surv_fit <- survfit(
      Surv(`암진단후생존일수.Survival.period.`, 
           `사망여부.Death.` == 1) ~ 
        `대장암.수술.여부.Operation.`, 
      data = data
    )
    
    # Kaplan-Meier 생존 곡선
    plot(surv_fit, 
         col = c("red", "blue"),
         xlab = "생존 시간 (일)", 
         ylab = "생존 확률",
         main = "수술 여부에 따른 생존 곡선")
    legend("topright", 
           c("수술 O", "수술 X"), 
           col = c("red", "blue"), 
           lty = 1)
    
    # 생존 분석 결과
    cat("\n=== 생존 분석 결과 ===\n")
    print(summary(surv_fit))
    
    # ggsurvplot을 사용한 향상된 플롯
    ggsurvplot(
      surv_fit,
      data = data,
      conf.int = TRUE,
      pval = TRUE,
      risk.table = TRUE,
      title = "수술 여부에 따른 생존 곡선",
      xlab = "생존 시간 (일)",
      ylab = "생존 확률"
    )
  }
}
analyze_survival(data)


cat("\n=== EDA 완료 ===\n")
