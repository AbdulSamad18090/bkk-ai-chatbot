// tools/getWeatherDetails.js
export function getWeatherDetails(city) {
  const weatherData = {
    karachi: { temp: 31, condition: "Sunny", humidity: 65 },
    lahore: { temp: 28, condition: "Partly Cloudy", humidity: 55 },
    islamabad: { temp: 26, condition: "Rainy", humidity: 70 },
    peshawar: { temp: 30, condition: "Hot and Dry", humidity: 40 },
    quetta: { temp: 24, condition: "Cool and Breezy", humidity: 35 }
  };

  const cityKey = city.toLowerCase();
  if (weatherData[cityKey]) {
    return weatherData[cityKey];
  } else {
    return { error: "City not found in weather database." };
  }
}
