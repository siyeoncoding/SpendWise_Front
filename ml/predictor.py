# ml/predictor.py

import pandas as pd
import pickle
import os

MODEL_PATH = os.path.join("model_data", "category_predictor.pkl")

with open(MODEL_PATH, "rb") as f:
    model, feature_order = pickle.load(f)

def predict_category(input_data: dict) -> dict:
    df = pd.DataFrame([input_data])
    df = df.reindex(columns=feature_order, fill_value=0)

    probs = model.predict_proba(df)[0]
    labels = model.classes_

    # Top 1
    max_idx = probs.argmax()
    prediction = labels[max_idx]
    confidence = round(probs[max_idx], 4)

    # Top 3
    top_3_indices = probs.argsort()[-3:][::-1]
    top_3 = [
        {
            "category": labels[i],
            "confidence": round(probs[i], 4)
        }
        for i in top_3_indices
    ]

    return {
        "prediction": prediction,
        "confidence": confidence,
        "top_3": top_3
    }
