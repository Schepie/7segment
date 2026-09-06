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

# Magnetic Pogo Pin Connector — Backplate-Mounted Manual

This manual documents the **backplate-integrated, outside-mount installation** of the **5-pin magnetic pogo pin connector** into the modular 7-segment display and colon spacer housing.

---

## 1. Backplate-Mounted Architecture

To ensure **all electrical wiring, soldering, and harness routing are 100% self-contained on the backplate**, the connectors (both USB-C and Magnetic Pogo Pins) are physically part of the **Backplate**:

1. **Backplate Connector Towers:** Monolithic vertical towers rise from the backplate on the left and right walls to house the pogo connectors and USB-C port.
2. **Wire-Free Frontplate:** The black frontplate acts purely as an optical hood and light diffuser bezel with matching stepped U-notches. It can be mounted and unmounted at any time with **zero attached wires**.
3. **Stepped Lap-Joint (Zero Light Bleed):** A 1.0 mm stepped labyrinth overlap between the backplate tower and frontplate U-notch guarantees complete light isolation and a flush exterior seam.

```
                        FRONTPLATE (Optical Hood)
                 (Slidably mounts over backplate along -Z)
                 ┌──────────────────────────────────────┐
                 │     [Stepped 1mm Rebate U-Notch]     │
                 └───╭──────────────────────────────╮───┘
                     │       1.0mm Step Lap         │
                     ▼                              ▼
                     
                     ▲                              ▲
                     │       1.0mm Step Lip         │
                 ┌───╰──────────────────────────────╯───┐
                 │       [Backplate Connector Tower]    │
                 │       • 23.9 x 4.4mm Stadium Pocket  │
                 │       • 2x M2 x 5mm Screw Bosses     │
                 │       • Sense Resistor Pocket        │
                 │                                      │
                 │              BACKPLATE               │
                 │       • 100% Wiring & Electronics    │
                 └──────────────────────────────────────┘
```

---

## 2. Key Dimensions & Specifications

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
| **Total Length across Ears** | `23.5 mm` | `23.9 mm` | Ears sit flush in 3.0mm recessed pocket |
| **Hole Pitch (Center-to-Center)** | `20.0 mm` | `20.0 mm` | Exact hole alignment |
| **Central Body Width** | `17.5 mm` | `18.0 mm` | Stadium opening (+0.5 mm clearance) |
| **Body Height / Thickness** | `4.0 mm` | `4.4 mm` | Stadium opening (+0.4 mm clearance) |
| **Body Corner Radius** | `2.0 mm` | `2.2 mm` | Semi-circular rounded ends |
| **Screw Boss Depth** | — | `3.0 mm` | Recessed seating face from outer wall |
| **Screw Size** | **M2 × 5 mm** (or **M2 × 6 mm**) | Pilot hole: `1.8 mm` | Screws into 6mm deep internal boss |
| **Tower Width along Y** | — | `32.0 mm` | Centered at Y = 0 on backplate |
| **Stepped Lap Joint** | — | `1.0 mm` step | Labyrinth light trap against frontplate |

---

## 3. Mechanical Assembly Flow

```
[Step 1: Bench Assembly on Backplate]
    1. Install LED strips into the backplate channels.
    2. Snap ESP32 SuperMini into its backplate cradle (Panel 1).
    3. Install Pogo pin connectors into the backplate towers from outside.
    4. Fasten with 2x M2 x 5mm screws into the 1.8mm pilot holes.
    5. Solder wire harness and sense resistor directly on the backplate.
    6. Route all wires into the backplate floor cable retention clips.
    7. Fully test all electronics on the bench!

[Step 2: Install Frontplate]
    1. Slide the frontplate straight down over the backplate.
    2. The frontplate stepped U-notches smoothly wrap over the backplate connector towers.
    3. Secure with 4x M3 countersunk screws into the frontplate corner inserts.
    
    -> Zero wires are attached to the frontplate, allowing unlimited removal without risk!
```

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

## 5. Quick Test Print Coupons

- **Test Coupon SCAD:** [`test_coupons_backplate_connectors.scad`](file:///c:/Users/geert/Documents/Github/7segment/scad/test_coupons_backplate_connectors.scad)
- **Included Tests:**
  - `backplate_pogo_tower`: Isolated backplate connector tower for testing pogo connector fit and screw bite.
  - `frontplate_stepped_notch`: Isolated frontplate cap for testing the stepped lap joint.
  - `both_side_by_side`: Rapid test print (~15 minutes on Bambu Lab) to verify tolerances, slide-in smoothness, and light-tight seal.
