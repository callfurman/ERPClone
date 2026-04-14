import csv
import requests
import time

# 🔑 ВСТАВЬТЕ СЮДА ВАШ API-КЛЮЧ ЯНДЕКС (обязательно в кавычках!)
YANDEX_API_KEY = "d37508f3-92a4-4cea-b79d-ab0f49fae08e"

YANDEX_URL = "https://geocode-maps.yandex.ru/1.x/"
OUTPUT_FILE = "gigachat_vs_yandex.csv"

results = []
print("🔄 Запуск верификации координат GigaChat через Яндекс...")

try:
    with open("gigachat_coords.csv", "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader, 1):
            lat = row["lat"]
            lon = row["lon"]
            original_addr = row["address"]

            # Яндекс требует формат: долгота,широта
            params = {
                "apikey": YANDEX_API_KEY,
                "geocode": f"{lon},{lat}",
                "format": "json",
                "results": 1
            }

            try:
                resp = requests.get(YANDEX_URL, params=params, timeout=10)
                if resp.status_code == 200:
                    data = resp.json()
                    members = data.get("response", {}).get("GeoObjectCollection", {}).get("featureMember", [])
                    yandex_addr = members[0]["GeoObject"]["name"] if members else "NOT_FOUND"
                else:
                    yandex_addr = f"ERROR_{resp.status_code}"
            except Exception as e:
                yandex_addr = f"NET_ERROR: {str(e)[:30]}"

            # Статус совпадения
            is_match = "✅" if "ERROR" not in yandex_addr and "NET_ERROR" not in yandex_addr and yandex_addr != "NOT_FOUND" else "❌"

            results.append({
                "original_address": original_addr,
                "gigachat_coords": f"{lat},{lon}",
                "yandex_address": yandex_addr,
                "status": is_match
            })
            print(f"[{i}] {original_addr[:50]}... -> {yandex_addr[:50]}... [{is_match}]")
            time.sleep(0.6)  # Троттлинг для Яндекса

except FileNotFoundError:
    print("❌ Файл 'gigachat_coords.csv' не найден. Сначала запустите parse_gigachat.py")
    exit()

# 💾 Сохранение результатов
with open(OUTPUT_FILE, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(f, fieldnames=["original_address", "gigachat_coords", "yandex_address", "status"])
    writer.writeheader()
    writer.writerows(results)

print(f"\n✅ Готово! Результаты сохранены в {OUTPUT_FILE}")