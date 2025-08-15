// scripts/loadSchemaToQdrant.mjs
import fs from "fs";
import { QdrantClient } from "@qdrant/js-client-rest";
import { GoogleGenerativeAI } from "@google/generative-ai";
import "dotenv/config";

const client = new QdrantClient({
  url: process.env.NEXT_QDRANT_API_URL,
  apiKey: process.env.NEXT_QDRANT_API_KEY,
});

const genAI = new GoogleGenerativeAI(process.env.NEXT_GEMINI_API_KEY);

async function run() {
  const schema = fs.readFileSync(
    "app/dbSchemas/Wheat-Content-in-Roman-Urdu.docx",
    "utf8"
  );

  // Split into chunks for embedding
  const chunks = schema.match(/.{1,800}/gs);

  // Create collection if not exists
  await client
    .createCollection("Wheat-Content-in-Roman-Urdu", {
      vectors: { size: 768, distance: "Cosine" },
    })
    .catch(() => {});

  const embedModel = genAI.getGenerativeModel({ model: "embedding-001" });

  const points = await Promise.all(
    chunks.map(async (chunk, i) => {
      const res = await embedModel.embedContent(chunk);
      return {
        id: i,
        vector: res.embedding.values,
        payload: { text: chunk },
      };
    })
  );

  await client.upsert("Wheat-Content-in-Roman-Urdu", {
    wait: true,
    points,
  });
  console.log("✅ Schema uploaded to Qdrant!");
}

run().catch(console.error);
