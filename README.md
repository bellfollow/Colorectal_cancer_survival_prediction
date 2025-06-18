# 대장암 생존 예측 AI 프로젝트

[![GitHub license](https://img.shields.io/github/license/bellfollow/Colorectal_cancer_survival_prediction)](https://github.com/bellfollow/Colorectal_cancer_survival_prediction/blob/main/LICENSE)

## 🎯 프로젝트 개요

대장암 환자의 생존 예측을 위한 AI 시스템으로, GAN으로 생성된 가상 임상 데이터를 기반으로 R 기반의 생존분석 모델과 로컬 LLM(ollama)을 통합한 의료 상담 시스템을 제공합니다.

## 📊 데이터셋 정보

### 데이터셋 개요

- **데이터 출처**: GAN(생성적 적대 신경망)으로 생성된 가상 임상 데이터셋
- **데이터 분할**:
  - 훈련 데이터: 10,000건
  - 테스트 데이터: 5,000건
- **변수 수**: 총 52개 변수
- **데이터셋 설명 문서**: [대장암 합성 데이터셋 정보.md](대장암%20합성%20데이터셋%20정보.md)

### 주요 변수

| 중분류 | 변수명 | 설명 | 값 예시/코드 |
|--------|--------|------|--------------|
| 기본정보 | AGE | 진단 시 연령 | 67 |
| 암등록 | 조직학적 진단명 | mucinous, signet ring cell, adenocarcinoma 등 | 0=아니오, 1=예 |
| 암등록 | 병기(STAGE) 정보 | Tis, T1, T2, T3, T4, N1, N2, N3, M1 등 | 0=아니오, 1=예 |
| 건강정보 | Type of Drink | 음주 종류 | 1=맥주, 2=소주, 3=양주, 99=기타 |
| 건강정보 | Smoke | 흡연 여부 | 0=비흡연, 1=현재흡연, 2=과거흡연 |
| 신체계측 | Height, Weight | 신장, 체중 | 예: 170.1, 64.5 |
| 면역병리 | EGFR | 면역병리 EGFR 검사 결과 | 1=negative, 2=positive, 99=해당없음 |
| 분자병리 | MSI, KRASMUTATION, NRASMUTATION, BRAF_MUTATION | 분자병리 검사 결과 | 1=not detected, 2=detected, 99=해당없음 |
| 수술여부 | Operation | 대장암 수술 여부 | 0=아니오, 1=예 |
| 항암제치료 | Chemotherapy | 항암제 치료 여부 | 0=아니오, 1=예 |
| 방사선치료 | Radiation Therapy | 방사선 치료 여부 | 0=아니오, 1=예 |
| 기본정보 | Death | 사망 여부 | 0=아니오, 1=예 |
| 기본정보 | Survival period | 암 진단 후 생존 일수 | 예: 267 (days) |

> **참고**: 코드값 99는 "모름/기타/미측정"을 의미

## 🛠 기술 스택

- **언어**: R 100%
- **패키지**:
  - `tidyverse`: 데이터 처리 및 시각화
  - `survival`: 생존분석
  - `shiny`: 웹 대시보드
  - `renv`: 패키지 의존성 관리
  - `httr`: LLM API 통신
  - `caret`: 머신러닝 모델링
  - `xgboost`: 부스팅 알고리즘
  - `randomForest`: 랜덤 포레스트

## 🚀 설치 및 실행

1. **프로젝트 설정**
```r
# 프로젝트 디렉토리로 이동
setwd("path/to/project")

# 패키지 의존성 복원
renv::restore()
```

2. **데이터 전처리**
```r
source("pre_process/preprocess_data.R")
```

3. **모델 학습 및 평가**
```r
source("R/03_survival_modeling.R")
source("R/04_ml_models.R")
source("R/05_model_evaluation.R")
```

4. **Shiny 앱 실행**
```r
# Shiny 앱 실행
shiny::runApp("R/shiny_app")
```

## 📈 주요 기능

1. **생존 예측 모델**
   - Cox 비례위험모델
   - Random Forest
   - XGBoost
   - 앙상블 모델
   - 모델 성능 평가

2. **데이터 전처리**
   - 결측치 처리
   - 이상치 탐지 및 처리
   - 데이터 변환
   - 피처 엔지니어링

3. **시각화 대시보드**
   - Kaplan-Meier 생존곡선
   - 위험비 Forest Plot
   - Feature Importance
   - ROC Curve
   - 모델 성능 비교

4. **AI 의료 상담**
   - 환자별 맞춤 상담
   - 생존율 해석
   - 치료 권장사항

## 📄 라이선스

MIT License - see [LICENSE](LICENSE) for details

## 📁 프로젝트 구조

```
Colorectal_cancer_survival_prediction/
├── README.md
├── R/
│   ├── 01_data_preparation.R
│   ├── 02_exploratory_analysis.R
│   ├── 03_survival_modeling.R
│   ├── 04_ml_models.R
│   ├── 05_model_evaluation.R
│   └── shiny_app/
│       ├── ui.R
│       ├── server.R
│       ├── global.R
│       └── llm_functions.R
├── pre_process/
│   ├── preprocess_data.R
│   ├── data_cleaning.R
│   ├── feature_engineering.R
│   └── data_validation.R
├── data/
│   └── 암임상 라이브러리 합성데이터 train test set(대장암).xlsx
├── models/
├── plots/
├── .Rprofile
├── .Rbuildignore
├── .RData
├── .Rhistory
├── .Rproj.user
├── DESCRIPTION
├── renv/
├── renv.lock
└── 암환자_생존율예측.Rproj
```

### 각 디렉토리의 목적

- `R/`: R 스크립트 파일들
  - `01_data_preparation.R`: 데이터 전처리
  - `02_exploratory_analysis.R`: 탐색적 데이터 분석
  - `03_survival_modeling.R`: 생존분석 모델링
  - `04_ml_models.R`: 머신러닝 모델
  - `05_model_evaluation.R`: 모델 평가
  - `shiny_app/`: Shiny 웹 애플리케이션

- `pre_process/`: 데이터 전처리 관련 스크립트
  - `preprocess_data.R`: 데이터 전처리 주 프로세스
  - `data_cleaning.R`: 데이터 정제
  - `feature_engineering.R`: 피처 엔지니어링
  - `data_validation.R`: 데이터 검증

- `data/`: 원시 데이터 및 전처리된 데이터
- `models/`: 학습된 모델 저장
- `plots/`: 생성된 시각화 파일
- `renv/`: 패키지 의존성 관리
- `DESCRIPTION`: R 패키지 설명 파일
- `.Rprofile`: R 프로젝트 설정
- `.Rbuildignore`: 빌드 시 무시할 파일 설정
- `.RData`: R 세션 데이터
- `.Rhistory`: R 명령어 이력
- `.Rproj.user`: RStudio 프로젝트 설정
- `renv.lock`: 패키지 의존성 버전 정보
- `암환자_생존율예측.Rproj`: RStudio 프로젝트 파일

## 📝 관련 문서

- [대장암 합성 데이터셋 정보.md](대장암%20합성%20데이터셋%20정보.md): 데이터셋 상세 설명
- [process.md](process.md): 프로젝트 프로세스 설명
- [prob_solv.md](prob_solv.md): 문제 해결 과정 설명
- [asd.md](asd.md): 추가 설명 문서
