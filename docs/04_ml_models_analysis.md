# `04_ml_models.R` 코드 분석 및 설명

## 1. 개요

`04_ml_models.R` 스크립트는 전처리된 결장암 환자 데이터를 사용하여 생존 예측 모델과 분류 모델을 구축, 훈련, 평가하는 전체 머신러닝 파이프라인을 담당합니다. 이 스크립트의 최종 목표는 다양한 조건(EOCRC/LOCRC, 1/3/5년 생존율)에 대한 모델을 생성하고, 그 성능을 평가하여 후속 분석(`05_model_evaluation.R`)에서 사용할 수 있도록 결과를 저장하는 것입니다.

## 2. 주요 기능 및 함수 설명

스크립트는 여러 헬퍼(helper) 함수와 메인 로직으로 구성되어 있습니다.

### `apply_smote_if_needed` 함수

- **목적**: 클래스 불균형 문제를 해결하기 위해 SMOTE(Synthetic Minority Over-sampling Technique) 오버샘플링을 적용합니다.
- **핵심 로직**:
    1. **NA 값 제거**: SMOTE는 NA 값을 처리할 수 없으므로, 모델링에 사용할 변수와 타겟 변수에서 NA를 포함한 모든 행을 먼저 제거합니다.
    2. **불균형 비율 확인**: 다수 클래스와 소수 클래스의 비율을 계산하여, 이 비율이 5:1 이상으로 심각한 불균형 상태일 때만 SMOTE를 적용합니다. 불필요한 오버샘플링을 방지하여 원본 데이터의 특성을 최대한 유지하기 위함입니다.
    3. **최소 샘플 수 확인**: SMOTE의 `k` 파라미터는 소수 클래스의 샘플 수보다 작아야 합니다. 만약 소수 클래스의 샘플 수가 너무 적어 `k` 값을 설정할 수 없는 경우, SMOTE 적용을 건너뛰어 오류를 방지합니다.
    4. **타겟 변수 인코딩**: SMOTE 적용 전후로 타겟 변수의 인코딩(예: `0`/`1`을 `Died`/`Survived`로)을 일관성 있게 유지하여 데이터의 의미를 명확하게 합니다.

### `train_evaluate_rsf` 함수

- **목적**: 생존 분석을 위한 RSF(Random Survival Forest) 모델을 훈련하고 평가합니다.
- **핵심 로직**:
    1. **데이터 준비**: 범주형 변수를 팩터(factor)로 변환하여 모델이 올바르게 인식하도록 합니다.
    2. **모델 훈련**: `randomForestSRC` 패키지의 `rfsrc()` 함수를 사용하여 RSF 모델을 훈련합니다. 생존 시간(`OS_days`)과 생존 여부(`vital_status`)를 `Surv()` 객체로 결합하여 모델에 전달합니다.
    3. **성능 평가**: 테스트 데이터셋에 대한 C-index(Concordance Index)를 계산하여 모델의 예측 성능을 평가합니다.
    4. **변수 중요도 시각화**: 모델이 어떤 변수를 중요하게 생각하는지 파악하기 위해 변수 중요도(Permutation Importance)를 계산하고 `ggplot2`를 이용해 시각화합니다.

### `train_evaluate_classifier` 함수

- **목적**: 특정 시점(1, 3, 5년)의 생존 여부를 예측하는 이진 분류 모델(Random Forest, XGBoost, GBM)을 훈련하고 평가합니다.
- **핵심 로직**:
    1. **결측치 처리**: 훈련 데이터의 예측 변수(predictor)에 있는 NA 값을 각 변수의 중앙값(median)으로 대체합니다. 이는 모델 훈련 시 결측치로 인한 오류를 방지하고 데이터 손실을 최소화하기 위함입니다.
    2. **단일 클래스 데이터 처리**: 훈련 데이터의 타겟 변수에 클래스가 하나만 존재하는 경우(예: 5년 생존자 데이터에 생존자가 없는 경우), 모델 훈련이 불가능하므로 해당 모델링 과정을 건너뛰고 `NULL`을 반환하는 방어 코드를 추가했습니다. 이를 통해 전체 파이프라인이 중단되는 것을 방지합니다.
    3. **팩터 레벨 이름 변환**: `caret` 패키지는 팩터 레벨 이름으로 숫자를 허용하지 않으므로, `make.names()` 함수를 사용하여 `0`, `1`과 같은 레벨을 `X0`, `X1`과 같이 유효한 R 변수 이름으로 변환합니다. 이 작업은 "invalid class levels" 오류를 해결하기 위해 필수적이었습니다.
    4. **모델 훈련 및 교차 검증**: `caret::train` 함수를 사용하여 5-겹 교차 검증(5-fold CV) 방식으로 모델을 훈련합니다. `ROC`를 기준으로 최적의 모델을 선택하도록 설정합니다.
    5. **성능 평가**: 테스트 데이터에 대한 예측을 수행하고, 혼동 행렬(Confusion Matrix)과 AUC(Area Under ROC Curve)를 계산하여 모델 성능을 다각도로 평가합니다. AUC 계산 시, 예측 확률 열을 하드코딩된 이름(`"1"`) 대신 동적으로 두 번째 열(`[, 2]`)로 선택하도록 수정하여 팩터 레벨 이름 변경에 따른 오류를 해결했습니다.

## 3. 메인 실행 흐름

1. **데이터 로딩**: `03_data_preprocessing.R`에서 생성된 전처리 데이터를 불러옵니다.
2. **모델링 반복**: `EOCRC`/`LOCRC` 각 그룹과 `1-year`/`3-year`/`5-year` 각 생존 기간에 대해 반복문을 실행합니다.
3. **생존/분류 모델 선택**: 전체 생존 기간을 예측하는 경우 RSF 모델(`train_evaluate_rsf`)을, 특정 시점의 생존 여부를 예측하는 경우 분류 모델(`train_evaluate_classifier`)을 실행합니다.
4. **결과 저장**: 모든 모델의 훈련 결과(모델 객체, 평가 지표, 시각화 자료 등)를 리스트에 저장한 후, 최종적으로 `results/models/` 폴더에 `.rds` 파일 형태로 저장하여 영구 보존합니다.

## 4. 결론

`04_ml_models.R` 스크립트는 데이터의 특성과 발생 가능한 여러 예외 상황(결측치, 클래스 불균형, 단일 클래스 데이터 등)을 체계적으로 처리하여 안정적으로 다양한 머신러닝 모델을 구축하고 평가하는 핵심적인 파이프라인입니다. 이 스크립트를 통해 생성된 모델들은 프로젝트의 최종 목표인 결장암 환자의 생존 예측 가능성을 탐색하는 데 사용됩니다.
```
