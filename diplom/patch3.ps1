$content = Get-Content 'Chapters\Chapter3_Methodology.tex' -Raw -Encoding UTF8
$content = $content -replace '\\foreach \\x in \{0,4\.5,9\.5,14\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-0\.7\) -- \(\\x,-6\.4\);\}(?s).*?\\draw\[arr, dashed\] \(4\.5,-5\.9\) -- node\[msg\]\{Зургийн урьдчилан харах ба мессеж\\\\\(preview image \+ snackbar\)\} \(0,-5\.9\);', "
\foreach \x in {0,4.5,9.5,14.5} {\draw[dashed, draw=gray!80, thick] (\x,-1.0) -- (\x,-8.6);}

\draw[arr] (0,-2.0) -- node[msg]{Заавар текст\\(prompt)} (4.5,-2.0);
\draw[arr] (4.5,-3.2) -- node[msg]{POST /notes/generate-sticker} (9.5,-3.2);
\draw[arr] (9.5,-4.4) -- node[msg]{Зураг үүсгэх дуудлага\\(images.generate(prompt))} (14.5,-4.4);
\draw[arr, dashed] (14.5,-5.6) -- node[msg]{URL / алдаа} (9.5,-5.6);
\draw[arr, dashed] (9.5,-6.8) -- node[msg]{Стикерийн холбоос / тайлбар\\(stickerUrl / hint)} (4.5,-6.8);
\draw[arr, dashed] (4.5,-8.0) -- node[msg]{Зургийн урьдчилан харах ба мессеж\\(preview image + snackbar)} (0,-8.0);"
Set-Content 'Chapters\Chapter3_Methodology.tex' -Value $content -NoNewline -Encoding UTF8
