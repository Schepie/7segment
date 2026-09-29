from PIL import Image
import os

digit_segs = {
    'a': '15,12 27,24 141,24 153,12 141,0 27,0',
    'b': '155,16 143,28 143,140 156,152 168,140 168,28',
    'c': '155,159 143,171 143,284 156,296 168,284 168,171',
    'd': '15,299 26,311 141,311 152,300 140,287 28,287',
    'e': '12,159 0,171 0,285 11,296 24,284 24,171',
    'f': '12,15 0,27 0,141 12,153 24,141 24,27',
    'g': '15,156 27,168 140,168 152,155 141,144 27,144'
}

digit_x = [26, 242, 545, 761]
digit_y = 23

ladder_y = [35.5, 62.0, 113.5, 139.5, 166.0, 192.0, 218.0, 243.5, 270.0, 296.0, 322.0]

svg_parts = []
svg_parts.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 426" width="1024" height="426">')
svg_parts.append('  <rect width="1024" height="426" fill="#fbf8ea" />')
svg_parts.append('  <rect x="36" y="34" width="952" height="358" rx="8" fill="#161e2b" />')
svg_parts.append('  <g transform="translate(36, 34)">')

for idx, dx in enumerate(digit_x):
    svg_parts.append(f'    <g id="dig_{idx}" transform="translate({dx}, {digit_y})">')
    for s_name, pts in digit_segs.items():
        svg_parts.append(f'      <polygon id="dig_{idx}_{s_name}" points="{pts}" fill="#b6beca" />')
    svg_parts.append('    </g>')

svg_parts.append('    <g id="ladder">')
for r_idx, y in enumerate(ladder_y):
    svg_parts.append(f'      <circle id="lad_L_{r_idx}" cx="458" cy="{y}" r="8" fill="#b6beca" />')
    svg_parts.append(f'      <circle id="lad_R_{r_idx}" cx="493" cy="{y}" r="8" fill="#b6beca" />')
svg_parts.append('    </g>')

svg_parts.append('  </g>')
svg_parts.append('</svg>')

os.makedirs('Images', exist_ok=True)
with open('Images/test_board.svg', 'w') as f:
    f.write('\n'.join(svg_parts))
print('Images/test_board.svg created successfully')
