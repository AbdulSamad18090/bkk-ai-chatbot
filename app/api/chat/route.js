// app/api/chat/route.js
import { NextResponse } from "next/server";
import { QdrantClient } from "@qdrant/js-client-rest";
import { GoogleGenerativeAI } from "@google/generative-ai";

// Separate schema collections and documentation collections
const SCHEMA_COLLECTIONS = [
  "agri_bank_tenant_global_updated",
  "bkk_v2_live_tenant_global_updated",
];
const DOC_COLLECTIONS = ["Wheat-Content-in-Roman-Urdu"];

export async function POST(req) {
  const { query } = await req.json();

  const qdrant = new QdrantClient({
    url: process.env.NEXT_QDRANT_API_URL,
    apiKey: process.env.NEXT_QDRANT_API_KEY || undefined,
  });

  const queryVector = await embedText(query);

  // Fetch schema results
  let schemaResults = [];
  for (const collection of SCHEMA_COLLECTIONS) {
    try {
      const res = await qdrant.search(collection, {
        vector: queryVector,
        limit: 15, // prioritizing schema details
      });
      schemaResults.push(
        ...res.map((item) => ({
          text: item.payload?.text || "",
          score: item.score || 0,
          collection,
        }))
      );
    } catch (err) {
      console.error(`Error searching schema collection ${collection}:`, err);
    }
  }

  // Fetch documentation results
  let docResults = [];
  for (const collection of DOC_COLLECTIONS) {
    try {
      const res = await qdrant.search(collection, {
        vector: queryVector,
        limit: 5, // smaller limit for docs to avoid diluting schema
      });
      docResults.push(
        ...res.map((item) => ({
          text: item.payload?.text || "",
          score: item.score || 0,
          collection,
        }))
      );
    } catch (err) {
      console.error(`Error searching doc collection ${collection}:`, err);
    }
  }

  // Sort and slice best results from each group
  schemaResults = schemaResults.sort((a, b) => b.score - a.score).slice(0, 10);
  docResults = docResults.sort((a, b) => b.score - a.score).slice(0, 5);

  // Build contexts separately
  const schemaContext = schemaResults
    .map(
      (r) => `-- From ${r.collection} (score: ${r.score.toFixed(3)})\n${r.text}`
    )
    .join("\n\n");

  const docContext = docResults
    .map(
      (r) =>
        `-- From Documentation (${r.collection}, score: ${r.score.toFixed(
          3
        )})\n${r.text}`
    )
    .join("\n\n");

  console.log(`Schema context for query "${query}":\n${schemaContext}\n`);
  console.log(`Documentation context for query "${query}":\n${docContext}\n`);

  // Prompt
  const SYSTEM_PROMPT = `
    You are an expert SQL query generator.
    You are given PostgreSQL database schema context below (retrieved from vector search):

    Schema Context:
    ${schemaContext}

    ADDITIONAL DOCUMENTATION:
    ${docContext}

    Your task:
    - Write a correct PostgreSQL SQL query using only the available tables and columns.
    - Do not guess table/column names that do not exist.
    - Output ONLY the SQL query inside triple backticks.
  `;

  // Call Gemini
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

// Helper for embeddings
async function embedText(text) {
  const genAI = new GoogleGenerativeAI(process.env.NEXT_GEMINI_API_KEY);
  const embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" });
  const embeddingResult = await embeddingModel.embedContent(text);
  return embeddingResult.embedding.values;
}
