// app/api/chat/route.js
import fs from "fs";
import path from "path";
import { NextResponse } from "next/server";
import { GoogleGenerativeAI } from "@google/generative-ai";

export async function POST(req) {
  const { query } = await req.json();

  // Read the database schema file
  const schemaPath = path.join(process.cwd(), "app", "db.sql");
  const schema = fs.readFileSync(schemaPath, "utf8");

  const SYSTEM_PROMPT = `
    You are an expert SQL query generator.
    You are given the PostgreSQL database schema below:

    ${schema}

    Your task:
    - Read and understand the schema.
    - Given a user request, write a correct PostgreSQL SQL query using only the available tables and columns.
    - Do not guess column names or tables that do not exist.
    - Output ONLY the SQL query inside triple backticks, no explanation unless requested.

    Example:
    User: "Get all patient names from Lahore"
    Output:
    \`\`\`sql
    SELECT name FROM patients WHERE city = 'Lahore';
    \`\`\`
  `;

  const genAI = new GoogleGenerativeAI(process.env.NEXT_GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const result = await model.generateContent(
    `${SYSTEM_PROMPT}\nUser: ${query}\nSQL:`
  );

  const aiResponse = result.response.text();

  return NextResponse.json({
    success: true,
    output: aiResponse,
  });
}
