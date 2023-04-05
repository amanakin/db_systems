# Анализ MongoDB

### Система
MacBook Pro (13-inch, M1, 2020)\
**Chip:** Apple M1\
**Memory:** 8GB

База данных запущена в Docker

### Пререквизиты

**Версия MongoDB**: 6.0.5

`docker-compose.yml:`
```yaml
services:
  mongodb:
    image: mongo
    container_name: mongodb
    environment:
      - PUID=1001
      - PGID=1001
    volumes:
      - /Users/anton/Projects/db_systems/mongodata:/data/db
    ports:
      - 27017:27017
    restart: unless-stopped
```

Для замера производительности использовался MongoDB Compass.

## Датасет

В качестве данных использовались сведения о ДТП в США:
[ссылка на датасет](https://www.kaggle.com/datasets/sobhanmoosavi/us-accidents).

Пример данных:
```json
{
  "_id": {
    "$oid": "642dc3b35ab100fe8c0f7bf5"
  },
  "ID": "A-1068",
  "Severity": 2,
  "Start_Time": "2016-03-24 11:20:57",
  "End_Time": "2016-03-24 17:20:57",
  "Start_Lat": 37.7017,
  "Start_Lng": -121.88372,
  "End_Lat": 37.70172,
  "End_Lng": -121.88859,
  "Distance(mi)": 0.266,
  "Description": "At Hacienda Dr - Accident.",
  "Street": "I-580 W",
  "Side": "R",
  "City": "Pleasanton",
  "County": "Alameda",
  "State": "CA",
  "Zipcode": 94588,
  "Country": "US",
  "Timezone": "US/Pacific",
  "Airport_Code": "KLVK",
  "Weather_Timestamp": "2016-03-24 10:53:00",
  "Temperature(F)": 60.1,
  "Humidity(%)": 62,
  "Pressure(in)": 30.27,
  "Visibility(mi)": 10,
  "Wind_Direction": "SW",
  "Wind_Speed(mph)": 4.6,
  "Weather_Condition": "Clear",
  "Amenity": false,
  "Bump": false,
  "Crossing": false,
  "Give_Way": false,
  "Junction": true,
  "No_Exit": false,
  "Railway": true,
  "Roundabout": false,
  "Station": false,
  "Stop": false,
  "Traffic_Calming": false,
  "Traffic_Signal": false,
  "Turning_Loop": false,
  "Sunrise_Sunset": "Day",
  "Civil_Twilight": "Day",
  "Nautical_Twilight": "Day",
  "Astronomical_Twilight": "Day"
}
```

Интересные для нас поля:
* `Severity` Показывает тяжесть аварии, число от 1 до 4.
* 

## Простые запросы

### Create

```
db.us.insertOne({"Severity": 1, "Start_Time": "2023-04-05 22:00:00", "End_Time": "2023-04-05 22:00:00", "Description": "Doint DB homework"})
```
Result:
```
{
  acknowledged: true,
  insertedId: ObjectId("642dd504b9bca2fcbbc1ac2b")
}
```

### Read
```
db.us.findOne({_id: ObjectId("642dd73fb9bca2fcbbc1ac2c")})
```
Result:
```
{
  _id: ObjectId("642dd73fb9bca2fcbbc1ac2c"),
  Severity: 1,
  Start_Time: '2023-04-05 22:00:00',
  End_Time: '2023-04-05 22:00:00',
  Description: 'Doint DB homework'
}
```

### Update
```
db.us.updateOne({"_id": ObjectId("642dd504b9bca2fcbbc1ac2b")}, {$set: {"Description": "Doing DB homework"}})
```
Result:
```
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

### Delete
```
db.us.deleteOne({_id: ObjectId("642dd504b9bca2fcbbc1ac2b")})
```
Result:
```
{
  acknowledged: true,
  deletedCount: 1
}
```

## Индексы

Попробуем более сложные запросы.

Получить самые серьезные ДТП с самым сильным ветром (если уровень ДТП одинаковый, то отбираем по скорости ветра) с 2016 по 2019 года.
```
db.us.find({Start_Time: {$regex: '201[6-9]-'}}).sort({Severity: -1, 'Wind_Speed(mph)': -1})
```
**CollScan:** 9689ms\
**Sort:** 7910ms

Добавим индекс на поле `Severity: -1` и `Wind_Speed(mph): -1`.
Получившийся индекс весит 22MB. 

Результаты запроса с индексом:\
**Fetch:** 28910ms\
**IXScan** 784ms

Как видим, запрос стал намного дольше, mongo просматривает абсолютно
все ключи индекса, а их 2.8 миллиона. Из-за этого могут быть проблемы с оперативной памятью или просто 
слишком долгим проходом по индексу.

При этом даже если упростим фильтр, то получим такие же даные:
```
db.us.find({Railway: true, State: 'CA'}).sort({Severity: -1, 'Wind_Speed(mph)': -1})
```
С индексами:\
**Fetch:** 11805ms\
**IXScan** 270

Без индексов:\
**CollScan:** 1974\
**Sort:** 73

На таких больших данных куда быстрее сначала применить фильтр, а потом на маленьком количестве данных отсортировать в памяти
нужные данные.

