import os
import time
import csv
import json
import logging
import requests
import urllib3
from dotenv import load_dotenv

# ⚠️ Отключаем предупреждения об SSL (для Сбера)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 🔐 Загрузка токена
load_dotenv()
GIGACHAT_TOKEN = os.getenv("GIGACHAT_TOKEN")

if not GIGACHAT_TOKEN:
    raise ValueError("❌ Укажите GIGACHAT_TOKEN в файле .env")

URL = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions"
HEADERS = {
    "Authorization": f"Bearer {GIGACHAT_TOKEN}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}
OUTPUT = "gigachat_reverse_30.csv"
DELAY = 3.0
TIMEOUT = 30

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(message)s", datefmt="%H:%M:%S")

# 📍 30 координат для обратного геокодирования (lat, lon)
COORDS = [
    (55.751244, 37.618426), (55.763881, 37.614627), (55.763881, 37.619439),
    (55.75222, 37.61556), (55.748396, 37.597627), (55.748933, 37.610703),
    (55.764896, 37.61919), (55.76222, 37.63456), (55.687047, 37.530776),
    (55.7836, 37.6303), (59.93863, 30.31411), (59.93863, 30.31411),
    (59.938748, 30.311634), (59.937286, 30.321488), (59.943826, 30.327942),
    (59.937461, 30.321381), (59.932846, 30.321059), (59.938526, 30.314231),
    (59.937868, 30.314446), (59.937826, 30.322391), (56.83997, 60.61392),
    (55.041667, 82.926389), (55.796596, 49.118399), (56.329722, 44.004167),
    (53.2273, 50.2264), (55.162833, 61.439544), (55.0327, 82.9068),
    (47.2196, 39.7056), (54.7963, 55.9617), (56.028786, 92.841577)
]

def query_gigachat_reverse(session, lat, lon):
    """Запрос к GigaChat для получения адреса по координатам"""
    prompt = f"""Определи адрес (город, улица, дом) для географических координат:
Широта: {lat}
Долгота: {lon}

Верни ответ ТОЛЬКО в формате JSON без пояснений:
{{
  "address": "полный адрес текстом"
}}"""
    
    payload = {
        "model": "GigaChat",
        "messages": [
            {
                "role": "system",
                "content": "Ты — геоинформационный ассистент. Возвращай адреса строго в формате JSON с полем address."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0.1,
        "max_tokens": 200
    }
    
    try:
        resp = session.post(URL, headers=HEADERS, json=payload, timeout=TIMEOUT, verify=False)
        resp.raise_for_status()
        data = resp.json()
        
        content = data["choices"][0]["message"]["content"]
        content = content.strip()
        
        # Удаляем markdown-обёртку
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].strip()
        
        result = json.loads(content)
        return result.get("address", ""), content
        
    except Exception as e:
        logging.error(f"❌ Ошибка: {e}")
        return "", str(e)

def run_reverse_benchmark():
    session = requests.Session()
    results = []
    total = len(COORDS)
    
    logging.info(f"🚀 Запуск обратного геокодирования GigaChat. Точек: {total}")

    for i, (lat, lon) in enumerate(COORDS, 1):
        logging.info(f"[{i}/{total}] 🔄 {lat},{lon}")
        
        start = time.perf_counter()
        address, raw_response = query_gigachat_reverse(session, lat, lon)
        elapsed = (time.perf_counter() - start) * 1000
        
        results.append({
            "query_coords": f"{lat},{lon}",
            "lat": lat,
            "lon": lon,
            "result_address": address,
            "found": bool(address),
            "time_ms": round(elapsed, 1)
        })
        
        if address:
            logging.info(f"   ✅ {address[:60]}...")
        else:
            logging.info(f"   ❌ Не найдено")
        
        time.sleep(DELAY)

    # 💾 Сохранение
    with open(OUTPUT, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=["query_coords", "lat", "lon", "result_address", "found", "time_ms"])
        writer.writeheader()
        writer.writerows(results)
    
    found = sum(1 for r in results if r["found"])
    logging.info(f"✅ Готово! Файл: {OUTPUT}")
    logging.info(f"📊 Успешно: {found}/{total} ({found/total*100:.1f}%)")

if __name__ == "__main__":
    run_reverse_benchmark()