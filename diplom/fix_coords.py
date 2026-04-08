import re
with open('Chapters/Chapter3_Methodology.tex', 'r', encoding='utf-8') as f:
    text = f.read()

# Add fill=white
text = text.replace(r'msg/.style={above, align=center, font=\small, inner sep=2pt}', r'msg/.style={above, align=center, font=\small, inner sep=2pt, fill=white}')

# Seq 1
text = text.replace(r'(\x,-0.7) -- (\x,-6.4)', r'(\x,-0.7) -- (\x,-8.6)')
text = text.replace(r'(0,-1.5)', r'(0,-2.0)')
text = text.replace(r'(5,-1.5)', r'(5,-2.0)')
text = text.replace(r'(5,-2.2)', r'(5,-3.0)')
text = text.replace(r'(10,-2.2)', r'(10,-3.0)')
text = text.replace(r'(10,-3.0)', r'(10,-4.0)')
text = text.replace(r'(15,-3.0)', r'(15,-4.0)')
text = text.replace(r'(15,-3.8)', r'(15,-5.0)')
text = text.replace(r'(10,-3.8)', r'(10,-5.0)')
text = text.replace(r'(10,-4.6)', r'(10,-6.0)')
text = text.replace(r'(5,-4.6)', r'(5,-6.0)')
text = text.replace(r'(5,-5.4)', r'(5,-7.0)')
text = text.replace(r'(19.5,-5.4)', r'(19.5,-7.0)')
text = text.replace(r'(5,-6.1)', r'(5,-8.0)')
text = text.replace(r'(0,-6.1)', r'(0,-8.0)')

# Seq 2
text = text.replace(r'(\x,-1.0) -- (\x,-8.6)', r'(\x,-1.0) -- (\x,-11.0)')
text = text.replace(r'(0,-1.6)', r'(0,-2.3)')
text = text.replace(r'(5.5,-1.6)', r'(5.5,-2.3)')
text = text.replace(r'(5.5,-2.6)', r'(5.5,-3.5)')
text = text.replace(r'(11,-2.6)', r'(11,-3.5)')
text = text.replace(r'(11,-3.6)', r'(11,-4.7)')
text = text.replace(r'(16.5,-3.6)', r'(16.5,-4.7)')
text = text.replace(r'(16.5,-4.6)', r'(16.5,-5.9)')
text = text.replace(r'(11,-4.6)', r'(11,-5.9)')
text = text.replace(r'(11,-5.6)', r'(11,-7.1)')
text = text.replace(r'(21.5,-5.6)', r'(21.5,-7.1)')
text = text.replace(r'(21.5,-6.6)', r'(21.5,-8.3)')
text = text.replace(r'(11,-6.6)', r'(11,-8.3)')
text = text.replace(r'(11,-7.6)', r'(11,-9.5)')
text = text.replace(r'(5.5,-7.6)', r'(5.5,-9.5)')
text = text.replace(r'(5.5,-8.4)', r'(5.5,-10.5)')
text = text.replace(r'(0,-8.4)', r'(0,-10.5)')

# Seq 3
# (\x,-0.7) -- (\x,-6.4); -> wait, might overlap with first if we are not careful
text = text.replace(r'foreach \x in {0,4.5,9.5,14.5} {\draw[dashed, draw=gray!80, thick] (\x,-0.7) -- (\x,-6.4)', r'foreach \x in {0,4.5,9.5,14.5} {\draw[dashed, draw=gray!80, thick] (\x,-1.0) -- (\x,-8.6)')
text = text.replace(r'(0,-1.4)', r'(0,-2.0)')
text = text.replace(r'(4.5,-1.4)', r'(4.5,-2.0)')
text = text.replace(r'(4.5,-2.3)', r'(4.5,-3.2)')
text = text.replace(r'(9.5,-2.3)', r'(9.5,-3.2)')
text = text.replace(r'(9.5,-3.2)', r'(9.5,-4.4)')
text = text.replace(r'(14.5,-3.2)', r'(14.5,-4.4)')
text = text.replace(r'(14.5,-4.1)', r'(14.5,-5.6)')
text = text.replace(r'(9.5,-4.1)', r'(9.5,-5.6)')
text = text.replace(r'(9.5,-5.0)', r'(9.5,-6.8)')
text = text.replace(r'(4.5,-5.0)', r'(4.5,-6.8)')
text = text.replace(r'(4.5,-5.9)', r'(4.5,-8.0)')
text = text.replace(r'(0,-5.9)', r'(0,-8.0)')

with open('Chapters/Chapter3_Methodology.tex', 'w', encoding='utf-8') as f:
    f.write(text)

