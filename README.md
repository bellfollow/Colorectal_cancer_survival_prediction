# 대장암 생존 예측 AI 프로젝트 (EOCRC/LOCRC)

[![GitHub license](https://img.shields.io/github/license/bellfollow/Colorectal_cancer_survival_prediction)](https://github.com/bellfollow/Colorectal_cancer_survival_prediction/blob/main/LICENSE)

## 🎯 프로젝트 개요

대장암 환자의 생존 예측을 위한 분석 시스템으로, 조기발병 대장암(EOCRC)과 만기발병 대장암(LOCRC) 그룹별로 생존 예측 모델을 개발했습니다. R을 사용한 생존 분석과 다변량 분석을 통해 주요 예후 인자를 규명하고, 모델 성능을 평가했습니다.

## 📊 분석 결과 요약

### 주요 발견사항

#### EOCRC (Early-Onset Colorectal Cancer)
- **유의한 예후인자**: 
  - 시그넷링세포암 (p=0.042, HR=1.27)
- **모델 성능**: C-index = 0.551

#### LOCRC (Late-Onset Colorectal Cancer)
- **유의한 예후인자**:
  - 체중 (p=0.037, HR=1.004)
- **모델 성능**: C-index = 0.536

### 데이터셋 정보

- **데이터 출처**: GAN(생성적 적대 신경망)으로 생성된 가상 임상 데이터셋
- **데이터 분할**:
  - EOCRC: 1,000건
  - LOCRC: 1,000건
- **주요 변수**: 
  - 생존 시간(일)
  - 사망 여부
  - 임상적 병기
  - 조직학적 유형
  - 치료 방법 등

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
- **주요 패키지**:
  - `survival`: 생존 분석
  - `survminer`: 생존 분석 시각화
  - `tidyverse`: 데이터 처리 및 시각화
  - `car`: 다중공선성 검정
  - `knitr`: 보고서 생성
  - `broom`: 모델 결과 정리

## 📈 분석 방법론

1. **단변량 분석**
   - 각 변수별 Cox 비례위험모델 적합
   - p-value < 0.25 기준으로 유의변수 선정

2. **다변량 분석**
   - 단변량에서 선정된 변수로 다변량 모델 구축
   - 모델 적합도 검정 (Likelihood ratio test)
   - Harrell's C-index로 예측력 평가
   - VIF를 통한 다중공선성 검정

## 🚀 분석 실행 방법

1. **필요 패키지 설치**
```r
install.packages(c("tidyverse", "survival", "survminer", "knitr", "broom", "car"))
```

2. **분석 스크립트 실행**
```r
# 단변량 분석
source("R/02_02_exploratory_analysis.R")

# 다변량 분석
source("R/02_03_exploratory_analysis.R")
```

3. **결과 확인**
- 분석 결과는 콘솔에 출력되며, 상세 내용은 `docs/survival_analysis_documentation.md`에서 확인 가능

## 📂 프로젝트 구조

```
Colorectal_cancer_survival_prediction/
├── R/
│   ├── 02_02_exploratory_analysis.R  # 단변량 분석
│   └── 02_03_exploratory_analysis.R  # 다변량 분석
├── data/
│   ├── 1_train_EOCRC.csv            # EOCRC 학습 데이터
│   └── 1_train_LOCRC.csv            # LOCRC 학습 데이터
├── docs/
│   ├── survival_analysis_documentation.md  # 상세 분석 결과
│   └── data_preparation_README.md   # 데이터 전처리 문서
└── README.md                        # 현재 파일
```

## 📝 분석 결과 상세

자세한 분석 결과는 다음 문서에서 확인하실 수 있습니다:
- [상세 분석 결과 보기](docs/survival_analysis_documentation.md)
- [데이터 전처리 문서](docs/data_preparation_README.md)

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📧 문의

분석에 대한 문의사항이 있으시면 이슈를 등록해주세요.

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
