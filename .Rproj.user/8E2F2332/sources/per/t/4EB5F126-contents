# 01_data_preparation.R
# 데이터 로드 및 전처리 스크립트

# 필요한 패키지 로드
library(tidyverse)
library(readxl)

# 데이터 파일 경로 설정
train_file <- "pre_process/암임상_라이브러리_합성데이터_train.csv"
test_file <- "pre_process/암임상_라이브러리_합성데이터_test.csv"

# 데이터 로드
train_data <- read.csv(train_file, fileEncoding = "UTF-8-BOM")
test_data <- read.csv(test_file, fileEncoding = "UTF-8-BOM")

# 데이터 검증 및 기본 정보 출력
print("Train 데이터셋 정보:")
glimpse(train_data)
print("\nTest 데이터셋 정보:")
glimpse(test_data)

# 결측치 확인
print("\nTrain 데이터 결측치:")
sum(is.na(train_data))
print("\nTest 데이터 결측치:")
sum(is.na(test_data))

