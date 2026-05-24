import "dotenv/config";
import { defineConfig } from "prisma/config";

const mongodbUri = process.env["MONGODB_URI"];

if (!mongodbUri) {
  throw new Error("Missing required environment variable: MONGODB_URI");
}

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    url: mongodbUri,
  },
});
