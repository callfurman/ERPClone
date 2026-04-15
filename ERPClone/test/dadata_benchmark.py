import os
import time
import csv
import logging
import requests
from dotenv import load_dotenv

# 🔐 Загрузка ключей из .env файла
load_dotenv()
API_KEY = os.getenv("DADATA_API_KEY")
SECRET_KEY = os.getenv("DADATA_SECRET_KEY")

if not API_KEY or not SECRET_KEY:
    raise ValueError("❌ Ошибка: Ключи DADATA не найдены! Создайте файл .env рядом со скриптом.")

URL_CLEANER = "https://cleaner.dadata.ru/api/v1/clean/address"
URL_GEOLOCATE = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/geolocate/address"
OUTPUT_CSV = "dadata_results.csv"
DELAY = 0.4
TIMEOUT = 10

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-8s | %(message)s", datefmt="%H:%M:%S")

# 📥 30 адресов (идентичны списку для Яндекса)
ADDRESSES = [
    "109012, г. Москва, Красная площадь, д. 1", "125009, г. Москва, Тверская ул., д. 7",
    "101000, г. Москва, ул. Мясницкая, д. 26", "119019, г. Москва, ул. Арбат, д. 51",
    "127006, г. Москва, ул. Новый Арбат, д. 15", "115035, г. Москва, ул. Пятницкая, д. 62",
    "107031, г. Москва, Кузнецкий Мост ул., д. 21/5", "123001, г. Москва, ул. 1905 года, д. 8",
    "119121, г. Москва, Ленинский проспект, д. 32А", "129090, г. Москва, проспект Мира, д. 41",
    "190000, г. Санкт-Петербург, Невский пр., д. 28", "191186, г. Санкт-Петербург, Дворцовая площадь, д. 2",
    "191023, г. Санкт-Петербург, набережная реки Фонтанки, д. 62", "190031, г. Санкт-Петербург, Садовая ул., д. 54",
    "191011, г. Санкт-Петербург, ул. Итальянская, д. 25", "191002, г. Санкт-Петербург, Литейный пр., д. 51",
    "197046, г. Санкт-Петербург, ул. Куйбышева, д. 4", "199034, г. Санкт-Петербург, Университетская наб., д. 7",
    "191124, г. Санкт-Петербург, ул. Чайковского, д. 39", "191014, г. Санкт-Петербург, Литейный пр., д. 60",
    "620014, г. Екатеринбург, ул. 8 Марта, д. 13", "630099, г. Новосибирск, Красный проспект, д. 20",
    "420014, г. Казань, ул. Кремлевская, д. 18", "603005, г. Нижний Новгород, ул. Большая Покровская, д. 82",
    "443099, г. Самара, ул. Куйбышева, д. 145", "454091, г. Челябинск, пр. Ленина, д. 57",
    "644099, г. Омск, ул. Ленина, д. 10", "344002, г. Ростов-на-Дону, ул. Большая Садовая, д. 47",
    "450008, г. Уфа, пр. Октября, д. 72", "660049, г. Красноярск, пр. Мира, д. 53"
]

# 📍 20 координат для обратного геокодирования
COORDS = [
    (55.753544, 37.621202), (59.939131, 30.315882), (55.796289, 49.108980), (56.328674, 44.002059),
    (54.989347, 73.368221), (53.195538, 50.100202), (47.222531, 39.718705), (56.838002, 60.597295),
    (55.041500, 82.934600), (56.852544, 53.204843), (45.043317, 38.975882), (48.719390, 44.501840),
    (54.734853, 55.957855), (58.520721, 31.301470), (59.557049, 150.803543), (43.585525, 39.723062),
    (44.616650, 33.525366), (60.153033, 59.986748), (51.768199, 55.096955), (53.361406, 55.925674)
]

# Заголовки API
HEADERS_CLEAN = {
    "Authorization": f"Token {API_KEY}",
    "X-Secret": SECRET_KEY,
    "Content-Type": "application/json"
}
HEADERS_GEO = {
    "Authorization": f"Token {API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def run_benchmark():
    session = requests.Session()
    results = []
    total = len(ADDRESSES) + len(COORDS)
    logging.info(f"🚀 Запуск DaData. Запросов: {total}")

    # 1. Прямое геокодирование (Cleaner)
    for i, addr in enumerate(ADDRESSES, 1):
        logging.info(f"[{i}/{total}] 📍 {addr[:50]}...")
        start = time.perf_counter()
        try:
            resp = session.post(URL_CLEANER, headers=HEADERS_CLEAN, json=[addr], timeout=TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            elapsed = (time.perf_counter() - start) * 1000
            
            if data and len(data) > 0:
                item = data[0]
                # ✅ Важно: DaData Cleaner возвращает координаты в полях geo_lat / geo_lon
                lat, lon = item.get("geo_lat"), item.get("geo_lon")
                coords_str = f"{lat},{lon}" if lat and lon else None
                address = item.get("value", "")
                qc = item.get("qc", "")
            else:
                coords_str, address, qc = None, None, None
        except Exception as e:
            logging.error(f"❌ Ошибка: {e}")
            coords_str, address, qc, elapsed = None, None, None, 0

        results.append({
            "type": "direct", "query": addr, "found": bool(coords_str),
            "result_coords": coords_str, "result_address": address, "qc": qc, "time_ms": round(elapsed, 1)
        })
        time.sleep(DELAY)

    # 2. Обратное геокодирование (Geolocate)
    for i, (lat, lon) in enumerate(COORDS, 1 + len(ADDRESSES)):
        logging.info(f"[{i}/{total}] 🔄 {lat},{lon}")
        start = time.perf_counter()
        try:
            payload = {"lat": lat, "lon": lon, "radius_meters": 100, "count": 1}
            resp = session.post(URL_GEOLOCATE, headers=HEADERS_GEO, json=payload, timeout=TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            elapsed = (time.perf_counter() - start) * 1000
            address = data.get("suggestions", [{}])[0].get("value", "") if data.get("suggestions") else None
        except Exception as e:
            logging.error(f"❌ Ошибка: {e}")
            address, elapsed = None, 0

        results.append({
            "type": "reverse", "query": f"{lat},{lon}", "found": bool(address),
            "result_coords": None, "result_address": address, "qc": None, "time_ms": round(elapsed, 1)
        })
        time.sleep(DELAY)

    # 💾 Сохранение
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    
    found = sum(1 for r in results if r["found"])
    logging.info(f"✅ ГОТОВО! Файл: {OUTPUT_CSV}")
    logging.info(f"📊 Успешно: {found}/{total} ({found/total*100:.1f}%)")

if __name__ == "__main__":
    run_benchmark()