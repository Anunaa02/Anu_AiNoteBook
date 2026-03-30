# Автомат хөрвүүлэгч тохиргоо (latexmk)
# Ажиллуулах: latexmk -pdf main.tex

$pdf_mode = 5;          # XeLaTeX ашиглах
$xelatex  = 'xelatex -interaction=nonstopmode -synctex=1 %O %S';
$bibtex_use = 1;
$clean_ext  = 'bbl blg aux toc lof lot out synctex.gz';
