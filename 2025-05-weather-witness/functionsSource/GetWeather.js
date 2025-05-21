
// ref: https://openweathermap.org/api/geocoding-api
const geoCodingRequest = Functions.makeHttpRequest({
  url: "http://api.openweathermap.org/geo/1.0/zip",
  method: "GET",
  params: { zip: `${args[0]},${args[1]}`, appid: secrets.apiKey }
})

const geoCodingResponse = await geoCodingRequest;

if (geoCodingResponse.error) throw Error("Request failed, try checking the params provided")

// ref: https://openweathermap.org/current
const weatherRequest = Functions.makeHttpRequest({
  url: "https://api.openweathermap.org/data/2.5/weather",
  method: "GET",
  params: { lat: geoCodingResponse.data.lat, lon: geoCodingResponse.data.lon, appid: secrets.apiKey }
})

const weatherResponse = await weatherRequest
if (weatherResponse.error) throw Error("Request failed, try checking the params provided")

const weather_id = weatherResponse.data.weather[0].id;
const weather_id_x = parseInt(weather_id / 100);

let weather_enum = 0;


// ref: https://openweathermap.org/weather-conditions
// thunderstorm
if (weather_id_x === 2) weather_enum = 3;
// rain
else if (weather_id_x === 3 || weather_id_x === 5) weather_enum = 2;
// snow
else if (weather_id_x === 6) weather_enum = 5;
// clear
else if (weather_id === 800) weather_enum = 0;
// cloudy
else if (weather_id_x === 8) weather_enum = 1;
// windy
else weather_enum = 4;

return Functions.encodeUint256(weather_enum);
