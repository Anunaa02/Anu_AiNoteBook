const express = require("express");
const { createNote, getNotes, deleteNote, updateNote, saveStickerToNote, generateSticker } = require("../controllers/noteController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// ✨ AI Sticker generator route (must be before /:id routes)
router.post("/generate-sticker", authMiddleware, generateSticker);

// Standard CRUD routes
router.post("/", authMiddleware, createNote);
router.get("/", authMiddleware, getNotes);
router.delete("/:id", authMiddleware, deleteNote);
router.put("/:id", authMiddleware, updateNote);
router.patch("/:id/sticker", authMiddleware, saveStickerToNote);

module.exports = router;
