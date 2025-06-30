# 대장암 생존 분석 문서화

이 문서는 대장암 환자의 생존 분석을 위한 R 스크립트를 설명합니다. 조기발병 대장암(EOCRC)과 만기발병 대장암(LOCRC)에 대한 단변량 및 다변량 생존 분석을 포함합니다.

## 목차
1. [개요](#개요)
2. [데이터 준비](#데이터-준비)
3. [단변량 생존 분석](#단변량-생존-분석)
4. [다변량 생존 분석](#다변량-생존-분석)
5. [결론](#결론)

## 개요

이 분석은 대장암 환자의 생존에 영향을 미치는 요인을 파악하기 위해 수행되었습니다. 두 가지 주요 그룹에 대해 분석을 수행했습니다:

- **EOCRC (Early-Onset Colorectal Cancer)**: 조기발병 대장암 (50세 이하)
- **LOCRC (Late-Onset Colorectal Cancer)**: 만기발병 대장암 (50세 초과)

## 데이터 준비

### 필요한 패키지

```r
# 필수 패키지
library(tidyverse)    # 데이터 조작 및 시각화
library(survival)     # 생존 분석
library(survminer)    # 생존 분석 시각화
library(knitr)        # 표 출력
library(broom)        # 모델 결과 정리
library(car)          # 다중공선성 검사 (다변량 분석용)
```

### 데이터 로드

```r
# 데이터 로드 (UTF-8-BOM 인코딩)
eocrc_data <- read.csv("data/1_train_EOCRC.csv", fileEncoding = "UTF-8-BOM")
locrc_data <- read.csv("data/1_train_LOCRC.csv", fileEncoding = "UTF-8-BOM")
```

## 단변량 생존 분석

### 분석 방법

각 변수에 대해 단변량 Cox 비례위험 모델을 적합시켜 생존과의 연관성을 평가했습니다.

### 주요 코드

```r
# 단변량 Cox 회귀 분석 함수
perform_univariate_analysis <- function(data, group_name) {
  # 분석에서 제외할 변수들
  exclude_vars <- c("순번.No.", "cancer_type", "암진단후생존일수.Survival.period.")
  
  # 분석에 사용할 변수들 선택
  vars_to_analyze <- setdiff(names(data), c(exclude_vars, "사망여부.Death."))
  
  # 각 변수별로 단변량 Cox 회귀 분석 수행
  for (var in vars_to_analyze) {
    # 결측치가 있는 경우 제외
    temp_data <- data[!is.na(data[[var]]), ]
    
    # 모델 공식 생성 및 적합
    formula <- as.formula(paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", var))
    cox_model <- coxph(formula, data = temp_data)
    
    # 결과 추출 및 저장
    # ...
  }
  
  # p-value < 0.25인 유의한 변수 필터링
  significant_results <- results[results$p_value < 0.25, ]
  
  # 생존곡선 시각화 (범주형 변수에 한해)
  # ...
}
```

### 주요 결과

- **EOCRC 그룹**: 유의한 변수 목록 (p < 0.25)
- **LOCRC 그룹**: 유의한 변수 목록 (p < 0.25)

## 다변량 생존 분석

### 분석 방법

단변량 분석에서 유의한 변수(p < 0.25)를 기반으로 다변량 Cox 회귀 모델을 구축했습니다.

### 주요 코드

```r
# 다변량 Cox 회귀 분석 함수
perform_multivariate_analysis <- function(data, group_name) {
  # M_stage 처리
  if ("M_stage" %in% names(analysis_data)) {
    analysis_data$M_stage <- factor(analysis_data$M_stage, levels = c("M0", "M1"))
    analysis_data$M_stage_M1 <- as.numeric(analysis_data$M_stage == "M1")
  }
  
  # 그룹별 유의 변수 선택
  if (group_name == "EOCRC") {
    vars_to_analyze <- eocrc_significant_vars
  } else {
    vars_to_analyze <- gsub("M_stage", "M_stage_M1", locrc_significant_vars)
  }
  
  # 모델 적합
  formula_str <- paste("Surv(암진단후생존일수.Survival.period., 사망여부.Death.) ~", 
                      paste(vars_to_analyze, collapse = " + "))
  cox_model <- coxph(as.formula(formula_str), data = analysis_data)
  
  # 모델 평가
  c_index <- concordance(cox_model)$concordance
  
  # 다중공선성 검사
  if (require(car)) {
    vif_values <- car::vif(cox_model)
  }
  
  return(list(model = cox_model, c_index = c_index, vif = vif_values))
}
```

### 모델 평가
### EOCRC
```
===  EOCRC 그룹 다변량 Cox 회귀 분석 (p < 0.25 유의변수 기반) ===

[다변량 분석 결과]


                                               Variable                                           HR   CI_lower   CI_upper   p_value
---------------------------------------------  ---------------------------------------------  ------  ---------  ---------  --------
조직학적진단명.코드.설명.signet.ring.cell.     조직학적진단명.코드.설명.signet.ring.cell.      1.270      2.743      4.940     0.042
체중측정값.Weight.                             체중측정값.Weight.                              0.996      2.690      2.723     0.168
조직학적진단명.코드.설명.Neoplasm.malignant.   조직학적진단명.코드.설명.Neoplasm.malignant.    1.159      2.517      4.288     0.204
항암제.치료.여부.Chemotherapy.                 항암제.치료.여부.Chemotherapy.                  0.852      1.938      2.996     0.215
조직학적진단명.코드.설명.carcinoide.tumor.     조직학적진단명.코드.설명.carcinoide.tumor.      1.150      2.487      4.269     0.239

[유의미한 변수 (p < 0.25)]


                                               Variable                                           HR   CI_lower   CI_upper   p_value
---------------------------------------------  ---------------------------------------------  ------  ---------  ---------  --------
조직학적진단명.코드.설명.signet.ring.cell.     조직학적진단명.코드.설명.signet.ring.cell.      1.270      2.743      4.940     0.042
체중측정값.Weight.                             체중측정값.Weight.                              0.996      2.690      2.723     0.168
조직학적진단명.코드.설명.Neoplasm.malignant.   조직학적진단명.코드.설명.Neoplasm.malignant.    1.159      2.517      4.288     0.204
항암제.치료.여부.Chemotherapy.                 항암제.치료.여부.Chemotherapy.                  0.852      1.938      2.996     0.215
조직학적진단명.코드.설명.carcinoide.tumor.     조직학적진단명.코드.설명.carcinoide.tumor.      1.150      2.487      4.269     0.239

[모델 적합도 검정 (Likelihood ratio test)]
Analysis of Deviance Table
 Cox model: response is Surv(암진단후생존일수.Survival.period., 사망여부.Death.)
Terms added sequentially (first to last)

                                              loglik  Chisq Df Pr(>|Chi|)
NULL                                         -3929.4
조직학적진단명.코드.설명.signet.ring.cell.   -3927.2 4.3116  1    0.03785 *
체중측정값.Weight.                           -3926.3 1.9298  1    0.16478
조직학적진단명.코드.설명.Neoplasm.malignant. -3925.3 1.9036  1    0.16768
항암제.치료.여부.Chemotherapy.               -3924.5 1.5600  1    0.21167
조직학적진단명.코드.설명.carcinoide.tumor.   -3923.9 1.3409  1    0.24688
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

[모델의 Harrell's C-index] 0.551
```
### LOCRC
```
===  LOCRC 그룹 다변량 Cox 회귀 분석 (p < 0.25 유의변수 기반) ===

[다변량 분석 결과]


                                                     Variable                                                 HR   CI_lower   CI_upper   p_value        
---------------------------------------------------  ---------------------------------------------------  ------  ---------  ---------  --------        
체중측정값.Weight.                                   체중측정값.Weight.                                    1.004      2.719      2.741     0.037        
조직학적진단명.코드.설명.Neuroendocrine.carcinoma.   조직학적진단명.코드.설명.Neuroendocrine.carcinoma.    1.160      2.690      3.895     0.067        
분자병리MSI검사결과코드.명.MSI.                      분자병리MSI검사결과코드.명.MSI.                       0.951      2.442      2.753     0.116        
진단시연령.AGE.                                      진단시연령.AGE.                                       0.996      2.694      2.722     0.159        
조직학적진단명.코드.설명.carcinoide.tumor.           조직학적진단명.코드.설명.carcinoide.tumor.            1.121      2.594      3.739     0.167
M_stage_M1                                           M_stage_M1                                            1.075      2.611      3.332     0.211        
항암제.치료.여부.Chemotherapy.                       항암제.치료.여부.Chemotherapy.                        1.102      2.567      3.622     0.223        

[유의미한 변수 (p < 0.25)]


                                                     Variable                                                 HR   CI_lower   CI_upper   p_value        
---------------------------------------------------  ---------------------------------------------------  ------  ---------  ---------  --------        
체중측정값.Weight.                                   체중측정값.Weight.                                    1.004      2.719      2.741     0.037        
조직학적진단명.코드.설명.Neuroendocrine.carcinoma.   조직학적진단명.코드.설명.Neuroendocrine.carcinoma.    1.160      2.690      3.895     0.067        
분자병리MSI검사결과코드.명.MSI.                      분자병리MSI검사결과코드.명.MSI.                       0.951      2.442      2.753     0.116
진단시연령.AGE.                                      진단시연령.AGE.                                       0.996      2.694      2.722     0.159        
조직학적진단명.코드.설명.carcinoide.tumor.           조직학적진단명.코드.설명.carcinoide.tumor.            1.121      2.594      3.739     0.167        
M_stage_M1                                           M_stage_M1                                            1.075      2.611      3.332     0.211        
항암제.치료.여부.Chemotherapy.                       항암제.치료.여부.Chemotherapy.                        1.102      2.567      3.622     0.223        

[모델 적합도 검정 (Likelihood ratio test)]
Analysis of Deviance Table
 Cox model: response is Surv(암진단후생존일수.Survival.period., 사망여부.Death.)
Terms added sequentially (first to last)

                                                    loglik  Chisq Df Pr(>|Chi|)
NULL                                               -9530.3
체중측정값.Weight.                                 -9528.3 3.9845  1    0.04592
조직학적진단명.코드.설명.Neuroendocrine.carcinoma. -9526.7 3.2158  1    0.07293
분자병리MSI검사결과코드.명.MSI.                    -9525.4 2.5367  1    0.11123
진단시연령.AGE.                                    -9524.3 2.2081  1    0.13729
조직학적진단명.코드.설명.carcinoide.tumor.         -9523.4 1.8881  1    0.16942
M_stage_M1                                         -9522.6 1.6452  1    0.19962
항암제.치료.여부.Chemotherapy.                     -9521.8 1.4508  1    0.22840

NULL
체중측정값.Weight.                                 *
조직학적진단명.코드.설명.Neuroendocrine.carcinoma. .
분자병리MSI검사결과코드.명.MSI.
진단시연령.AGE.
조직학적진단명.코드.설명.carcinoide.tumor.
M_stage_M1
항암제.치료.여부.Chemotherapy.
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

[모델의 Harrell's C-index] 0.536
```

### VIF 다중 공선성 분석
#### EOCRC 모델에 대한 다중 공선성
```
=== EOCRC 모델 다중공선성 검사 (VIF) ===
  조직학적진단명.코드.설명.signet.ring.cell.
                                    1.005112
                          체중측정값.Weight.
                                    1.002901
조직학적진단명.코드.설명.Neoplasm.malignant.
                                    1.009914
              항암제.치료.여부.Chemotherapy.
                                    1.004617
  조직학적진단명.코드.설명.carcinoide.tumor.
                                    1.003651
```

#### LOCRC 모델에 대한 다중 공선성
```
=== LOCRC 모델 다중공선성 검사 (VIF) ===
                                체중측정값.Weight.
                                          1.000794
조직학적진단명.코드.설명.Neuroendocrine.carcinoma.
                                          1.001673
                   분자병리MSI검사결과코드.명.MSI.
                                          1.000919
                                   진단시연령.AGE.
                                          1.004158
        조직학적진단명.코드.설명.carcinoide.tumor.
                                          1.000920
                                          1.000919
                                   진단시연령.AGE.
                                          1.004158
        조직학적진단명.코드.설명.carcinoide.tumor.
      1.000920
                                        M_stage_M1
                                          1.004928
                    항암제.치료.여부.Chemotherapy.
                                          1.001160
```

### 결론
(1) 임상적·통계적 요약
- EOCRC:
    - 시그넷링세포암이 독립적 예후인자(p=0.042, HR=1.27)
    - 나머지 변수들은 p < 0.25까지 포함되나, 통계적으로 유의하지 않음
    - 예측력(C-index) 0.551로 낮음
- LOCRC:
    - 체중만이 독립적 예후인자(p=0.037, HR=1.004)
    - p < 0.25까지 확대하면 여러 변수 포함 가능
    - 예측력(C-index) 0.536으로 낮음

(2) 모델의 한계
- 예측력(C-index)가 0.5대로, 무작위 예측과 거의 차이가 없음
- 논문(s41598-025-95385-0.pdf)에서는 C-index 0.88(EOCRC), 0.86(LOCRC) 수준의 높은 예측력을 보였으나
    - 현재 데이터셋에서는 표본 수, 이벤트 수, 변수 다양성의 한계로 예측력이 낮음
- p < 0.25까지 포함해도 임상적으로 의미 있는 변수(병기, 치료 등)가 통계적으로 유의하지 않음

(3) 다중공선성 문제 없음
- 모든 변수의 VIF가 1~1.01 수준으로, 다중공선성(변수 간 중복 설명력) 문제는 없음