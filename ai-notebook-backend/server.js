require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const path = require("path");

const authRoutes = require("./routes/auth");
const noteRoutes = require("./routes/notes");

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve sticker directory statically
app.use('/sticker', express.static(path.join(__dirname, '../sticker')));

// MongoDB
const MONGO_URI =
  process.env.MONGO_URI ||
  "mongodb+srv://erdeneanu2006_db_user:CDacNEUnBFGmWCbr@cluster0.xi7awaa.mongodb.net/";

mongoose
  .connect(MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB error:", err));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/notes", noteRoutes);

// Port
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🎨 Sticker generation available at /api/notes/generate-sticker`);
});