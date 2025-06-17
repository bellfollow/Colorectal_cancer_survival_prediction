# 문제 해결 가이드

## 인코딩 문제
- 한글이 추가되어 있기에 UTF-8로 인코딩하면 한글이 깨진다, 
```R
train_data <- read_csv(train_file, locale = locale(encoding = "UTF-8-BOM")) 
test_data <- read_csv(test_file, locale = locale(encoding = "UTF-8-BOM")) 
```
- 위 코드를 실행하면 ``` 에러: Unknown encoding UTF-8-BOM ```이 나온다. 
- R의 read_csv() 함수에서 "UTF-8-BOM" 인코딩을 직접 지원하지 않아서 발생하는 문제

### 해결책 : 기본 read.csv 사용
```
train_data <- read.csv(train_file, fileEncoding = "UTF-8-BOM")
test_data <- read.csv(test_file, fileEncoding = "UTF-8-BOM")
```
하면 해결됨


## 표준편차 0
```R
> # 3. 변수 간 상관관계
> print("\n변수 간 상관관계:")
[1] "\n변수 간 상관관계:"
> cor_matrix <- cor(train_data %>% select(where(is.numeric)))
```
```shell
경고메시지(들):
cor(train_data %>% select(where(is.numeric)))에서: 표준편차가 0입니다
```
- 상관계수를 계산할 때 변수의 표준편차가 0인(즉, 모든 값이 동일한) 열이 포함되어 있기 때문
    -  train_data에서 select(where(is.numeric))로 뽑은 숫자형 변수들 중에 값이 전부 같은 변수가 있음
### 해결책 : 표준편차가 0인 열을 제거
```R
numeric_cols <- train_data %>%
  select(where(is.numeric)) %>%
  select_if(~sd(.x) > 0)

cor_matrix <- cor(numeric_cols)
```

## 너무 많은 피쳐 
```R
View(cor_matrix)
```
- 진행하면 너무 많은 요소가 있다.
- 순번은 상관관계에서 필요 없다보기 때문에 제거 후 