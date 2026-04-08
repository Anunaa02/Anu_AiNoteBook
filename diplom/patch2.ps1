$content = Get-Content 'Chapters\Chapter3_Methodology.tex' -Raw -Encoding UTF8
$content = $content -replace '\\foreach \\x in \{0,5\.5,11,16\.5,21\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-1\.0\) -- \(\\x,-8\.6\);\}(?s).*?\\draw\[arr, dashed\] \(5\.5,-8\.4\) -- node\[msg\]\{Жагсаалт шинэчлэх\\\\\(refresh list\)\} \(0,-8\.4\);', "
\foreach \x in {0,5.5,11,16.5,21.5} {\draw[dashed, draw=gray!80, thick] (\x,-1.0) -- (\x,-11.0);}

\draw[arr] (0,-2.3) -- node[msg, text width=5cm]{Гарчиг, агуулга, сэтгэл\\хөдлөлийн төлөв\\(title, content, mood)} (5.5,-2.3);
\draw[arr] (5.5,-3.5) -- node[msg]{POST /notes + Bearer} (11,-3.5);
\draw[arr] (11,-4.7) -- node[msg]{Токен шалгах\\(verify(token))} (16.5,-4.7);
\draw[arr, dashed] (16.5,-5.9) -- node[msg]{Хэрэглэгчийн таних утга\\(req.userId)} (11,-5.9);
\draw[arr] (11,-7.1) -- node[msg]{Шинэ тэмдэглэл хадгалах\\(new Note().save())} (21.5,-7.1);
\draw[arr, dashed] (21.5,-8.3) -- node[msg]{Үүсгэсэн тэмдэглэл\\(created note)} (11,-8.3);
\draw[arr, dashed] (11,-9.5) -- node[msg]{201 Created} (5.5,-9.5);
\draw[arr, dashed] (5.5,-10.5) -- node[msg]{Жагсаалт шинэчлэх\\(refresh list)} (0,-10.5);"
Set-Content 'Chapters\Chapter3_Methodology.tex' -Value $content -NoNewline -Encoding UTF8
