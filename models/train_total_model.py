import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
import pickle
import os

# 경로
CSV_PATH = os.path.join("..", "data", "spending_regression_data.csv")
MODEL_PATH = os.path.join("..", "model_data", "total_spending_predictor.pkl")


# 데이터 로드
df = pd.read_csv(CSV_PATH)

X = df[["식비", "교통", "문화", "의료", "주거"]]
y = df["total_spending"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestRegressor()
model.fit(X_train, y_train)

# 저장
os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
with open(MODEL_PATH, 'wb') as f:
    pickle.dump((model, list(X.columns)), f)

print("✅ 총소비액 회귀 모델 학습 및 저장 완료:", MODEL_PATH)
