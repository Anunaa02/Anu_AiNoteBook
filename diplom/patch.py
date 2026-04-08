import re

with open('Chapters/Chapter3_Methodology.tex', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace Diagram 1 msg/.style
text = text.replace(r'msg/.style={above, align=center, font=\small, inner sep=2pt}', r'msg/.style={above, align=center, fill=white, font=\small, inner sep=2pt}')

# Replace Diagram 1 lines
text = re.sub(
    r'\\foreach \\x in \{0,5,10,15,19\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-0\.7\) -- \(\\x,-6\.4\);\}.*?\\draw\[arr, dashed\] \(5,-6\.1\) -- node\[msg\]\{Үндсэн дэлгэц\\\\\(MainScreen\(\)\)\} \(0,-6\.1\);',
    r'\\foreach \\x in {0,5,10,15,19.5} {\\draw[dashed, draw=gray!80, thick] (\\x,-0.7) -- (\\x,-8.6);}\n\n'
    r'  \\draw[arr] (0,-2.0) -- node[msg]{Имэйл, нууц үг\\\\(email, password)} (5,-2.0);\n'
    r'  \\draw[arr] (5,-3.0) -- node[msg]{POST /auth/login} (10,-3.0);\n'
    r'  \\draw[arr] (10,-4.0) -- node[msg]{Хэрэглэгч хайх\\\\(findOne(email))} (15,-4.0);\n'
    r'  \\draw[arr, dashed] (15,-5.0) -- node[msg]{Хэрэглэгч (user)} (10,-5.0);\n'
    r'  \\draw[arr, dashed] (10,-6.0) -- node[msg]{Токен, хэрэглэгч} (5,-6.0);\n'
    r'  \\draw[arr] (5,-7.0) -- node[msg]{Токен хадгалах\\\\(saveToken())} (19.5,-7.0);\n'
    r'  \\draw[arr, dashed] (5,-8.0) -- node[msg]{Үндсэн дэлгэц\\\\(MainScreen())} (0,-8.0);',
    text,
    flags=re.DOTALL
)

# Replace Diagram 2 lines
text = re.sub(
    r'\\foreach \\x in \{0,5\.5,11,16\.5,21\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-1\.0\) -- \(\\x,-8\.6\);\}.*?\\draw\[arr, dashed\] \(5\.5,-8\.4\) -- node\[msg\]\{Жагсаалт шинэчлэх\\\\\(refresh list\)\} \(0,-8\.4\);',
    r'\\foreach \\x in {0,5.5,11,16.5,21.5} {\\draw[dashed, draw=gray!80, thick] (\\x,-1.0) -- (\\x,-11.0);}\n\n'
    r'  \\draw[arr] (0,-2.3) -- node[msg, text width=5cm]{Гарчиг, агуулга, сэтгэл\\\\хөдлөлийн төлөв\\\\(title, content, mood)} (5.5,-2.3);\n'
    r'  \\draw[arr] (5.5,-3.5) -- node[msg]{POST /notes + Bearer} (11,-3.5);\n'
    r'  \\draw[arr] (11,-4.7) -- node[msg]{Токен шалгах\\\\(verify(token))} (16.5,-4.7);\n'
    r'  \\draw[arr, dashed] (16.5,-5.9) -- node[msg]{Хэрэглэгчийн таних утга\\\\(req.userId)} (11,-5.9);\n'
    r'  \\draw[arr] (11,-7.1) -- node[msg]{Шинэ тэмдэглэл хадгалах\\\\(new Note().save())} (21.5,-7.1);\n'
    r'  \\draw[arr, dashed] (21.5,-8.3) -- node[msg]{Үүсгэсэн тэмдэглэл\\\\(created note)} (11,-8.3);\n'
    r'  \\draw[arr, dashed] (11,-9.5) -- node[msg]{201 Created} (5.5,-9.5);\n'
    r'  \\draw[arr, dashed] (5.5,-10.5) -- node[msg]{Жагсаалт шинэчлэх\\\\(refresh list)} (0,-10.5);',
    text,
    flags=re.DOTALL
)

# Replace Diagram 3 lines
text = re.sub(
    r'\\foreach \\x in \{0,4\.5,9\.5,14\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-0\.7\) -- \(\\x,-6\.4\);\}.*?\\draw\[arr, dashed\] \(4\.5,-5\.9\) -- node\[msg\]\{Зургийн урьдчилан харах ба мессеж\\\\\(preview image \+ snackbar\)\} \(0,-5\.9\);',
    r'\\foreach \\x in {0,4.5,9.5,14.5} {\\draw[dashed, draw=gray!80, thick] (\\x,-1.0) -- (\\x,-8.6);}\n\n'
    r'  \\draw[arr] (0,-2.0) -- node[msg]{Заавар текст\\\\(prompt)} (4.5,-2.0);\n'
    r'  \\draw[arr] (4.5,-3.2) -- node[msg]{POST /notes/generate-sticker} (9.5,-3.2);\n'
    r'  \\draw[arr] (9.5,-4.4) -- node[msg]{Зураг үүсгэх дуудлага\\\\(images.generate(prompt))} (14.5,-4.4);\n'
    r'  \\draw[arr, dashed] (14.5,-5.6) -- node[msg]{URL / алдаа} (9.5,-5.6);\n'
    r'  \\draw[arr, dashed] (9.5,-6.8) -- node[msg]{Стикерийн холбоос / тайлбар\\\\(stickerUrl / hint)} (4.5,-6.8);\n'
    r'  \\draw[arr, dashed] (4.5,-8.0) -- node[msg]{Зургийн урьдчилан харах ба мессеж\\\\(preview image + snackbar)} (0,-8.0);',
    text,
    flags=re.DOTALL
)

with open('Chapters/Chapter3_Methodology.tex', 'w', encoding='utf-8') as f:
    f.write(text)

