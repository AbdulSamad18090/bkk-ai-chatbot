// app/api/chat/route.js
import { getWeatherDetails } from "@/app/tools/getWeatherDetails";
import { NextResponse } from "next/server";

const SYSTEM_PROMPT = `
You are an AI Weather Assistant with START, PLAN, ACTION, OBSERVATION, and OUTPUT stages.  
Wait for the user prompt and first PLAN using the available tools.  
After Planning, take the ACTION with the appropriate tool and wait for OBSERVATION.  
Once you get the OBSERVATION, return the final OUTPUT based on the START prompt and the collected observations.

Available Tools:
- function getWeatherDetails(city: string): string  
  getWeatherDetails is a function that accepts a city name (string) and returns the current weather in that city.

Supported cities: Karachi, Lahore, Islamabad, Peshawar, Quetta.  
If a city is not supported, clearly say so and do not fabricate data.

Example:
START  
{ "type": "user", "user": "What is the weather in Lahore?" }  
{ "type": "plan", "plan": "I will call getWeatherDetails for Lahore" }  
{ "type": "action", "function": "getWeatherDetails", "input": "lahore" }  
{ "type": "observation", "observation": "28°C, Partly Cloudy, Humidity 55%" }  
{ "type": "output", "output": "Weather in Lahore: 28°C, Partly Cloudy, Humidity 55%" }

START  
{ "type": "user", "user": "Tell me the weather in Karachi and Islamabad" }  
{ "type": "plan", "plan": "I will call getWeatherDetails for Karachi and Islamabad" }  
{ "type": "action", "function": "getWeatherDetails", "input": "karachi" }  
{ "type": "observation", "observation": "31°C, Sunny, Humidity 65%" }  
{ "type": "action", "function": "getWeatherDetails", "input": "islamabad" }  
{ "type": "observation", "observation": "26°C, Rainy, Humidity 70%" }  
{ "type": "output", "output": "Weather in Karachi: 31°C, Sunny, Humidity 65%. Weather in Islamabad: 26°C, Rainy, Humidity 70%." }
`;

export async function POST(req) {
  const { query } = await req.json();

  // Try to extract city name from query
  const supportedCities = [
    "karachi",
    "lahore",
    "islamabad",
    "peshawar",
    "quetta",
  ];
  const lowerQuery = query.toLowerCase();
  const city = supportedCities.find((c) => lowerQuery.includes(c));

  let weatherInfo = null;
  if (city) {
    weatherInfo = getWeatherDetails(city);
    if (weatherInfo.error) {
      return NextResponse.json({
        success: false,
        output: weatherInfo.error,
      });
    }

    // Directly respond without LLM if city is found
    return NextResponse.json({
      success: true,
      output: `Weather in ${city.charAt(0).toUpperCase() + city.slice(1)}: ${
        weatherInfo.temp
      }°C, ${weatherInfo.condition}, Humidity ${weatherInfo.humidity}%`,
    });
  }

  // Fallback: Ask the LLM (only if not found in our DB)
  const response = await fetch("http://localhost:11434/api/generate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "llama3.2",
      prompt: `${SYSTEM_PROMPT}\nUser: ${query}\nWeatherBot:`,
      stream: false,
    }),
  });

  const data = await response.json();

  return NextResponse.json({
    success: true,
    output: data.response,
  });
}
