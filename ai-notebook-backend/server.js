const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const authRoutes = require("./routes/auth");
const noteRoutes = require("./routes/notes");

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect("mongodb+srv://erdeneanu2006_db_user:CDacNEUnBFGmWCbr@cluster0.xi7awaa.mongodb.net/")
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.log(err));

app.use("/api/auth", authRoutes);
app.use("/api/notes", noteRoutes);

app.listen(5000, () => console.log("Server running on port 5000"));