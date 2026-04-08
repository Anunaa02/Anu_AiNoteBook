$content = Get-Content 'Chapters\Chapter3_Methodology.tex' -Raw -Encoding UTF8
$content = $content -replace 'msg/\.style=\{above, align=center, font=\\small, inner sep=2pt\}', 'msg/.style={above, align=center, fill=white, font=\small, inner sep=2pt}'
$content = $content -replace '\\foreach \\x in \{0,5,10,15,19\.5\} \{\\draw\[dashed, draw=gray!80, thick\] \(\\x,-0\.7\) -- \(\\x,-6\.4\);\}(?s).*?\\draw\[arr, dashed\] \(5,-6\.1\) -- node\[msg\]\{Үндсэн дэлгэц\\\\\(MainScreen\(\)\)\} \(0,-6\.1\);', "
\foreach \x in {0,5,10,15,19.5} {\draw[dashed, draw=gray!80, thick] (\x,-0.7) -- (\x,-8.6);}

\draw[arr] (0,-2.0) -- node[msg]{Имэйл, нууц үг\\(email, password)} (5,-2.0);
\draw[arr] (5,-3.0) -- node[msg]{POST /auth/login} (10,-3.0);
\draw[arr] (10,-4.0) -- node[msg]{Хэрэглэгч хайх\\(findOne(email))} (15,-4.0);
\draw[arr, dashed] (15,-5.0) -- node[msg]{Хэрэглэгч (user)} (10,-5.0);
\draw[arr, dashed] (10,-6.0) -- node[msg]{Токен, хэрэглэгч} (5,-6.0);
\draw[arr] (5,-7.0) -- node[msg]{Токен хадгалах\\(saveToken())} (19.5,-7.0);
\draw[arr, dashed] (5,-8.0) -- node[msg]{Үндсэн дэлгэц\\(MainScreen())} (0,-8.0);"
Set-Content 'Chapters\Chapter3_Methodology.tex' -Value $content -NoNewline -Encoding UTF8
