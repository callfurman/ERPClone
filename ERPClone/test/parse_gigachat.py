import json

# Ваш ответ от GigaChat (скопированный из Postman)
GIGACHAT_RESPONSE = {
    "choices": [
        {
            "message": {
                "content": "[\n{\"address\": \"109012, г. Москва, Красная площадь, д. 1\", \"lat\": 55.75222, \"lon\": 37.61556},\n{\"address\": \"125009, г. Москва, Тверская ул., д. 7\", \"lat\": 55.75972, \"lon\": 37.62321},\n{\"address\": \"101000, г. Москва, ул. Мясницкая, д. 26\", \"lat\": 55.76139, \"lon\": 37.62222},\n{\"address\": \"119019, г. Москва, ул. Арбат, д. 51\", \"lat\": 55.75972, \"lon\": 37.61944},\n{\"address\": \"127006, г. Москва, ул. Новый Арбат, д. 15\", \"lat\": 55.75806, \"lon\": 37.58333},\n{\"address\": \"115035, г. Москва, ул. Пятницкая, д. 62\", \"lat\": 55.73333, \"lon\": 37.60278},\n{\"address\": \"107031, г. Москва, Кузнецкий Мост ул., д. 21/5\", \"lat\": 55.7625, \"lon\": 37.62361},\n{\"address\": \"123001, г. Москва, ул. 1905 года, д. 8\", \"lat\": 55.77306, \"lon\": 37.60861},\n{\"address\": \"119121, г. Москва, Ленинский проспект, д. 32А\", \"lat\": 55.68333, \"lon\": 37.48333},\n{\"address\": \"129090, г. Москва, проспект Мира, д. 41\", \"lat\": 55.825, \"lon\": 37.60806}\n]",
                "role": "assistant"
            }
        }
    ]
}

# Извлекаем и парсим
content = GIGACHAT_RESPONSE["choices"][0]["message"]["content"]
coords_list = json.loads(content)  # Парсим строку как JSON

# Выводим таблицу
print(f"{'Адрес':<60} | {'GigaChat lat,lon':<20}")
print("-" * 85)
for item in coords_list:
    addr = item["address"]
    lat, lon = item["lat"], item["lon"]
    print(f"{addr:<60} | {lat}, {lon}")

# Сохраняем в CSV для сравнения
import csv
with open("gigachat_coords.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(f, fieldnames=["address", "lat", "lon"])
    writer.writeheader()
    writer.writerows(coords_list)

print(f"\n✅ Сохранено {len(coords_list)} координат в gigachat_coords.csv")