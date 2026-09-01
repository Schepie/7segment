# Magnetic Pogo Pin Connector — Outside Mount Manual

This manual documents the **outside-mount installation** of the **5-pin magnetic pogo pin connector** into the modular 7-segment display and colon spacer housing.

---

## 1. Key Dimensions & Specifications

```
                       23.5 mm (Full Length across Ears)
◄─────────────────────────────────────────────────────────────────►
               20.0 mm (Center-to-Center Hole Pitch)
      ◄─────────────────────────────────────────────►
                     17.5 mm (Plug Body)
             ◄───────────────────────────────►
      ┌───────╭─────────────────────────────╮───────┐  ▲
      │  (O)  │  (N)   •   •   •   •   •  (S)│  (O)  │  │ 4.0 mm
      └───────╰─────────────────────────────╯───────┘  ▼
       Ear 1        Stadium Rounded Plug       Ear 2
      (Ø1.8mm)            (r = 2.0 mm)        (Ø1.8mm)
```

| Parameter | Physical Part | 3D CAD Pocket Dimension | Note |
| :--- | :--- | :--- | :--- |
| **Total Length across Ears** | `23.5 mm` | — | Ears sit flat on outside wall |
| **Hole Pitch (Center-to-Center)** | `20.0 mm` | `20.0 mm` | Exact hole alignment |
| **Central Body Width** | `17.5 mm` | `18.0 mm` | Stadium opening (+0.5 mm) |
| **Body Height / Thickness** | `4.0 mm` | `4.4 mm` | Stadium opening (+0.4 mm) |
| **Body Corner Radius** | `2.0 mm` | `2.2 mm` | Semi-circular rounded ends |
| **Rear Body Depth (behind ears)** | `2.0 mm` | `2.0 mm` | Inserts into 2.0mm wall |
| **Mounting Ear Thickness** | `1.0 mm` | — | Protrudes only 1.0 mm on outside |
| **Screw Size** | **M2 × 5 mm** (or **M2 × 6 mm**) | Pilot hole: `1.8 mm` | Screws into 6mm deep internal boss |

---

## 2. Mechanical Architecture (Outside Mount)

The connector is installed directly from the **outside face** of the cabinet:
1. The 17.5 mm body passes through the 18.0 × 4.4 mm stadium opening into the housing.
2. The two mounting ears rest flat against the **outside wall surface**.
3. Two **M2 × 5mm screws** are driven from the outside through the connector ears into the **6 mm deep internal reinforced bosses**.

### Top-Down Cross Section Diagram

```
                              OUTSIDE OF HOUSING
                          (Facing adjacent digit)
              M2 x 5mm Screw                          M2 x 5mm Screw
              (From Outside)                          (From Outside)
                    │                                       │
                    ▼                                       ▼
    ═══════════════[═]════════╦═══════════════╦════════════[═]═══════════
    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[Ear]▒▒▒▒▒▒║ Stadium Window║▒▒▒▒▒▒[Ear]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    ▒▒ Outer Wall  [1mm] ▒▒▒▒▒║ (18.0 x 4.4mm)║▒▒▒▒▒ [1mm]  Outer Wall ▒▒
    ▒▒ (2.0mm)     ┌────┐     ║               ║     ┌────┐  (2.0mm)    ▒▒
    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│    │▒▒▒▒▒╨───────────────╨▒▒▒▒▒│    │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    ▒▒             │    │    Pogo Connector Body    │    │             ▒▒
    ▒▒  Internal   │    │   ┌───────────────────┐   │    │  Internal   ▒▒
    ▒▒  Boss       │    │   │  Plug Body (2mm)  │   │    │  Boss       ▒▒
    ▒▒  (6mm Deep) │(..)|   └─────────┬─────────┘   │(..)|  (6mm Deep) ▒▒
    ▒▒             └────┘             │             └────┘             ▒▒
    ▒▒                ▲          4-Wire Cable          ▲               ▒▒
    ══════════════════╪═══════════════╪════════════════╪═════════════════
                      │               │                │
            Deep Thread Bite     To LED Strip    Deep Thread Bite
               (4mm+ meat)      Inside Cabinet      (4mm+ meat)

                              INSIDE HOUSING
```

---

## 3. Advantages of Outside Mounting

1. **Very Strong & Simple:** Screws go into a **6.0 mm solid internal boss** — $> 4\text{ mm}$ of deep, secure thread bite that will never strip.
2. **Easy Assembly & Maintenance:** You can install, wire, or replace a pogo connector directly from the outside without opening or disassembling the backplate.
3. **No Thin-Wall Punch-Through Risk:** Standard M2 × 5mm or M2 × 6mm screws fit naturally with deep thread engagement.
4. **Minimal Profile:** The mounting ears are only 1.0 mm thick, fitting easily in the seam gap between display modules.

---

## 4. Electrical Pinout & Wiring

```
        Pin 1        Pin 2        Pin 3        Pin 4        Pin 5
       [ +5V ]      [ GND ]      [ DATA ]     [ SENSE ]    [ RESV ]
     (Red Wire)  (Black Wire)  (Green Wire)  (Blue Wire)   (Optional)
```

```
Panel 1 (Left)                    Magnetic Seam                  Panel 2 (Right)
┌────────────────┐             ┌─────────────────┐             ┌────────────────┐
│ +5V Power      ├────────────►│ Pin 1: +5V      ├────────────►│ +5V Power      │
│ GND            ├────────────►│ Pin 2: GND      ├────────────►│ GND            │
│ LED Data Out   ├────────────►│ Pin 3: Data     ├────────────►│ LED Data In    │
│ Auto-Sense/ID  ├────────────►│ Pin 4: Sense    ├────────────►│ Auto-Sense/ID  │
└────────────────┘             └─────────────────┘             └────────────────┘
```

---

## 5. Step-by-Step Installation Instructions

```
[Step 1: Wire Pre-Solder]
    Pre-solder the 4 flexible wires to the back pins of the connector.

[Step 2: Outside-In Insertion]
    Feed wires through the stadium slot into the cabinet, and push 
    the connector body into the opening until the ears touch the outside wall.

[Step 3: Fasten Screws from Outside]
    Drive two standard M2 x 5mm screws from the outside through the ear holes
    into the 1.8mm pilot holes. They bite securely into the 6mm deep boss.
```

---

## 6. Quick Test Print

- **STL File:** [`test_fit_coupon_Pogo_Pin_connector.stl`](file:///c:/Users/geert/Documents/Github/7segment/test_fit_coupon_Pogo_Pin_connector.stl)
- **Print Settings:** 0.2 mm layer height, 3 perimeters, 15% infill. Print time: ~10 minutes.
