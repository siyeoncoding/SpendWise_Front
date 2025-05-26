import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
import pickle
import os

# 경로 설정
CSV_PATH = os.path.join("..", "data", "spending_data_10users_12months_utf8.csv")
MODEL_PATH = os.path.join("..", "model_data", "category_predictor.pkl")

# 데이터 로딩
df = pd.read_csv(CSV_PATH)

# 'month' 컬럼 생성 (yyyy-MM 형식으로)
df['month'] = pd.to_datetime(df['date']).dt.to_period('M').astype(str)

# Pivot 처리: 월 + 사용자 기준, 카테고리별 소비 합계
pivot = df.pivot_table(
    index=['month', 'user_id'],
    columns='category',
    values='amount',
    aggfunc='sum',
    fill_value=0
).reset_index()

# 카테고리 컬럼만 추출
category_cols = pivot.columns.difference(['month', 'user_id'])

# 소비 비율로 정규화 (row-wise normalize)
pivot[category_cols] = pivot[category_cols].div(pivot[category_cols].sum(axis=1), axis=0)

# 가장 많이 소비한 카테고리를 라벨로 지정
pivot['label'] = pivot[category_cols].idxmax(axis=1)

# X, y 데이터 분리
X = pivot[category_cols]
y = pivot['label']

# 모델 학습
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

#기존
#model = DecisionTreeClassifier()



# 바꾼 버전
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# feature 순서 함께 저장
feature_order = list(X.columns)
os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
with open(MODEL_PATH, 'wb') as f:
    pickle.dump((model, feature_order), f)

print("모델 학습 및 저장 완료:", MODEL_PATH)
