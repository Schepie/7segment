import zipfile
import os
import struct

def make_3mf(output_path, model_objects):
    """
    model_objects: list of dicts:
    [
      {
        'id': 1,
        'name': 'White_Layer1_0.2mm',
        'color': '#FFFFFFFF',
        'triangles': [ ((x1,y1,z1), (x2,y2,z2), (x3,y3,z3)), ... ]
      }, ...
    ]
    """
    content_types = """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodelxml"/>
</Types>"""

    rels = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>"""

    # Build 3D model XML
    xml_parts = []
    xml_parts.append('<?xml version="1.0" encoding="UTF-8"?>')
    xml_parts.append('<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">')
    xml_parts.append('  <resources>')
    
    for obj in model_objects:
        obj_id = obj['id']
        obj_name = obj['name']
        triangles = obj['triangles']
        
        # Deduplicate vertices
        vertex_map = {}
        vertices = []
        indexed_tris = []
        
        for tri in triangles:
            tri_indices = []
            for pt in tri:
                rounded = (round(pt[0], 4), round(pt[1], 4), round(pt[2], 4))
                if rounded not in vertex_map:
                    vertex_map[rounded] = len(vertices)
                    vertices.append(rounded)
                tri_indices.append(vertex_map[rounded])
            indexed_tris.append(tri_indices)
            
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
    for obj in model_objects:
        xml_parts.append(f'    <item objectid="{obj["id"]}"/>')
    xml_parts.append('  </build>')
    xml_parts.append('</model>')
    
    model_xml = "\n".join(xml_parts)
    
    with zipfile.ZipFile(output_path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', content_types)
        z.writestr('_rels/.rels', rels)
        z.writestr('3D/3dmodel.model', model_xml)

from generate_diffusers import create_segment_polygon, generate_7segment_polygons, triangulate_polygon_prism

# Create 3MF for single segment
single_poly = [create_segment_polygon(104.0, 18.0)]
s_w_tris = []
s_t_tris = []
for p in single_poly:
    s_w_tris.extend(triangulate_polygon_prism(p, 0.0, 0.2))
    s_t_tris.extend(triangulate_polygon_prism(p, 0.2, 0.8))

make_3mf(r"c:\Users\geert\Documents\Github\7segment\single_segment_dual_layer.3mf", [
    {'id': 1, 'name': 'Layer1_White_0.2mm', 'triangles': s_w_tris},
    {'id': 2, 'name': 'Layer2_Transparent_0.6mm', 'triangles': s_t_tris}
])

# Create 3MF for 7-segment digit
seven_polys = generate_7segment_polygons()
seven_w_tris = []
seven_t_tris = []
for p in seven_polys:
    seven_w_tris.extend(triangulate_polygon_prism(p, 0.0, 0.2))
    seven_t_tris.extend(triangulate_polygon_prism(p, 0.2, 0.8))

make_3mf(r"c:\Users\geert\Documents\Github\7segment\7segment_diffuser_dual_layer.3mf", [
    {'id': 1, 'name': 'Layer1_White_0.2mm', 'triangles': seven_w_tris},
    {'id': 2, 'name': 'Layer2_Transparent_0.6mm', 'triangles': seven_t_tris}
])

print("Generated .3mf files successfully in project root!")
