const express = require("express");
const { createNote, getNotes, deleteNote, updateNote } = require("../controllers/noteController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authMiddleware, createNote);
router.get("/", authMiddleware, getNotes);
router.delete("/:id", authMiddleware, deleteNote);
router.put("/:id", authMiddleware, updateNote);

module.exports = router;
