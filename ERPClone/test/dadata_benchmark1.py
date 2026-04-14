import requests
import json

API_KEY = "c30223b4fa27571354d8ee083ed57aec9b90f3b8"
SECRET_KEY = "d49ce68a8de0de72e483b240f49d8dc70e072b62"

URL = "https://cleaner.dadata.ru/api/v1/clean/address"

HEADERS = {
    "Authorization": f"Token {API_KEY}",
    "X-Secret": SECRET_KEY,
    "Content-Type": "application/json"
}

# Тест на 5 адресах
test_addresses = [
    "Москва, Красная площадь, 1",
    "Санкт-Петербург, Невский проспект, 28",
    "Казань, Кремлевская, 18"
]

print("🔍 Тестируем DaData Cleaner API...\n")

for addr in test_addresses:
    print(f"📍 Адрес: {addr}")
    try:
        resp = requests.post(URL, headers=HEADERS, json=[addr], timeout=10)
        print(f"   Статус: {resp.status_code}")
        
        if resp.status_code == 200:
            data = resp.json()
            print(f"   Ответ: {json.dumps(data, ensure_ascii=False, indent=2)[:300]}")
            if data and len(data) > 0:
                item = data[0]
                print(f"   ✅ Координаты: {item.get('lat')}, {item.get('lon')}")
                print(f"   ✅ Адрес: {item.get('value')}")
            else:
                print("   ❌ Пустой ответ от API")
        else:
            print(f"   ❌ Ошибка: {resp.text[:200]}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    print()