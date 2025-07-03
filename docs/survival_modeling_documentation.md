# 대장암 생존 예측 모델링 문서

## 개요
이 문서는 `03_survival_modeling.R` 스크립트에 대한 설명서입니다. 이 스크립트는 대장암(EOCRC, LOCRC) 환자의 생존 분석을 수행하고 예측 모델을 구축하기 위한 코드로 구성되어 있습니다.

## 1. 목적
- 대장암 환자의 생존 예측을 위한 Cox 비례위험모델 구축
- Kaplan-Meier 생존 곡선을 통한 생존 분석 시각화
- 위험군 분류 및 모델 성능 평가

## 2. 주요 기능

### 2.1 데이터 로드 및 전처리
- EOCRC(조기발생 대장암) 및 LOCRC(후기발생 대장암)에 대한 훈련/테스트 데이터셋 로드
- 유의한 변수 자동 로드 및 표준화

### 2.2 생존 분석 함수 (`perform_survival_analysis`)
- Cox 비례위험모델 적합
- Kaplan-Meier 생존 곡선 생성
- 위험군 분류 (High/Low Risk)
- 로그-랭크 검정(Log-rank test) 수행

### 2.3 테스트셋 평가 함수 (`evaluate_test_set`)
- 테스트셋에 대한 예측 수행
- Concordance Index (C-index) 계산
- 시간 의존적 ROC 곡선 분석 (1년, 3년, 5년 생존률)
- 위험 점수 기반 예측 성능 평가

## 3. 주요 출력물

### 3.1 모델 요약
- 변수별 위험비(HR) 및 유의성
- 모델 적합도 지표 (C-index)

### 3.2 시각화
- Kaplan-Meier 생존 곡선
- 위험군별 생존 곡선
- 시간 의존적 ROC 곡선
- 위험 점수 분포

## 4. 사용된 R 패키지
- `survival`: 생존 분석을 위한 핵심 패키지
- `survminer`: 생존 곡선 시각화
- `tidyverse`: 데이터 처리 및 시각화
- `timeROC`: 시간 의존적 ROC 곡선 분석

## 5. 실행 방법

1. 필요한 패키지 설치:
```r
install.packages(c("survival", "survminer", "tidyverse", "timeROC"))
```

2. 스크립트 실행:
```r
source("R/03_survival_modeling.R")
```

## 6. 주의사항
- 실행 전 `02_03_exploratory_analysis.R`이 먼저 실행되어 있어야 함
- 결과는 `results` 디렉토리에 저장됨
- 메모리 사용량이 많을 수 있으니 주의 요망

## 7. 출력 파일
- `results/eocrc_risk_scores.csv`: EOCRC 위험 점수
- `results/locrc_risk_scores.csv`: LOCRC 위험 점수
- `results/*.png`: 다양한 시각화 결과물

## 8. 문제 해결
- 패키지 설치 오류 시: 관리자 권한으로 R을 실행하거나 CRAN 미러 사이트 변경
- 메모리 부족 시: 데이터 크기를 줄이거나 더 많은 메모리 할당

## 9. 참고 문헌
- Therneau, T. M., & Grambsch, P. M. (2000). Modeling Survival Data: Extending the Cox Model. Springer.
- Kassambara, A., Kosinski, M., & Biecek, P. (2021). survminer: Drawing Survival Curves using 'ggplot2'.
- Blanche, P., et al. (2013). Review and comparison of ROC curve estimators for a time-dependent outcome with marker-dependent censoring.
