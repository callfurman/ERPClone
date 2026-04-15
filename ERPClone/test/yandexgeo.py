import os
import time
import random
import csv
import logging
import requests
from dotenv import load_dotenv  # Для загрузки переменных из .env

# 🔧 1. ЗАГРУЗКА НАСТРОЕК
load_dotenv()  # Загружает переменные из файла .env в окружение

API_KEY = os.getenv("YANDEX_API_KEY")
if not API_KEY:
    raise ValueError("❌ Ошибка: Ключ YANDEX_API_KEY не найден! Проверьте файл .env")

BASE_URL = "https://geocode-maps.yandex.ru/1.x/"
OUTPUT_CSV = "yandex_30_results.csv"

# ⏱ Настройки троттлинга
DELAY_BASE = 0.6
DELAY_JITTER = 0.4
TIMEOUT = 10

# 📊 Логирование
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%H:%M:%S"
)

# 📥 2. СПИСОК ИЗ 30 АДРЕСОВ (Сбалансированная выборка)
# 10 Москва + 10 СПб + 10 Регионы
ADDRESSES = [
    # Москва
    "109012, г. Москва, Красная площадь, д. 1",
    "125009, г. Москва, Тверская ул., д. 7",
    "101000, г. Москва, ул. Мясницкая, д. 26",
    "119019, г. Москва, ул. Арбат, д. 51",
    "127006, г. Москва, ул. Новый Арбат, д. 15",
    "115035, г. Москва, ул. Пятницкая, д. 62",
    "107031, г. Москва, Кузнецкий Мост ул., д. 21/5",
    "123001, г. Москва, ул. 1905 года, д. 8",
    "119121, г. Москва, Ленинский проспект, д. 32А",
    "129090, г. Москва, проспект Мира, д. 41",
    # Санкт-Петербург
    "190000, г. Санкт-Петербург, Невский пр., д. 28",
    "191186, г. Санкт-Петербург, Дворцовая площадь, д. 2",
    "191023, г. Санкт-Петербург, набережная реки Фонтанки, д. 62",
    "190031, г. Санкт-Петербург, Садовая ул., д. 54",
    "191011, г. Санкт-Петербург, ул. Итальянская, д. 25",
    "191002, г. Санкт-Петербург, Литейный пр., д. 51",
    "197046, г. Санкт-Петербург, ул. Куйбышева, д. 4",
    "199034, г. Санкт-Петербург, Университетская наб., д. 7",
    "191124, г. Санкт-Петербург, ул. Чайковского, д. 39",
    "191014, г. Санкт-Петербург, Литейный пр., д. 60",
    # Регионы
    "620014, г. Екатеринбург, ул. 8 Марта, д. 13",
    "630099, г. Новосибирск, Красный проспект, д. 20",
    "420014, г. Казань, ул. Кремлевская, д. 18",
    "603005, г. Нижний Новгород, ул. Большая Покровская, д. 82",
    "443099, г. Самара, ул. Куйбышева, д. 145",
    "454091, г. Челябинск, пр. Ленина, д. 57",
    "644099, г. Омск, ул. Ленина, д. 10",
    "344002, г. Ростов-на-Дону, ул. Большая Садовая, д. 47",
    "450008, г. Уфа, пр. Октября, д. 72",
    "660049, г. Красноярск, пр. Мира, д. 53"
]

# 🛠 Вспомогательные функции
def safe_sleep():
    time.sleep(DELAY_BASE + random.uniform(0, DELAY_JITTER))

def parse_yandex_response(data: dict) -> dict:
    members = data.get("response", {}).get("GeoObjectCollection", {}).get("featureMember", [])
    if not members:
        return {"found": False, "coords": None, "address": None, "kind": None}
    
    obj = members[0]["GeoObject"]
    lon, lat = map(float, obj["Point"]["pos"].split())
    kind = obj.get("metaDataProperty", {}).get("GeocoderMetaData", {}).get("kind")
    name = obj.get("name", "")
    
    return {
        "found": True,
        "coords": f"{lat:.6f},{lon:.6f}",
        "address": name,
        "kind": kind
    }

def query_yandex(session: requests.Session, params: dict):
    try:
        resp = session.get(BASE_URL, params=params, timeout=TIMEOUT)
        if resp.status_code == 429:
            logging.warning("⚠️ Rate Limit (429). Ждем 2 сек...")
            time.sleep(2)
            return None
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        logging.error(f"❌ Ошибка запроса: {e}")
        return None

# 🚀 Основной процесс
def run_benchmark():
    session = requests.Session()
    session.headers.update({"User-Agent": "GeocodeBenchmark/1.0"})
    
    results = []
    total = len(ADDRESSES)
    
    logging.info(f"🚀 Запуск Яндекс.Геокодера. Адресов: {total}")

    for i, addr in enumerate(ADDRESSES, 1):
        logging.info(f"[{i}/{total}] 📍 {addr[:50]}...")
        
        params = {"apikey": API_KEY, "geocode": addr, "format": "json", "results": 1}
        
        start = time.perf_counter()
        data = query_yandex(session, params)
        elapsed = (time.perf_counter() - start) * 1000
        
        parsed = parse_yandex_response(data) if data else {"found": False, "coords": None, "address": None, "kind": None}
        
        results.append({
            "type": "direct",
            "query": addr,
            "found": parsed["found"],
            "result_coords": parsed["coords"],
            "result_address": parsed["address"],
            "yandex_kind": parsed["kind"],
            "time_ms": round(elapsed, 1),
            "error": "API Error" if data is None else ""
        })
        safe_sleep()

    # 💾 Сохранение (utf-8-sig для Excel)
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    
    found = sum(1 for r in results if r["found"])
    logging.info(f"✅ Готово! Файл: {OUTPUT_CSV}")
    logging.info(f"📊 Успешно: {found}/{total} ({found/total*100:.1f}%)")

if __name__ == "__main__":
    run_benchmark()