# 대장암 생존 예측 AI 프로젝트

[![GitHub license](https://img.shields.io/github/license/yourusername/colorectal-cancer-survival)](https://github.com/yourusername/colorectal-cancer-survival/blob/main/LICENSE)

## 🎯 프로젝트 개요

대장암 환자의 생존 예측을 위한 AI 시스템으로, R 기반의 생존분석 모델과 로컬 LLM(ollama)을 통합한 의료 상담 시스템을 제공합니다.

## 📊 데이터셋 정보

### 데이터셋 개요

- **데이터 목적**: GAN(생성적 적대 신경망)으로 생성된 가상 임상 데이터셋
- **데이터 분할**:
  - 훈련 데이터: 10,000건
  - 테스트 데이터: 5,000건
- **변수 수**: 총 52개 변수

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

## 🚀 설치 및 실행

1. **R 환경 설정**
```r
# R 4.3 이상 필요
# 필수 패키지 설치
install.packages("renv")
renv::restore()
```

2. **LLM 설정**
```bash
# ollama 설치
# Windows용 ollama 설치
# 의료 특화 모델 다운로드
ollama pull llama2:7b-chat
```

3. **Shiny 앱 실행**
```r
# 프로젝트 디렉토리로 이동
setwd("path/to/project")

# Shiny 앱 실행
shiny::runApp("R/shiny_app")
```

## 📈 주요 기능

1. **생존 예측 모델**
   - Cox 비례위험모델
   - Random Forest
   - XGBoost
   - 앙상블 모델

2. **시각화 대시보드**
   - Kaplan-Meier 생존곡선
   - 위험비 Forest Plot
   - Feature Importance
   - ROC Curve

3. **AI 의료 상담**
   - 환자별 맞춤 상담
   - 생존율 해석
   - 치료 권장사항

## 📄 라이선스

MIT License - see [LICENSE](LICENSE) for details

## 📁 프로젝트 구조

```
암환자_생존율예측/
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
├── data/
├── models/
├── plots/
├── DESCRIPTION
└── renv/  # 패키지 의존성 관리
```

### 각 디렉토리의 목적

- `R/`: R 스크립트 파일들
  - `01_data_preparation.R`: 데이터 전처리
  - `02_exploratory_analysis.R`: 탐색적 데이터 분석
  - `03_survival_modeling.R`: 생존분석 모델링
  - `04_ml_models.R`: 머신러닝 모델
  - `05_model_evaluation.R`: 모델 평가
  - `shiny_app/`: Shiny 웹 애플리케이션

- `data/`: 원시 데이터 및 전처리된 데이터
- `models/`: 학습된 모델 저장
- `plots/`: 생성된 시각화 파일
- `renv/`: 패키지 의존성 관리
- `DESCRIPTION`: R 패키지 설명 파일
