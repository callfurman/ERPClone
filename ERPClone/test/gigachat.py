import os
import time
import csv
import json
import logging
import requests
import urllib3
from dotenv import load_dotenv

# ⚠️ Отключаем предупреждения об SSL (только для тестов!)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 🔐 Загрузка токена из .env
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
OUTPUT = "gigachat_30_results.csv"
DELAY = 3.0
TIMEOUT = 30

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(message)s", datefmt="%H:%M:%S")

# 📥 30 адресов
ADDRESSES = [
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

def query_gigachat(session, address):
    prompt = f"""Найди географические координаты (широту и долготу) для адреса: {address}

Верни ответ ТОЛЬКО в формате JSON без пояснений:
{{
  "lat": число,
  "lon": число
}}"""
    
    payload = {
        "model": "GigaChat",
        "messages": [
            {"role": "system", "content": "Ты — геоинформационный ассистент. Возвращай координаты строго в формате JSON с полями lat и lon."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.1,
        "max_tokens": 200
    }
    
    try:
        # ✅ Добавлено verify=False для обхода SSL-ошибки
        resp = session.post(URL, headers=HEADERS, json=payload, timeout=TIMEOUT, verify=False)
        resp.raise_for_status()
        data = resp.json()
        
        content = data["choices"][0]["message"]["content"]
        content = content.strip()
        
        # Удаляем markdown-обёртку если есть
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].strip()
        
        coords = json.loads(content)
        return coords.get("lat"), coords.get("lon"), content
        
    except Exception as e:
        logging.error(f"❌ Ошибка: {e}")
        return None, None, str(e)

def run_benchmark():
    session = requests.Session()
    results = []
    total = len(ADDRESSES)
    
    logging.info(f"🚀 Запуск GigaChat. Адресов: {total}")

    for i, addr in enumerate(ADDRESSES, 1):
        logging.info(f"[{i}/{total}] 📍 {addr[:50]}...")
        
        start = time.perf_counter()
        lat, lon, raw_response = query_gigachat(session, addr)
        elapsed = (time.perf_counter() - start) * 1000
        
        results.append({
            "address": addr,
            "lat": lat,
            "lon": lon,
            "found": bool(lat and lon),
            "time_ms": round(elapsed, 1)
        })
        
        if lat and lon:
            logging.info(f"   ✅ {lat},{lon}")
        else:
            logging.info(f"   ❌ Не найдено")
        
        time.sleep(DELAY)

    with open(OUTPUT, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=["address", "lat", "lon", "found", "time_ms"])
        writer.writeheader()
        writer.writerows(results)
    
    found = sum(1 for r in results if r["found"])
    logging.info(f"✅ Готово! Файл: {OUTPUT}")
    logging.info(f"📊 Успешно: {found}/{total} ({found/total*100:.1f}%)")

if __name__ == "__main__":
    run_benchmark()