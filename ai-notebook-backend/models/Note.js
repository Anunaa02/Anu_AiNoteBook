const mongoose = require("mongoose");

const noteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  title:   { type: String, default: "" },
  content: { type: String, required: true },
  mood:    { type: String, default: "" },
  stickerUrl: { type: String, default: null },
  reminderAt: { type: Date, default: null },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Note", noteSchema);
