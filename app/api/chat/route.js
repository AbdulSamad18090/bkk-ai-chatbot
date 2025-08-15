// app/api/chat/route.js
import { NextResponse } from "next/server";
import { QdrantClient } from "@qdrant/js-client-rest";
import { GoogleGenerativeAI } from "@google/generative-ai";

const COLLECTION_NAME = "db_schema"; // Must match what you used in loadSchemaToQdrant.js

export async function POST(req) {
  const { query } = await req.json();

  // 1️⃣ Connect to Qdrant
  const qdrant = new QdrantClient({
    url: process.env.NEXT_QDRANT_API_URL,
    apiKey: process.env.NEXT_QDRANT_API_KEY || undefined,
  });

  // 2️⃣ Search schema chunks in Qdrant
  const searchResult = await qdrant.search(COLLECTION_NAME, {
    vector: await embedText(query),
    limit: 5,
  });

  // Extract the most relevant schema pieces
  const schemaContext = searchResult
    .map(item => item.payload?.text || "")
    .join("\n");

  // 3️⃣ Prepare system prompt for Gemini
  const SYSTEM_PROMPT = `
    You are an expert SQL query generator.
    You are given PostgreSQL database schema context below (retrieved from vector search):

    ${schemaContext}

    Your task:
    - Write a correct PostgreSQL SQL query using only the available tables and columns.
    - Do not guess table/column names that do not exist.
    - Output ONLY the SQL query inside triple backticks.
  `;

  // 4️⃣ Call Gemini
  const genAI = new GoogleGenerativeAI(process.env.NEXT_GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const result = await model.generateContent(
    `${SYSTEM_PROMPT}\nUser: ${query}\nSQL:`
  );

  const aiResponse = result.response.text();

  // 5️⃣ Return result
  return NextResponse.json({
    success: true,
    output: aiResponse,
  });
}

// Helper — uses Gemini to create embeddings
async function embedText(text) {
  const genAI = new GoogleGenerativeAI(process.env.NEXT_GEMINI_API_KEY);
  const embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" });
  const embeddingResult = await embeddingModel.embedContent(text);
  return embeddingResult.embedding.values;
}
