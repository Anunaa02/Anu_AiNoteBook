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

const fs = require("fs");
const path = require("path");

exports.saveStickerToNote = async (req, res) => {
  try {
    const { stickerUrl } = req.body;
    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: req.userId },
      { stickerUrl, updatedAt: Date.now() },
      { new: true }
    );
    if (!note) return res.status(404).json({ message: "Note not found" });      
    
    // 🔍 ТАНИЛЦУУЛГА: Үүсгэсэн стикерийг "sticker" хавтсанд автоматаар хадгалах
    let finalStickerUrl = stickerUrl;
    if (stickerUrl) {
      try {
        const response = await fetch(stickerUrl);
        const buffer = await response.arrayBuffer();
        const stickerDir = path.join(__dirname, "../../sticker");
        
        // Хавтас байхгүй бол үүсгэх
        if (!fs.existsSync(stickerDir)) {
          fs.mkdirSync(stickerDir, { recursive: true });
        }

        const fileName = `sticker_${note._id}.png`;
        fs.writeFileSync(path.join(stickerDir, fileName), Buffer.from(buffer));
        console.log(`✅ Debug: Стикерийг локал 'sticker' хавтсанд хадгаллаа: ${fileName}`);
        
        // Front-End-руу локал орчны зураг руу харуулж CORS алдаанаас сэргийлнэ
        const hostUrl = req.protocol + '://' + req.get('host');
        finalStickerUrl = `${hostUrl}/sticker/${fileName}`;
        note.stickerUrl = finalStickerUrl;
        await note.save();
      } catch (dlError) {
        console.error(`❌ Debug: Стикерийг татаж хадгалахад алдаа гарлаа:`, dlError.message);
      }
    }

    res.json({ message: "Sticker saved", note: { ...note.toObject(), stickerUrl: finalStickerUrl } });
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
        prompt: `A single cute minimal cartoon icon visually representing this idea: "${prompt.substring(0, 100)}". Beautiful flat vector sticker design, thick white border outline around the shape, 100% solid white background. NO TEXT, no writing, no words, no letters, purely visual symbol.`,
        n: 1,
        size: "1024x1024",
        quality: "standard",
        style: "natural"
      });

      if (response.data && response.data.length > 0) {
        const imageUrl = response.data[0].url;
        console.log("✅ Sticker generated successfully with OpenAI DALL-E");
        
        try {
          const fs = require("fs");
          const path = require("path");
          
          const imageResponse = await fetch(imageUrl);
          if (!imageResponse.ok) {
            throw new Error(`Failed to download image: ${imageResponse.statusText}`);
          }

          const imageBuffer = await imageResponse.arrayBuffer();
          const stickerDir = path.join(__dirname, "../../sticker");

          // Хавтас байхгүй бол үүсгэх
          if (!fs.existsSync(stickerDir)) {
            fs.mkdirSync(stickerDir, { recursive: true });
          }

          // Timestamp-ээр нэрлэж, локал хавтсанд хадгалах
          const fileName = `sticker_${Date.now()}.png`;
          const filePath = path.join(stickerDir, fileName);
          fs.writeFileSync(filePath, Buffer.from(imageBuffer));

          console.log(`✅ Стикерийг локал хавтсанд хадгаллаа: ${fileName}`);

          // Локал URL-г буцаах
          const localStickerUrl = `${req.protocol}://${req.get('host')}/sticker/${fileName}`;

          return res.json({
            success: true,
            stickerUrl: localStickerUrl,
            source: "openai_dalle3"
          });
        } catch (downloadError) {
          console.error("❌ Зургийг татаж хадгалахад алдаа гарлаа:", downloadError.message);
          return res.json({
            success: true,
            stickerUrl: imageUrl,
            source: "openai_dalle3"
          });
        }
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

exports.saveStickerToLocalFile = async (req, res) => {
  try {
    const fs = require("fs");
    const path = require("path");
    
    const { imageBase64 } = req.body;
    if (!imageBase64) {
      return res.status(400).json({ success: false, message: "No imageBase64 provided" });
    }

    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, "");
    const buffer = Buffer.from(base64Data, 'base64');
    
    const stickerDir = path.join(__dirname, "../../sticker");
    if (!fs.existsSync(stickerDir)) {
      fs.mkdirSync(stickerDir, { recursive: true });
    }
    
    const fileName = `sticker_${Date.now()}.png`;
    const filePath = path.join(stickerDir, fileName);
    
    fs.writeFileSync(filePath, buffer);
    
    const stickerUrl = `${req.protocol}://${req.get('host')}/sticker/${fileName}`;
    res.json({
      success: true,
      stickerUrl,
      fileName
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

