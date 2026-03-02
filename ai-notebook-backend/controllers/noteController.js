const Note = require("../models/Note");

exports.createNote = async (req, res) => {
  try {
    const { title, content, mood, reminderAt } = req.body;
    const userId = req.userId;

    const note = new Note({
      userId,
      title: title || "",
      content,
      mood: mood || "",
      reminderAt: reminderAt || null,
    });

    await note.save();

    res.status(201).json({
      message: "Note created successfully",
      note
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getNotes = async (req, res) => {
  try {
    const userId = req.userId;
    const notes = await Note.find({ userId }).sort({ createdAt: -1 });

    res.json({
      message: "Notes retrieved successfully",
      notes
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteNote = async (req, res) => {
  try {
    const note = await Note.findOneAndDelete({ _id: req.params.id, userId: req.userId });
    if (!note) return res.status(404).json({ message: "Note not found" });
    res.json({ message: "Note deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateNote = async (req, res) => {
  try {
    const { title, content, mood } = req.body;
    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: req.userId },
      { title, content, mood, updatedAt: Date.now() },
      { new: true }
    );
    if (!note) return res.status(404).json({ message: "Note not found" });
    res.json({ message: "Note updated", note });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
