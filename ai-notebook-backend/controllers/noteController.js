const Note = require("../models/Note");
const OpenAI = require("openai").default;

const FALLBACK_STYLES = [
  "adventurer-neutral",
  "avataaars-neutral",
  "bottts-neutral",
  "personas"
];
const FAST_CACHE_TTL_MS = 1000 * 60 * 10;
const stickerUrlCache = new Map();
const activityKeywords = {
  meeting: ["meeting", "office", "team", "work", "business"],
  hangout: ["hang out", "hangout", "friends", "friend", "cafe", "chat"],
  exercise: ["exercise", "workout", "gym", "yoga", "run", "fitness"],
  water: ["water", "drink", "hydration", "bottle"],
  homework: ["homework", "study", "assignment", "learn", "school"]
};

const stringHash = (value) => {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = ((hash << 5) - hash) + value.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
};

const pickFallbackStyle = (prompt) => {
  const normalized = (prompt || "sticker").toLowerCase();
  if (normalized.includes("cat") || normalized.includes("dog") || normalized.includes("animal")) {
    return "personas";
  }

  const idx = stringHash(normalized) % FALLBACK_STYLES.length;
  return FALLBACK_STYLES[idx];
};

const detectActivityType = (prompt) => {
  const value = (prompt || "").toLowerCase();
  for (const [type, keywords] of Object.entries(activityKeywords)) {
    if (keywords.some((keyword) => value.includes(keyword))) {
      return type;
    }
  }
  return "generic";
};

const detectActivityScene = (prompt) => {
  const value = (prompt || "").toLowerCase();
  if (value.includes("meeting") || value.includes("office") || value.includes("team")) {
    return "four adorable cartoon puppies in an office meeting around a round wooden table, one with a blue book, one with headphones, one holding papers, one with a coffee mug";
  }
  if (value.includes("water") || value.includes("plant") || value.includes("garden")) {
    return "cute character watering indoor plants with a small watering can and flower pots";
  }
  if (value.includes("exercise") || value.includes("workout") || value.includes("gym") || value.includes("yoga")) {
    return "cute character doing workout and stretching with dumbbells or yoga mat";
  }
  if (value.includes("hang out") || value.includes("hangout") || value.includes("friends") || value.includes("cafe")) {
    return "cute friends hanging out, chatting and laughing at a cafe table";
  }
  return "cute characters doing positive daily activities in a playful scene";
};

const buildDesignedStickerPrompt = (prompt) => {
  const userTheme = (prompt || "people doing positive daily activities").trim();
  const isMeeting = detectActivityType(userTheme) === "meeting";
  const activityScene = detectActivityScene(userTheme);
  const basePrompt = [
    "kawaii sticker illustration",
    "flat 2d cartoon style",
    "adorable characters with expressive faces",
    activityScene,
    "single cohesive sticker scene",
    "bold clean outlines with thick white die-cut border",
    "pastel vibrant colors",
    "soft simple shading",
    "minimal plain background",
    "no watermark",
    "no logo",
    "no emoji",
    "no icon-only symbols",
    "not realistic",
    "theme: " + userTheme
  ];

  if (isMeeting) {
    basePrompt.push("large heading text exactly: Meeting!");
    basePrompt.push("small speech bubble text: Hi!");
    basePrompt.push("round wooden table with laptop, papers and two coffee cups");
  } else {
    basePrompt.push("large playful heading text relevant to the activity");
  }

  return basePrompt.join(", ");
};

const buildAnimatedStickerPrompt = (prompt) => {
  const userTheme = (prompt || "cute daily activity").trim();
  return [
    "animated sticker illustration",
    " cartoon style",
    "cute expressive character",
    "single sticker composition",
    "thick clean white die-cut border",
    "vibrant colors",
    "soft shading",
    "minimal clean background",
    "no watermark",
    "no logo",
    "theme: " + userTheme
  ].join(", ");
};

const createFallbackStickerUrl = (prompt) => {
  const cleanPrompt = (prompt || "cute meeting sticker").trim().slice(0, 120);
  const styledPrompt = buildDesignedStickerPrompt(cleanPrompt);
  const seed = stringHash(cleanPrompt || "sticker");
  return `https://image.pollinations.ai/prompt/${encodeURIComponent(styledPrompt)}?model=flux&width=768&height=768&seed=${seed}&enhance=true&nologo=true&safe=true`;
};

const createFallbackStickerUrlAlt = (prompt) => {
  const cleanPrompt = (prompt || "cute meeting sticker").trim().slice(0, 120);
  const activityScene = detectActivityScene(cleanPrompt);
  const altPrompt = [
    "premium sticker illustration",
    "kawaii flat vector",
    "cute characters",
    activityScene,
    "thick white cutout border",
    "pastel colorful palette",
    "simple clean background",
    detectActivityType(cleanPrompt) === "meeting" ? "heading text Meeting! and small speech bubble Hi!" : "playful heading text",
    "no emoji",
    "no icon-only symbols",
    "no watermark",
    "theme: " + cleanPrompt
  ].join(", ");
  const seed = stringHash(`alt-${cleanPrompt}`);
  return `https://image.pollinations.ai/prompt/${encodeURIComponent(altPrompt)}?model=flux&width=768&height=768&seed=${seed}&enhance=true&nologo=true&safe=true`;
};

const createSafeFallbackPngUrl = (prompt) => {
  const cleanPrompt = (prompt || "sticker").trim().slice(0, 120);
  const safeSeed = encodeURIComponent(cleanPrompt || "sticker");
  const style = pickFallbackStyle(cleanPrompt);
  return `https://api.dicebear.com/9.x/${style}/png?seed=${safeSeed}&size=512&backgroundType=gradientLinear&backgroundColor=b6e3f4,c0aede,d1d4f9,fde68a,ffdfbf&radius=24`;
};

const createLocalStyledStickerDataUri = (prompt) => {
  const activityType = detectActivityType(prompt);
  const titleMap = {
    meeting: "Meeting!",
    hangout: "Hang Out!",
    exercise: "Exercise!",
    water: "Drink Water!",
    homework: "Homework!",
    generic: "Daily Task!"
  };
  const title = titleMap[activityType] || titleMap.generic;

  const sceneMap = {
    meeting: `
      <ellipse cx="256" cy="300" rx="150" ry="72" fill="#f59e0b" opacity="0.35"/>
      <rect x="210" y="250" width="92" height="56" rx="10" fill="#dbeafe" stroke="#64748b" stroke-width="4"/>
      <circle cx="148" cy="210" r="34" fill="#fb923c"/><rect x="116" y="240" width="64" height="54" rx="22" fill="#60a5fa"/>
      <circle cx="256" cy="206" r="34" fill="#fde68a"/><rect x="224" y="238" width="64" height="58" rx="22" fill="#34d399"/>
      <circle cx="364" cy="210" r="34" fill="#fca5a5"/><rect x="332" y="240" width="64" height="54" rx="22" fill="#a78bfa"/>
      <rect x="182" y="178" width="80" height="40" rx="16" fill="#fef3c7"/><text x="222" y="204" text-anchor="middle" font-size="24" font-family="Arial" fill="#92400e">Hi!</text>
    `,
    hangout: `
      <circle cx="190" cy="220" r="34" fill="#f59e0b"/><rect x="158" y="250" width="64" height="70" rx="22" fill="#60a5fa"/>
      <circle cx="322" cy="220" r="34" fill="#fb7185"/><rect x="290" y="250" width="64" height="70" rx="22" fill="#34d399"/>
      <rect x="170" y="314" width="172" height="20" rx="10" fill="#334155"/>
    `,
    exercise: `
      <circle cx="256" cy="200" r="34" fill="#f59e0b"/><rect x="224" y="234" width="64" height="86" rx="22" fill="#22d3ee"/>
      <rect x="170" y="258" width="44" height="14" rx="7" fill="#111827"/><rect x="298" y="258" width="44" height="14" rx="7" fill="#111827"/>
      <rect x="152" y="252" width="14" height="26" rx="6" fill="#334155"/><rect x="346" y="252" width="14" height="26" rx="6" fill="#334155"/>
    `,
    water: `
      <rect x="194" y="140" width="124" height="210" rx="24" fill="#e2e8f0"/>
      <rect x="206" y="172" width="100" height="150" rx="16" fill="#93c5fd"/>
      <rect x="226" y="118" width="60" height="28" rx="9" fill="#cbd5e1"/>
      <path d="M256 212c18 28 30 44 30 62a30 30 0 1 1-60 0c0-18 12-34 30-62Z" fill="#2563eb"/>
    `,
    homework: `
      <rect x="148" y="228" width="216" height="120" rx="18" fill="#334155"/>
      <rect x="164" y="244" width="184" height="84" rx="10" fill="#c7d2fe"/>
      <rect x="236" y="170" width="40" height="60" rx="12" fill="#f59e0b"/>
      <line x1="198" y1="268" x2="314" y2="268" stroke="#475569" stroke-width="5"/>
      <line x1="198" y1="286" x2="288" y2="286" stroke="#475569" stroke-width="5"/>
    `,
    generic: `
      <circle cx="256" cy="214" r="38" fill="#f59e0b"/><rect x="220" y="248" width="72" height="86" rx="24" fill="#38bdf8"/>
    `
  };

  const scene = sceneMap[activityType] || sceneMap.generic;
  const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="768" height="768" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#f8fafc"/>
      <stop offset="100%" stop-color="#e2e8f0"/>
    </linearGradient>
  </defs>
  <rect x="12" y="12" width="488" height="488" rx="72" fill="#ffffff"/>
  <rect x="28" y="28" width="456" height="456" rx="56" fill="url(#bg)"/>
  <text x="256" y="116" text-anchor="middle" font-size="60" font-family="Arial, sans-serif" font-weight="700" fill="#1d4ed8">${title}</text>
  ${scene}
  <circle cx="98" cy="126" r="7" fill="#f59e0b"/><circle cx="420" cy="146" r="8" fill="#fb7185"/><circle cx="96" cy="404" r="8" fill="#22d3ee"/>
</svg>`;

  return `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
};

const fetchImageAsDataUri = async (imageUrl, timeoutMs = 15000) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetch(imageUrl, { method: "GET", signal: controller.signal });
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    throw new Error(`Image fetch failed with status ${response.status}`);
  }

  const contentType = (response.headers.get("content-type") || "").toLowerCase();
  if (!contentType.startsWith("image/")) {
    throw new Error("Image fetch returned non-image content");
  }

  const arrayBuffer = await response.arrayBuffer();
  const base64 = Buffer.from(arrayBuffer).toString("base64");
  const mimeType = contentType.split(";")[0] || "image/png";
  return `data:${mimeType};base64,${base64}`;
};

const getFastFallbackStickerPayload = async (prompt) => {
  const useDesignedFallback = String(process.env.USE_DESIGNED_FALLBACK || "true").toLowerCase() === "true";
  const allowSafeAvatarFallback = String(process.env.ALLOW_SAFE_AVATAR_FALLBACK || "false").toLowerCase() === "true";
  const allowLocalStyledFallback = String(process.env.ALLOW_LOCAL_STYLED_FALLBACK || "true").toLowerCase() === "true";
  const modeKey = useDesignedFallback ? "designed" : "safe";
  const key = `${modeKey}::${(prompt || "sticker").trim().toLowerCase()}`;
  const now = Date.now();
  const cached = stickerUrlCache.get(key);

  if (cached && (now - cached.ts) < FAST_CACHE_TTL_MS) {
    return { stickerUrl: cached.url, source: cached.source };
  }

  if (useDesignedFallback) {
    try {
      const primaryDataUri = await fetchImageAsDataUri(createFallbackStickerUrl(prompt), 25000);
      stickerUrlCache.set(key, { url: primaryDataUri, source: "fallback_activity_pack_fast", ts: now });
      return { stickerUrl: primaryDataUri, source: "fallback_activity_pack_fast" };
    } catch (firstDesignedError) {
      try {
        const secondaryDataUri = await fetchImageAsDataUri(createFallbackStickerUrlAlt(prompt), 15000);
        stickerUrlCache.set(key, { url: secondaryDataUri, source: "fallback_activity_pack_fast", ts: now });
        return { stickerUrl: secondaryDataUri, source: "fallback_activity_pack_fast" };
      } catch (secondDesignedError) {
        // Fall through to guaranteed safe fallback.
      }
    }
  }

  if (allowSafeAvatarFallback) {
    const safeDataUri = await fetchImageAsDataUri(createSafeFallbackPngUrl(prompt), 6000);
    stickerUrlCache.set(key, { url: safeDataUri, source: "fallback_dicebear_fast", ts: now });
    return { stickerUrl: safeDataUri, source: "fallback_dicebear_fast" };
  }

  if (allowLocalStyledFallback) {
    const localDataUri = createLocalStyledStickerDataUri(prompt);
    stickerUrlCache.set(key, { url: localDataUri, source: "fallback_local_styled", ts: now });
    return { stickerUrl: localDataUri, source: "fallback_local_styled" };
  }

  // Guaranteed final fallback so sticker generation never hard-fails in free mode.
  const localDataUri = createLocalStyledStickerDataUri(prompt);
  stickerUrlCache.set(key, { url: localDataUri, source: "fallback_local_styled", ts: now });
  return { stickerUrl: localDataUri, source: "fallback_local_styled" };
};

const GEMINI_DEFAULT_MODEL_CANDIDATES = [
  "gemini-2.5-flash-image-preview",
  "gemini-2.0-flash-preview-image-generation",
  "gemini-2.5-flash",
  "gemini-2.0-flash",
  "gemini-2.0-flash-001"
];

const parseGeminiModelCandidates = () => {
  const preferred = String(process.env.GEMINI_IMAGE_MODEL || "").trim();
  const fromEnv = String(process.env.GEMINI_IMAGE_MODEL_CANDIDATES || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  const set = new Set();
  if (preferred) set.add(preferred);
  for (const model of fromEnv) set.add(model);
  for (const model of GEMINI_DEFAULT_MODEL_CANDIDATES) set.add(model);
  return Array.from(set);
};

const extractGeminiInlineImage = (geminiBody) => {
  const candidates = Array.isArray(geminiBody?.candidates) ? geminiBody.candidates : [];
  for (const candidate of candidates) {
    const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
    for (const part of parts) {
      const inlineData = part?.inlineData || part?.inline_data;
      if (inlineData?.data) {
        return {
          mimeType: inlineData?.mimeType || inlineData?.mime_type || "image/png",
          data: inlineData.data
        };
      }
    }
  }
  return null;
};

const generateGeminiImageDataUri = async ({ apiKey, prompt }) => {
  const modelCandidates = parseGeminiModelCandidates();
  const requestVariants = [
    { version: "v1beta", responseModalities: ["TEXT", "IMAGE"] },
    { version: "v1", responseModalities: ["TEXT", "IMAGE"] },
    { version: "v1beta", responseModalities: ["IMAGE"] },
    { version: "v1", responseModalities: ["IMAGE"] }
  ];

  const attempts = [];

  for (const model of modelCandidates) {
    for (const variant of requestVariants) {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 25000);

      const requestBody = {
        contents: [{
          role: "user",
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          responseModalities: variant.responseModalities
        }
      };

      let response;
      let body = null;
      try {
        response = await fetch(
          `https://generativelanguage.googleapis.com/${variant.version}/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`,
          {
            method: "POST",
            signal: controller.signal,
            headers: {
              "Content-Type": "application/json"
            },
            body: JSON.stringify(requestBody)
          }
        );

        try {
          body = await response.json();
        } catch (_) {
          body = null;
        }
      } finally {
        clearTimeout(timeoutId);
      }

      const message = body?.error?.message || body?.message || "Gemini request failed";
      if (!response?.ok) {
        const reason = String(body?.error?.details?.[0]?.reason || "").toUpperCase();
        attempts.push(`${model}@${variant.version}:${response?.status || 0}`);

        // Key/account problems should fail fast with clear message.
        if (reason.includes("API_KEY") || /API key expired|API_KEY_INVALID|invalid api key/i.test(message)) {
          const error = new Error(`Gemini API key invalid or expired: ${message}`);
          error.status = response?.status || 400;
          error.type = "gemini_key_invalid";
          throw error;
        }

        if (/quota|RESOURCE_EXHAUSTED|rate limit|Too Many Requests/i.test(message) || response?.status === 429) {
          const error = new Error(`Gemini quota/rate limit: ${message}`);
          error.status = response?.status || 429;
          error.type = "gemini_quota";
          throw error;
        }

        continue;
      }

      const inlineImage = extractGeminiInlineImage(body);
      if (!inlineImage?.data) {
        attempts.push(`${model}@${variant.version}:no-image`);
        continue;
      }

      return {
        model,
        dataUri: `data:${inlineImage.mimeType};base64,${inlineImage.data}`
      };
    }
  }

  const tried = attempts.slice(0, 8).join(", ");
  const error = new Error(`No Gemini image response from tried variants (${tried || "none"})`);
  error.status = 502;
  error.type = "gemini_no_image";
  throw error;
};

exports.createNote = async (req, res) => {
  try {
    const { title, content, mood, reminderAt, noteDate } = req.body;
    const userId = req.userId;

    const note = new Note({
      userId,
      title: title || "",
      content,
      mood: mood || "",
      reminderAt: reminderAt || null,
      noteDate: noteDate || null,
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
    const { title, content, mood, reminderAt, noteDate } = req.body;
    const updatePayload = {
      title,
      content,
      mood,
      updatedAt: Date.now()
    };

    if (Object.prototype.hasOwnProperty.call(req.body, "reminderAt")) {
      updatePayload.reminderAt = reminderAt || null;
    }

    if (Object.prototype.hasOwnProperty.call(req.body, "noteDate")) {
      updatePayload.noteDate = noteDate || null;
    }

    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: req.userId },
      updatePayload,
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

const parseImageDataUri = (value) => {
  const match = String(value || "").match(/^data:([^;,]+);base64,(.+)$/i);
  if (!match) return null;
  return {
    mimeType: String(match[1] || "image/png").toLowerCase(),
    base64Payload: match[2]
  };
};

const imageMimeToExt = (mimeType) => {
  const cleanMime = String(mimeType || "").toLowerCase();
  if (cleanMime === "image/svg+xml") return "svg";
  if (cleanMime === "image/jpeg") return "jpg";
  if (cleanMime === "image/webp") return "webp";
  if (cleanMime === "image/gif") return "gif";
  return "png";
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
    
    // 🔍 ТАНИЛЦУУЛГА: Үүсгэсэн стикерийг "sticker" хавтсанд автоматаар хадгалах
    let finalStickerUrl = stickerUrl;
    if (stickerUrl) {
      try {
        const stickerDir = path.join(__dirname, "../../sticker");

        // Хавтас байхгүй бол үүсгэх
        if (!fs.existsSync(stickerDir)) {
          fs.mkdirSync(stickerDir, { recursive: true });
        }

        let mimeType = "image/png";
        let binaryBuffer;

        const parsedDataUri = parseImageDataUri(stickerUrl);
        if (parsedDataUri) {
          mimeType = parsedDataUri.mimeType;
          binaryBuffer = Buffer.from(parsedDataUri.base64Payload, "base64");
        } else {
          const response = await fetch(stickerUrl);
          if (!response.ok) {
            throw new Error(`Sticker download failed with status ${response.status}`);
          }

          const contentType = (response.headers.get("content-type") || "").toLowerCase();
          if (!contentType.startsWith("image/")) {
            throw new Error("Sticker URL returned non-image content");
          }

          mimeType = contentType.split(";")[0] || "image/png";
          const buffer = await response.arrayBuffer();
          binaryBuffer = Buffer.from(buffer);
        }

        const extension = imageMimeToExt(mimeType);
        const fileName = `sticker_${note._id}.${extension}`;
        fs.writeFileSync(path.join(stickerDir, fileName), binaryBuffer);
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

// ✨ STICKER GENERATOR - OpenAI / OpenRouter Image API
exports.generateSticker = async (req, res) => {
  try {
    const stickerGenerationDisabled = String(process.env.DISABLE_STICKER_GENERATION || "false").toLowerCase() === "true";
    if (stickerGenerationDisabled) {
      return res.status(503).json({
        success: false,
        message: "Sticker generation is currently disabled.",
        error: "sticker_generation_disabled"
      });
    }

    const { prompt } = req.body;
    const normalizedPrompt = String(prompt || "").trim();

    if (!normalizedPrompt) {
      return res.status(400).json({ success: false, message: "Prompt required" });
    }

    const openaiApiKey = process.env.OPENAI_API_KEY;
    const openrouterApiKey = process.env.OPENROUTER_API_KEY;
    const geminiApiKey = process.env.GEMINI_API_KEY;

    const hasNativeOpenAIKey = Boolean(openaiApiKey) &&
      !(typeof openaiApiKey === "string" && openaiApiKey.startsWith("sk-or-"));
    const hasOpenRouterKey = Boolean(openrouterApiKey) ||
      (typeof openaiApiKey === "string" && openaiApiKey.startsWith("sk-or-"));
    const hasGeminiKey = Boolean(geminiApiKey);
    const openRouterOnly = String(process.env.OPENROUTER_ONLY || "false").toLowerCase() === "true";
    const googleOnly = String(process.env.GOOGLE_ONLY || "false").toLowerCase() === "true";

    if (openRouterOnly && !hasOpenRouterKey) {
      const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
      return res.json({
        success: true,
        stickerUrl: fallbackPayload.stickerUrl,
        source: fallbackPayload.source,
        warning: "OPENROUTER_ONLY=true but key is missing, free fallback sticker used"
      });
    }

    if (googleOnly && !hasGeminiKey) {
      const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
      return res.json({
        success: true,
        stickerUrl: fallbackPayload.stickerUrl,
        source: fallbackPayload.source,
        warning: "GOOGLE_ONLY=true but GEMINI_API_KEY is missing, free fallback sticker used"
      });
    }

    const useOpenRouter = openRouterOnly || (hasOpenRouterKey && !hasNativeOpenAIKey);
    const useGeminiDirect = (googleOnly && hasGeminiKey) || (!useOpenRouter && !hasNativeOpenAIKey && hasGeminiKey);

    const apiKeyToUse = useGeminiDirect
      ? geminiApiKey
      : (useOpenRouter ? (openrouterApiKey || openaiApiKey) : openaiApiKey);

    console.log(`\n🎨 Generating sticker for: "${normalizedPrompt}"`);

    const forceFallback = !openRouterOnly && String(process.env.USE_FALLBACK_MODE || "false").toLowerCase() === "true";
    const preferActivityFallback = !openRouterOnly && String(process.env.PREFER_ACTIVITY_FALLBACK || "false").toLowerCase() === "true";
    const useApiOnly = String(process.env.USE_API_ONLY || "true").toLowerCase() === "true";
    const fallbackOnApiError = String(process.env.FALLBACK_ON_API_ERROR || "true").toLowerCase() === "true";
    const activityType = detectActivityType(normalizedPrompt);
    if (forceFallback) {
      const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
      return res.json({
        success: true,
        stickerUrl: fallbackPayload.stickerUrl,
        source: fallbackPayload.source
      });
    }

    if (!apiKeyToUse || apiKeyToUse.trim().length === 0) {
      const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
      return res.json({
        success: true,
        stickerUrl: fallbackPayload.stickerUrl,
        source: fallbackPayload.source,
        warning: "Image API key missing, free fallback sticker used"
      });
    }

    if (!useApiOnly && preferActivityFallback && activityType !== "generic") {
      const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
      return res.json({
        success: true,
        stickerUrl: fallbackPayload.stickerUrl,
        source: fallbackPayload.source
      });
    }
    
    try {
      const model = useOpenRouter
          ? (process.env.OPENROUTER_IMAGE_MODEL || "openai/gpt-image-1")
          : (process.env.OPENAI_IMAGE_MODEL || "gpt-image-1");
        const stickerPrompt = buildAnimatedStickerPrompt(normalizedPrompt);

      let response;
      let usedGeminiModel = null;

      if (useGeminiDirect) {
        const geminiImage = await generateGeminiImageDataUri({
          apiKey: apiKeyToUse,
          prompt: stickerPrompt
        });
        usedGeminiModel = geminiImage.model;

        response = {
          data: [{
            url: geminiImage.dataUri || null
          }]
        };
      } else if (useOpenRouter) {
        const openRouterController = new AbortController();
        const openRouterTimeoutId = setTimeout(() => openRouterController.abort(), 20000);
        const openRouterResponse = await fetch("https://openrouter.ai/api/v1/responses", {
          method: "POST",
          signal: openRouterController.signal,
          headers: {
            "Authorization": `Bearer ${apiKeyToUse}`,
            "Content-Type": "application/json",
            "HTTP-Referer": process.env.OPENROUTER_SITE_URL || "http://localhost:3000",
            "X-Title": process.env.OPENROUTER_APP_NAME || "AI Notebook Backend"
          },
          body: JSON.stringify({
            model,
            input: stickerPrompt,
            modalities: ["image"],
            max_output_tokens: 256
          })
        });
        clearTimeout(openRouterTimeoutId);

        const contentType = (openRouterResponse.headers.get("content-type") || "").toLowerCase();
        let parsedBody = null;
        let rawBody = "";

        if (contentType.includes("application/json")) {
          parsedBody = await openRouterResponse.json();
        } else {
          rawBody = await openRouterResponse.text();
        }

        if (!openRouterResponse.ok) {
          const serverMessage = parsedBody?.error?.message || parsedBody?.message;
          const fallbackMessage = rawBody.includes("<html")
            ? "OpenRouter returned an HTML error page. Check image endpoint/model support."
            : (rawBody || "OpenRouter request failed");
          const error = new Error(serverMessage || fallbackMessage);
          error.status = openRouterResponse.status;
          error.type = "openrouter_error";
          throw error;
        }

        const imageResult = Array.isArray(parsedBody?.output)
          ? parsedBody.output.find((item) => item?.type === "image_generation_call" && item?.result)?.result
          : null;

        response = {
          data: [{
            url: imageResult || null
          }]
        };
      } else {
        const openai = new OpenAI({
          apiKey: apiKeyToUse,
          timeout: 60 * 1000
        });

        response = await openai.images.generate({
          model,
          prompt: stickerPrompt,
          size: "1024x1024"
        });
      }

      if (response?.data && response.data.length > 0 && response.data[0]?.url) {
        const imageUrl = response.data[0].url;
        console.log(useGeminiDirect
          ? "✅ Sticker generated successfully with Google Gemini"
          : (useOpenRouter
            ? "✅ Sticker generated successfully with OpenRouter"
            : "✅ Sticker generated successfully with OpenAI DALL-E"));
        const payload = {
          success: true,
          stickerUrl: imageUrl,
          source: useGeminiDirect ? "google_gemini" : (useOpenRouter ? "openrouter" : "openai_dalle3")
        };
        if (useGeminiDirect && usedGeminiModel) {
          payload.model = usedGeminiModel;
        }
        return res.json(payload);
      }

      if (fallbackOnApiError) {
        const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
        return res.json({
          success: true,
          stickerUrl: fallbackPayload.stickerUrl,
          source: fallbackPayload.source,
          warning: "Image API returned empty payload, free fallback sticker used"
        });
      }

      return res.status(500).json({
        success: false,
        message: "No image returned from image API",
        error: "empty_response"
      });
    } catch (apiError) {
      const status = apiError.status || 500;
      const rawMessage = apiError.message || "OpenAI API Error";
      const message = rawMessage.includes("<html")
        ? "Image API returned an HTML error page"
        : rawMessage.slice(0, 300);

      if (fallbackOnApiError) {
        const fallbackPayload = await getFastFallbackStickerPayload(normalizedPrompt);
        return res.json({
          success: true,
          stickerUrl: fallbackPayload.stickerUrl,
          source: fallbackPayload.source,
          warning: `Image API failed (${status}), free fallback sticker used`
        });
      }

      console.error("Image API Error:", apiError);
      
      // Provide helpful hints for common errors
      let hint = "";
      if (apiError.type === "gemini_no_image") {
        hint = "No image-capable Gemini model responded. Set GEMINI_IMAGE_MODEL or GEMINI_IMAGE_MODEL_CANDIDATES in .env.";
      } else if (apiError.type === "gemini_key_invalid") {
        hint = "GEMINI_API_KEY invalid/expired. Create a new key in Google AI Studio and retry.";
      } else if (apiError.type === "gemini_quota") {
        hint = "Gemini key has no available quota. Enable billing or wait/reset quota.";
      } else if (message.includes("Billing hard limit") || message.includes("429")) {
        hint = useGeminiDirect
          ? "Rate limit or quota issue on Google Gemini API key."
          : (useOpenRouter
          ? "Rate limit or credits issue. Check your OpenRouter usage and credits."
          : "Rate limit or billing issue. Check: https://platform.openai.com/account/billing/limits");
      } else if (message.includes("401") || message.includes("invalid")) {
        hint = useGeminiDirect
          ? "Invalid or expired GEMINI_API_KEY."
          : (useOpenRouter
          ? "Invalid or expired API key. Update OPENROUTER_API_KEY in .env"
          : "Invalid or expired API key. Update OPENAI_API_KEY in .env");
      } else if (message.includes("quota")) {
        hint = useGeminiDirect
          ? "Gemini API quota exceeded."
          : (useOpenRouter
          ? "Quota exceeded. Add credits in your OpenRouter account."
          : "Free trial expired or quota exceeded. Add payment method to OpenAI.");
      }
      
      res.status(status).json({
        success: false,
        message: message,
        error: apiError.type || "api_error",
        hint: hint
      });
    }

  } catch (error) {
    if (typeof error.message === "string" && error.message.includes("AI sticker services are temporarily unavailable")) {
      return res.status(502).json({
        success: false,
        message: "AI sticker service is unavailable now. Check OPENROUTER_API_KEY or OPENAI_API_KEY in .env and try again.",
        error: "ai_service_unavailable"
      });
    }

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

