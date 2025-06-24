# 데이터 전처리 프로세스 설명 문서

이 문서는 `01_data_preparation.R` 스크립트의 데이터 전처리 과정을 설명합니다.

## 1. 실행 환경 설정

### 1.1 필요한 패키지 로드
- `dplyr`: 데이터 조작
- `tidyr`: 데이터 정리
- `readr`: 데이터 읽기/쓰기
- `readxl`: 엑셀 파일 읽기
- `stringr`: 문자열 처리
- `purrr`: 함수형 프로그래밍
- `tibble`: 데이터프레임 개선
- `tidyselect`: tidy 선택 도우미
- `rlang`: tidy evaluation

### 1.2 데이터 파일 경로 설정
- 학습 데이터: `pre_process/암임상_라이브러리_합성데이터_train.csv`
- 테스트 데이터: `pre_process/암임상_라이브러리_합성데이터_test.csv`

## 2. 데이터 로드 및 기본 전처리

### 2.1 데이터 로드
- CSV 파일에서 데이터를 로드합니다.
- 18세 미만 환자는 제외합니다.

### 2.2 TNM 병기 처리
1. **T 병기 처리**
   - `병기STAGE.T`로 시작하는 변수들을 처리합니다.
   - T1-T4 단계로 그룹화합니다.
   - `T_stage` 변수로 통합합니다.

2. **N 병기 처리**
   - `병기STAGE.N`으로 시작하는 변수들을 처리합니다.
   - N0-N3 단계로 그룹화합니다.
   - `N_stage` 변수로 통합합니다.

3. **M 병기 처리**
   - `병기STAGE.M`으로 시작하는 변수들을 처리합니다.
   - M0, M1 단계로 그룹화합니다.
   - `M_stage` 변수로 통합합니다.

### 2.3 결측치 처리
1. **TNM Stage 변수 제외 처리**
   - TNM stage 변수(`T_stage`, `N_stage`, `M_stage`)는 결측치 처리를 하지 않습니다.
   - 99를 NA로만 변환하고 원본 유지

2. **일반 변수 처리**
   - **99를 NA로 변환**
   - **결측치 비율에 따른 처리**
     - 50% 이상: 변수 제외
     - 10% 이상 50% 미만: 
       - 수치형: 중앙값 대체
       - 범주형: '미실시' 범주 추가
     - 10% 미만: 해당 행 제거

### 2.4 EOCRC/LOCRC 분류
- **EOCRC (Early-Onset Colorectal Cancer)**: 50세 이하
- **LOCRC (Late-Onset Colorectal Cancer)**: 50세 초과

## 3. 데이터 분할 및 저장

### 3.1 학습/테스트 세트 분할
- 원본 데이터를 학습용과 테스트용으로 분할

### 3.2 EOCRC/LOCRC별 데이터 분할
- 각 세트를 다시 EOCRC와 LOCRC로 분할
  - `train_eocrc`: 학습용 EOCRC 데이터
  - `train_locrc`: 학습용 LOCRC 데이터
  - `test_eocrc`: 테스트용 EOCRC 데이터
  - `test_locrc`: 테스트용 LOCRC 데이터

### 3.3 파일 저장
- CSV 형식으로 저장 (UTF-8 인코딩)
  - `data/1_train_EOCRC.csv`
  - `data/1_train_LOCRC.csv`
  - `data/1_test_EOCRC.csv`
  - `data/1_test_LOCRC.csv`

## 4. 실행 결과 요약

### 4.1 데이터셋 크기
- 학습 데이터
  - EOCRC: [건수] 건
  - LOCRC: [건수] 건
- 테스트 데이터
  - EOCRC: [건수] 건
  - LOCRC: [건수] 건

### 4.2 변수 정보
- 총 변수 수: [21]개
- TNM stage 변수: T_stage, N_stage, M_stage
- 기타 임상 변수: [주요 변수들...]
- 이전 52개의 변수에서 많이 줄임임 

## 5. 주의사항
1. TNM stage 변수는 결측치 처리를 하지 않음
2. 99는 특수 코드로 간주하여 NA로 변환
3. 데이터 분할 시 환자 ID 중복을 방지하기 위해 주의 필요

## 6. 다음 단계
1. `02_exploratory_analysis.R`: 탐색적 데이터 분석 수행
2. `03_feature_engineering.R`: 특성 공학 수행
3. `04_modeling.R`: 모델 구축 및 평가
