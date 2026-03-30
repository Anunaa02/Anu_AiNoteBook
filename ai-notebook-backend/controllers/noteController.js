const Note = require("../models/Note");
const OpenAI = require("openai").default;

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

exports.saveStickerToNote = async (req, res) => {
  try {
    const { stickerUrl } = req.body;
    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: req.userId },
      { stickerUrl, updatedAt: Date.now() },
      { new: true }
    );
    if (!note) return res.status(404).json({ message: "Note not found" });
    res.json({ message: "Sticker saved", note });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ✨ STICKER GENERATOR - OpenAI DALL-E API (Real Images Only)
exports.generateSticker = async (req, res) => {
  try {
    const { prompt } = req.body;
    
    if (!prompt || prompt.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Prompt required" });
    }

    const openaiApiKey = process.env.OPENAI_API_KEY;

    if (!openaiApiKey || openaiApiKey.trim().length === 0) {
      return res.status(500).json({
        success: false,
        message: "OpenAI API key is not configured in .env file",
        error: "missing_api_key"
      });
    }

    console.log(`\n🎨 Generating sticker for: "${prompt}"`);
    
    try {
      const openai = new OpenAI({ 
        apiKey: openaiApiKey,
        timeout: 60 * 1000
      });

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: `A cute, adorable sticker illustration of: ${prompt}. Cartoon style, vibrant colors, professional quality, high resolution.`,
        n: 1,
        size: "1024x1024",
        quality: "standard",
        style: "natural"
      });

      if (response.data && response.data.length > 0) {
        const imageUrl = response.data[0].url;
        console.log("✅ Sticker generated successfully with OpenAI DALL-E");
        return res.json({
          success: true,
          stickerUrl: imageUrl,
          source: "openai_dalle3"
        });
      } else {
        return res.status(500).json({
          success: false,
          message: "No image returned from OpenAI",
          error: "empty_response"
        });
      }
    } catch (apiError) {
      console.error("❌ OpenAI API Error:", apiError);
      
      const status = apiError.status || 500;
      const message = apiError.message || "OpenAI API Error";
      
      // Provide helpful hints for common errors
      let hint = "";
      if (message.includes("Billing hard limit") || message.includes("429")) {
        hint = "⏳ Rate limit or billing issue. Check: https://platform.openai.com/account/billing/limits";
      } else if (message.includes("401") || message.includes("invalid")) {
        hint = "🔑 Invalid or expired API key. Update OPENAI_API_KEY in .env";
      } else if (message.includes("quota")) {
        hint = "💳 Free trial expired or quota exceeded. Add payment method to OpenAI.";
      }
      
      res.status(status).json({
        success: false,
        message: message,
        error: apiError.type || "api_error",
        hint: hint
      });
    }

  } catch (error) {
    console.error("❌ Unexpected error:", error.message);
    res.status(500).json({
      success: false,
      message: "Server error: " + error.message,
      error: "server_error"
    });
  }
};
