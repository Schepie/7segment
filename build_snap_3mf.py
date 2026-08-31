import os
import zipfile
import shutil

def ascii_stl_to_triangles(stl_path):
    triangles = []
    current_tri = []
    with open(stl_path, 'r') as f:
        for line in f:
            if 'vertex' in line:
                parts = line.strip().split()
                current_tri.append((float(parts[1]), float(parts[2]), float(parts[3])))
                if len(current_tri) == 3:
                    triangles.append(tuple(current_tri))
                    current_tri = []
    return triangles

def build_3mf(out_3mf, parts):
    content_types = """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodelxml"/>
</Types>"""

    rels = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>"""

    xml_parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">',
        '  <resources>'
    ]
    
    for p in parts:
        obj_id = p['id']
        obj_name = p['name']
        triangles = p['triangles']
        vertex_map = {}
        vertices = []
        indexed_tris = []
        for tri in triangles:
            t_idx = []
            for pt in tri:
                rounded = (round(pt[0], 4), round(pt[1], 4), round(pt[2], 4))
                if rounded not in vertex_map:
                    vertex_map[rounded] = len(vertices)
                    vertices.append(rounded)
                t_idx.append(vertex_map[rounded])
            indexed_tris.append(t_idx)
            
        xml_parts.append(f'    <object id="{obj_id}" type="model" name="{obj_name}">')
        xml_parts.append('      <mesh>')
        xml_parts.append('        <vertices>')
        for v in vertices:
            xml_parts.append(f'          <vertex x="{v[0]}" y="{v[1]}" z="{v[2]}"/>')
        xml_parts.append('        </vertices>')
        xml_parts.append('        <triangles>')
        for t in indexed_tris:
            xml_parts.append(f'          <triangle v1="{t[0]}" v2="{t[1]}" v3="{t[2]}"/>')
        xml_parts.append('        </triangles>')
        xml_parts.append('      </mesh>')
        xml_parts.append('    </object>')
        
    xml_parts.append('  </resources>')
    xml_parts.append('  <build>')
    for p in parts:
        xml_parts.append(f'    <item objectid="{p["id"]}"/>')
    xml_parts.append('  </build>')
    xml_parts.append('</model>')
    
    with zipfile.ZipFile(out_3mf, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', content_types)
        z.writestr('_rels/.rels', rels)
        z.writestr('3D/3dmodel.model', '\n'.join(xml_parts))

base_dir = r"c:\Users\geert\Documents\Github\7segment"

# 1. Single Segment (0.4mm White + Transparent)
w_tris = ascii_stl_to_triangles(os.path.join(base_dir, 'single_segment_snaps_WHITE_0.4mm.stl'))
t_tris = ascii_stl_to_triangles(os.path.join(base_dir, 'single_segment_snaps_TRANSPARENT_from_0.4mm.stl'))
build_3mf(os.path.join(base_dir, 'single_segment_snaps_dual_layer_0.4mm_white.3mf'), [
    {'id': 1, 'name': 'White_Layer1_2_0.4mm', 'triangles': w_tris},
    {'id': 2, 'name': 'Transparent_Body_with_Snaps', 'triangles': t_tris}
])

# 2. 7-Segment Digit (0.4mm White + Transparent)
all_w_tris = ascii_stl_to_triangles(os.path.join(base_dir, '7segment_snaps_WHITE_0.4mm.stl'))
all_t_tris = ascii_stl_to_triangles(os.path.join(base_dir, '7segment_snaps_TRANSPARENT_from_0.4mm.stl'))
build_3mf(os.path.join(base_dir, '7segment_snaps_dual_layer_0.4mm_white.3mf'), [
    {'id': 1, 'name': 'White_Layer1_2_0.4mm', 'triangles': all_w_tris},
    {'id': 2, 'name': 'Transparent_Body_with_Snaps', 'triangles': all_t_tris}
])

shutil.copy2(os.path.join(base_dir, 'single_segment_snaps_dual_layer_0.4mm_white.3mf'), r'C:\Users\geert\Downloads\single_segment_snaps_dual_layer_0.4mm_white.3mf')
shutil.copy2(os.path.join(base_dir, '7segment_snaps_dual_layer_0.4mm_white.3mf'), r'C:\Users\geert\Downloads\7segment_snaps_dual_layer_0.4mm_white.3mf')
print("Successfully generated .3mf project files with 0.4mm White layer!")
