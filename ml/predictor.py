# ml/predictor.py

import pandas as pd
import pickle
import os

MODEL_PATH = os.path.join("model_data", "category_predictor.pkl")

# 모델과 피처 순서 불러오기
with open(MODEL_PATH, "rb") as f:
    model, feature_order = pickle.load(f)

def predict_category(input_data: dict) -> dict:
    df = pd.DataFrame([input_data])
    df = df.reindex(columns=feature_order, fill_value=0)

    # 예측 확률 계산
    probs = model.predict_proba(df)[0]
    labels = model.classes_

    # 가장 높은 확률 찾기
    max_idx = probs.argmax()
    prediction = labels[max_idx]
    confidence = round(probs[max_idx], 4)  # 소수점 4자리까지 반환

    return {
        "prediction": prediction,
        "confidence": confidence
    }
