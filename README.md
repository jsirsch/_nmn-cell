# NMN Cell Simulation & TUI

A high-performance biochemical simulation and interactive Terminal User Interface (TUI) built in **Haskell** using the [**Brick**](https://github.com/jtdaugherty/brick) library, modeling the intracellular synthesis of **Nicotinamide Mononucleotide (NMN)** and **NAD+** metabolism.

---

## 🧬 Biological Background

Nicotinamide Mononucleotide ($\text{NMN}$) is a key intermediate in the biosynthesis of Nicotinamide Adenine Dinucleotide ($\text{NAD}^+$), an essential coenzyme for redox reactions and a critical substrate for sirtuins ($\text{SIRT1-7}$) and $\text{PARP}$ enzymes.

```
       [ Nicotinamide (NAM) ] + [ PRPP ]
                     │
                     ▼ (NAMPT - Rate-Limiting Salvage)
             [ NMN (Target) ] ◄─── (NRK1) ─── [ NR (Riboside) ] + [ ATP ]
                     │
                     ▼ (NMNAT1/2/3) + [ ATP ]
             [ NAD+ (Coenzyme) ]
                     │
                     ▼ (CD38 / SIRTs / PARPs)
             [ NAM (Salvage Recycled) ]
```

### Biochemical Pathways Modeled
1. **Primary Salvage Pathway ($\text{NAMPT}$)**:
   $$\text{NAM} + \text{PRPP} \xrightarrow{\text{NAMPT}} \text{NMN} + \text{PP}_i$$
   The primary rate-limiting step in mammalian cells. Coupled with feedback regulation from intracellular $\text{NAD}^+$ levels.
2. **Riboside Kinase Pathway ($\text{NRK1}$)**:
   $$\text{NR} + \text{ATP} \xrightarrow{\text{NRK1}} \text{NMN} + \text{ADP}$$
   Directly converts Nicotinamide Riboside ($\text{NR}$) into $\text{NMN}$ using cellular $\text{ATP}$.
3. **$\text{NAD}^+$ Biosynthesis ($\text{NMNAT}$)**:
   $$\text{NMN} + \text{ATP} \xrightarrow{\text{NMNAT}} \text{NAD}^+ + \text{PP}_i$$
4. **$\text{NAD}^+$ Consumption ($\text{CD38}$ & $\text{SIRTs}$)**:
   $$\text{NAD}^+ \xrightarrow{\text{CD38/SIRT}} \text{NAM} + \text{Byproducts}$$
5. **Adenylate Energy Balance & Homeostasis**:
   Dynamically tracks Adenylate Energy Charge:
   $$\text{Energy Charge} = \frac{[\text{ATP}] + 0.5 \cdot [\text{ADP}]}{[\text{ATP}] + [\text{ADP}] + [\text{AMP}]}$$

---

## 📁 Project Structure

The project separates the pure simulation domain from the interactive Brick TUI:

```
.
├── nmn-cell.cabal            # Cabal package definition (Library & TUI executable)
├── cabal.project             # Cabal multi-project configuration
├── flake.nix                 # Nix Flake definition (packages, apps, devShells)
├── shell.nix                 # Legacy Nix-shell environment
├── LICENSE                   # MIT License
├── README.md                 # Project documentation
│
├── src/                      # Domain Model & Simulation Engine
│   └── NMN/
│       ├── Types.hs          # Metabolites, Enzyme definitions, Cell state, Fluxes
│       ├── Enzymes.hs        # Michaelis-Menten kinetic equations & regulation
│       ├── Pathways.hs       # Coupled differential rate equations
│       └── Simulation.hs     # Numerical integration & biological perturbations
│
└── tui/                      # Dedicated Brick TUI Application
    ├── Main.hs               # Executable entry point, ticker thread & Vty setup
    └── UI/
        ├── Types.hs          # Brick AppState, Lenses, and CustomEvent
        ├── Attributes.hs     # UI styling, color schemes, and themes
        ├── Draw.hs           # Terminal widgets, ASCII pathway map & gauges
        ├── Events.hs         # Keyboard shortcuts & event handlers
        └── App.hs            # Brick App declaration
```

---

## 🚀 Building & Running

### Option 1: Nix Flakes (Recommended)

Run the TUI directly:
```bash
nix run
```

Enter a development shell (with GHC, Cabal, HLS, HLint, and ghcid):
```bash
nix develop
```

Build package binary:
```bash
nix build
```

---

### Option 2: Cabal

#### Prerequisites
- [GHC](https://www.haskell.org/ghc/) (>= 9.2 recommended)
- [Cabal](https://www.haskell.org/cabal/) (>= 3.6)

#### Run the Interactive TUI
```bash
cabal run nmn-cell-tui
```

#### Build Only
```bash
cabal build
```

---

## 🎮 Interactive Controls

| Key | Action |
|:---|:---|
| <kbd>Space</kbd> | Toggle Simulation **Pause / Resume** |
| <kbd>t</kbd> | **Single-step** 1 simulation tick (useful when paused) |
| <kbd>1</kbd> | **Inject Nicotinamide (NAM)** (+25.0 μM) |
| <kbd>2</kbd> | **Inject Nicotinamide Riboside (NR)** (+20.0 μM) |
| <kbd>3</kbd> | **Inject PRPP Substrate** (+15.0 μM) |
| <kbd>4</kbd> | **Inject ATP Energy** (+500.0 μM) |
| <kbd>u</kbd> | **Upregulate NAMPT** expression (+25%) |
| <kbd>i</kbd> | **Toggle NAMPT Inhibitor** ($\text{FK866}$ simulation: 85% inhibition) |
| <kbd>c</kbd> | **Toggle CD38 Inhibitor** ($78\text{c}$ simulation: $\text{NAD}^+$ sparing) |
| <kbd>+</kbd> / <kbd>-</kbd> | Increase / Decrease simulation speed ($\Delta t$) |
| <kbd>Tab</kbd> | Switch between View Tabs (**Overview**, **Enzymes**, **Help**) |
| <kbd>r</kbd> | **Reset** cell state to initial baseline |
| <kbd>q</kbd> / <kbd>Esc</kbd> | **Quit** application |
