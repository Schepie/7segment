import os
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

def create_animation():
    width = 960
    height = 540
    fps = 20
    
    # Load fonts
    try:
        font_badge = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 15)
        font_title = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 24)
        font_sub = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
    except Exception:
        font_badge = ImageFont.load_default()
        font_title = font_badge
        font_sub = font_badge

    scenes_def = [
        {
            "img_path": "Images/padel_scoreboard_back_studio.jpg",
            "badge": "STAP 1: COMFORTABEL MEENEMEN",
            "title": "Draagriem & Geïntegreerde Powerbank",
            "sub": "Slechts enkele kilo's • In 1 beweging over de schouder naar de baan",
            "duration": 2.5,
            "zoom": (1.0, 1.08),
            "pan": (0.0, 0.0)
        },
        {
            "img_path": "Images/padel_carrying_to_court.jpg",
            "badge": "STAP 1: COMFORTABEL MEENEMEN",
            "title": "Moeiteloos Naar de Padelbaan",
            "sub": "Handen vrij voor je racket en sporttas",
            "duration": 3.0,
            "zoom": (1.0, 1.06),
            "pan": (0.02, -0.01)
        },
        {
            "img_path": "Images/padel_hook_front_real.jpg",
            "badge": "STAP 2: OPHANGEN AAN HET HEKWERK",
            "title": "Geïntegreerde 3D-Geprinte Haken",
            "sub": "Aan de voorzijde gepositioneerd • Haakt van buitenaf direct over het staaldraad",
            "duration": 2.4,
            "zoom": (1.0, 1.10),
            "pan": (0.0, -0.02)
        },
        {
            "img_path": "Images/padel_hanging_on_mesh.jpg",
            "badge": "STAP 2: OPHANGEN AAN HET HEKWERK",
            "title": "Binnen 5 Seconden Opgehangen",
            "sub": "100% Smashproof: Hangt veilig achter het gaas tegen harde ballen",
            "duration": 3.0,
            "zoom": (1.0, 1.07),
            "pan": (-0.02, 0.01)
        },
        {
            "img_path": "Images/20261002_122400.jpg",
            "badge": "STAP 3: POLSBEDIENING KOPPELEN",
            "title": "Draadloze BLE Button om de Pols",
            "sub": "Direct verbonden via Bluetooth Low Energy • Geen app nodig tijdens het spel",
            "duration": 2.4,
            "zoom": (1.0, 1.08),
            "pan": (0.01, 0.0)
        },
        {
            "img_path": "Images/padel_remote_wrist_action.jpg",
            "badge": "STAP 3: POLSBEDIENING KOPPELEN",
            "title": "Scoren met 1 Druk op de Knop",
            "sub": "Directe tactiele feedback en reactietijd onder 35 ms",
            "duration": 2.8,
            "zoom": (1.0, 1.07),
            "pan": (0.0, -0.02)
        },
        {
            "img_path": "Images/padel_playing_match_action.jpg",
            "badge": "STAP 4: KLAAR VOOR DE MATCH!",
            "title": "Volledige Focus op het Spel",
            "sub": "Felle WS2813 LED's stralen kristalhelder door de mazen van het hek",
            "duration": 3.4,
            "zoom": (1.0, 1.08),
            "pan": (-0.03, 0.0)
        },
        {
            "img_path": "Images/20261002_122537.jpg",
            "badge": "STAP 4: KLAAR VOOR DE MATCH!",
            "title": "Live Score: 40 - 15 (Set 1)",
            "sub": "Gescheiden teamkleuren & actieve serveerder-aanduiding",
            "duration": 3.0,
            "zoom": (1.02, 1.09),
            "pan": (0.0, -0.01)
        }
    ]

    # Pre-load and crop base images to 16:9 ratio
    loaded_imgs = []
    for sc in scenes_def:
        path = sc["img_path"]
        if not os.path.exists(path):
            print(f"Error: {path} not found!")
            return
        im = Image.open(path).convert('RGB')
        # Center crop to 16:9
        im_w, im_h = im.size
        target_ratio = width / height
        cur_ratio = im_w / im_h
        if cur_ratio > target_ratio:
            new_w = int(im_h * target_ratio)
            left = (im_w - new_w) // 2
            im = im.crop((left, 0, left + new_w, im_h))
        else:
            new_h = int(im_w / target_ratio)
            top = (im_h - new_h) // 2
            im = im.crop((0, top, im_w, top + new_h))
        loaded_imgs.append(im)

    total_scenes = len(scenes_def)
    transition_frames = int(0.5 * fps) # 0.5s transition
    
    # Calculate scene frame counts
    scene_frames_list = []
    for sc in scenes_def:
        count = int(sc["duration"] * fps)
        scene_frames_list.append(count)

    total_anim_frames = sum(scene_frames_list)
    print(f"Total animation frames: {total_anim_frames} ({total_anim_frames / fps:.1f}s)")

    # Prepare VideoWriter
    mp4_path = "Images/padel_carrying_hanging_playing.mp4"
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_writer = cv2.VideoWriter(mp4_path, fourcc, float(fps), (width, height))

    all_pil_frames = []

    def render_overlay(pil_img, badge_txt, title_txt, sub_txt, global_progress):
        # Draw dark sleek glass banner at the bottom
        overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        # Gradient / dark box at bottom
        banner_h = 100
        banner_y = height - banner_h
        draw.rectangle([(0, banner_y - 20), (width, height)], fill=(10, 15, 25, 220))
        
        # Subtle top border for banner
        draw.line([(0, banner_y - 20), (width, banner_y - 20)], fill=(0, 200, 255, 120), width=2)

        # Pill badge
        badge_w = int(draw.textlength(badge_txt, font=font_badge)) + 24
        badge_h = 24
        badge_x = 24
        badge_y = banner_y - 8
        draw.rounded_rectangle([(badge_x, badge_y), (badge_x + badge_w, badge_y + badge_h)], radius=12, fill=(0, 160, 255, 255))
        draw.text((badge_x + 12, badge_y + 3), badge_txt, fill=(255, 255, 255, 255), font=font_badge)

        # Title
        draw.text((24, banner_y + 22), title_txt, fill=(255, 255, 255, 255), font=font_title)

        # Subtitle
        draw.text((24, banner_y + 58), sub_txt, fill=(185, 210, 230, 255), font=font_sub)

        # Progress bar at very bottom
        bar_y = height - 4
        draw.rectangle([(0, bar_y), (width, height)], fill=(30, 40, 50, 255))
        prog_w = int(width * global_progress)
        draw.rectangle([(0, bar_y), (prog_w, height)], fill=(0, 220, 255, 255))

        base_rgba = pil_img.convert('RGBA')
        combined = Image.alpha_composite(base_rgba, overlay)
        return combined.convert('RGB')

    frame_index = 0
    current_scene_idx = 0
    
    # Generate frames per scene
    scene_rendered_frames = []

    for sc_idx, sc in enumerate(scenes_def):
        im_base = loaded_imgs[sc_idx]
        bw, bh = im_base.size
        count = scene_frames_list[sc_idx]
        z_start, z_end = sc["zoom"]
        pan_x, pan_y = sc["pan"]

        frames_for_this_scene = []
        for fi in range(count):
            t = fi / max(1, count - 1)
            # Zoom calculation
            zoom = z_start + (z_end - z_start) * t
            crop_w = bw / zoom
            crop_h = bh / zoom

            # Pan calculation
            cx = (bw / 2) + (pan_x * bw * t)
            cy = (bh / 2) + (pan_y * bh * t)

            x1 = max(0, min(bw - crop_w, cx - crop_w / 2))
            y1 = max(0, min(bh - crop_h, cy - crop_h / 2))
            x2 = x1 + crop_w
            y2 = y1 + crop_h

            cropped = im_base.crop((x1, y1, x2, y2)).resize((width, height), Image.Resampling.BILINEAR)
            frames_for_this_scene.append(cropped)

        scene_rendered_frames.append(frames_for_this_scene)

    # Now composite scenes with cross-dissolve transitions
    final_frames = []
    
    for s_idx in range(total_scenes):
        sc = scenes_def[s_idx]
        cur_frames = scene_rendered_frames[s_idx]
        num_frames = len(cur_frames)

        is_last = (s_idx == total_scenes - 1)
        next_frames = scene_rendered_frames[s_idx + 1] if not is_last else None

        for fi in range(num_frames):
            # Check if in transition zone at the end of scene
            in_trans = (fi >= num_frames - transition_frames) and (not is_last)
            
            if in_trans:
                trans_t = (fi - (num_frames - transition_frames)) / transition_frames
                f_a = cur_frames[fi]
                f_b = next_frames[int(trans_t * transition_frames)]
                # Cross-dissolve
                blended = Image.blend(f_a, f_b, trans_t)
                img_to_overlay = blended
            else:
                img_to_overlay = cur_frames[fi]

            # Global progress
            global_prog = len(final_frames) / total_anim_frames
            out_img = render_overlay(img_to_overlay, sc["badge"], sc["title"], sc["sub"], global_prog)
            final_frames.append(out_img)

    print(f"Rendered {len(final_frames)} final frames.")

    # Write MP4
    for frm in final_frames:
        # Convert PIL to BGR OpenCV
        cv_img = cv2.cvtColor(np.array(frm), cv2.COLOR_RGB2BGR)
        video_writer.write(cv_img)
    video_writer.release()
    print(f"MP4 successfully written to {mp4_path} ({os.path.getsize(mp4_path)} bytes)")

    # Save animated WebP (scaled to 800x450 for fast loading and great quality)
    webp_path = "Images/padel_carrying_hanging_playing.webp"
    webp_w = 800
    webp_h = 450
    webp_frames = [f.resize((webp_w, webp_h), Image.Resampling.BILINEAR) for f in final_frames]
    
    # Save WebP with 50ms duration (20fps)
    webp_tmp = "Images/padel_carrying_hanging_playing_tmp.webp"
    webp_frames[0].save(
        webp_tmp,
        format='WEBP',
        save_all=True,
        append_images=webp_frames[1:],
        duration=50,
        loop=0,
        quality=80,
        method=4
    )
    if os.path.exists(webp_path):
        try:
            os.remove(webp_path)
        except Exception:
            pass
    os.replace(webp_tmp, webp_path)
    print(f"WebP successfully written to {webp_path} ({os.path.getsize(webp_path)} bytes)")

if __name__ == "__main__":
    create_animation()
