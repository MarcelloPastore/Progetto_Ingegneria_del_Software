import mongoose from 'mongoose';
import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export async function connectDB() {
    const uri = process.env.MONGODB_URI;
    if (!uri) throw new Error("MONGODB_URI non definita nelle variabili d'ambiente");

    await mongoose.connect(uri);
    console.log("Connesso a MongoDB");
}
