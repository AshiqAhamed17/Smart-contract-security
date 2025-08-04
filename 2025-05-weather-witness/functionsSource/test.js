// Simulated response from OpenWeather
const weatherResponse = {
    data: {
        weather: [{ id: 800 }]
    }
};

const weather_id = weatherResponse.data.weather[0].id;  // 800
const weather_id_x = parseInt(weather_id / 100);        // 8

let weather_enum = 1;

if (weather_id == 2) weather_enum = 3;
else if (weather_id === 800) weather_enum = 0;           // intended: SUNNY
else if (weather_id_x === 8) weather_enum = 1;          // also true → overwrites to CLOUDY
else weather_enum = 4;

console.log("Final weather_enum:", weather_enum); // Output: 1 → CLOUDY (wrong)