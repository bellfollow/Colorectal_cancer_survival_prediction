# 패키지 설치 및 renv 설정

# 필요한 패키지 목록
packages <- c(
  "tidyverse", "survival", "survminer", "flexsurv", "randomForest",
  "ranger", "xgboost", "mlr3", "tidymodels", "DALEX", "iml", "survex",
  "shiny", "shinydashboard", "DT", "plotly", "VIM", "mice", "httr",
  "jsonlite", "readxl", "janitor", "rms", "h2o"
)

# R 4.3 이상 확인
if (getRversion() < "4.3.0") {
  stop("R 4.3 이상이 필요합니다. 현재 버전: ", getRversion())
}

# 패키지 설치 함수
install_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    print(paste("Installing", pkg))
    install.packages(pkg)
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(paste("Failed to install", pkg))
    }
  } else {
    print(paste("Package", pkg, "already installed"))
  }
}

# renv 패키지 설치 및 초기화
if (!requireNamespace("renv", quietly = TRUE)) {
  print("Installing renv")
  install.packages("renv")
}

# renv 초기화
print("Initializing renv")
renv::init()

# 필요한 패키지 설치
print("Installing required packages...")
for (pkg in packages) {
  install_package(pkg)
}

# 패키지 의존성 저장
print("Saving package dependencies...")
renv::snapshot()

print("Package installation and renv setup complete!")
