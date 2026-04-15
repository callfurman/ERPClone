import os
import time
import csv
import logging
import requests
from dotenv import load_dotenv

# 🔐 Загрузка ключа
load_dotenv()
API_KEY = os.getenv("DADATA_API_KEY")
SECRET_KEY = os.getenv("DADATA_SECRET_KEY")
if not API_KEY:
    raise ValueError("❌ Укажите DADATA_API_KEY в файле .env")

URL = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/geolocate/address"
HEADERS = {
    "Authorization": f"Token {API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}
DELAY = 0.4
TIMEOUT = 10
OUTPUT = "dadata_reverse_30.csv"

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(message)s", datefmt="%H:%M:%S")

# 📍 Ровно 30 координат из вашего списка (lat, lon)
COORDS = [
    (55.7552921, 37.6176294), (55.7579795, 37.611263), (55.7639781, 37.6372038),
    (55.747186, 37.586536), (55.752219, 37.5923887), (55.7329539, 37.627147),
    (55.7625866, 37.6271387), (55.7671175, 37.5601109), (55.7106177, 37.5774773),
    (55.7817407, 37.6325789), (59.93584, 30.325866), (59.9401126, 30.3128061),
    (59.928855, 30.33866), (59.922972, 30.309544), (59.9358328, 30.3372245),
    (59.937197, 30.347785), (59.955775, 30.329298), (59.9407562, 30.3002204),
    (59.946302, 30.354343), (59.9338179, 30.3484245), (56.8364135, 60.6002825),
    (55.062889, 82.91175), (55.7907556, 49.1216778), (56.3089103, 43.9873194),
    (53.194324, 50.0936898), (55.1598343, 61.3981365), (54.9864413, 73.3728233),
    (47.2217159, 39.712198), (54.761345, 56.013339), (56.0118986, 92.87363)
]

def run_reverse():
    session = requests.Session()
    results = []
    total = len(COORDS)
    logging.info(f"🚀 Запуск обратного геокодирования DaData. Точек: {total}")

    for i, (lat, lon) in enumerate(COORDS, 1):
        logging.info(f"[{i}/{total}] 🔄 {lat},{lon}")
        start = time.perf_counter()
        try:
            payload = {"lat": lat, "lon": lon, "radius_meters": 100, "count": 1}
            resp = session.post(URL, headers=HEADERS, json=payload, timeout=TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            elapsed = (time.perf_counter() - start) * 1000
            address = data.get("suggestions", [{}])[0].get("value", "") if data.get("suggestions") else None
        except Exception as e:
            logging.error(f"❌ Ошибка: {e}")
            address, elapsed = None, 0

        results.append({
            "query_coords": f"{lat},{lon}",
            "result_address": address,
            "found": bool(address),
            "time_ms": round(elapsed, 1)
        })
        time.sleep(DELAY)

    with open(OUTPUT, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)

    found = sum(1 for r in results if r["found"])
    logging.info(f"✅ Готово! Файл: {OUTPUT}")
    logging.info(f"📊 Успешно: {found}/{total} ({found/total*100:.1f}%)")

if __name__ == "__main__":
    run_reverse()