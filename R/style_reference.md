# Style reference — conventions extracted from my earlier figure code

Source: `input/MY_R_STYLE_REFERENCE.txt` (line numbers below refer to that file).
It contains three scripts:

| Block | Lines | Tool | Figure |
|---|---|---|---|
| S1 | 1–148 | Stata | `[Figure 2-2-2] Annual Premiums and Premium Rate` |
| R1 | 150–202 | R / ggplot2 | Agricultural Disaster Insurance budget, 2014–2026 (no title) |
| S2 | 204–349 | Stata | `[Figure 2-2-1] Insured by Year and Insurance Uptake Rate` |

R1 is the only ggplot2 script, so it fixes everything that has a direct ggplot2
equivalent (theme, sizes, grid, border, colour of a single series, number format).
S1 and S2 are the numbered thesis figures from Chapter 2; they fix the conventions
R1 does not cover because R1 has one series and no title (title format, legend
placement, source note, bar fill, export width). Where the scripts conflict, the
decision and the reason are stated.

## 1. Extracted conventions

| Element | Convention used for Chapter 5 | Evidence (line) | Note |
|---|---|---|---|
| Base theme | `theme_bw()` | R1 190 | |
| Font family | **Arial Narrow** (fallback Nimbus Sans Narrow), final decision §2 | S1 10, S2 213 (`"Arial Narrow"`); R1 190 used `"sans"` | Superseded draft choice: `sans` |
| Base font size | 14 | R1 190 `base_size = 14` | |
| Axis-title size | 15, black | R1 196 | |
| Axis-label size | 11, `grey30` | R1 197 | |
| x-axis labels | horizontal, centred | R1 198; S1/S2 `angle(0)` 102, 304 | |
| Title | **None inside the graphic**; figure number and caption go in the thesis document (final decision §2) | R1 192 `plot.title = element_blank()` | S1/S2 put bracketed titles in the graph; not used |
| Title size | not applicable (no in-graphic title) | — | |
| Subtitle | none | none in any script | |
| Caption / source note | bottom-left, same size as axis labels (11), starts `Source:` | S1 130–132, S2 331–333 (`note(... size(small) position(7))`) | Methodological caveats go in the same note. |
| Legend | top, one row, no box, text 11, no legend title | S1 123–128, S2 324–329 (`position(12) row(1) size(small) region(lcolor(white))`) | R1 199 `legend.position = "none"` (single series only) |
| Major grid | `grey90`, width 0.6 | R1 194 | S1/S2 use dashed horizontal `gs12` grid (105, 307); R1 wins (ggplot2 script) |
| Minor grid | `grey95`, width 0.4 | R1 195 | |
| Panel border | `grey40`, width 0.8 | R1 193 | |
| Background | white plot and panel, no outer border | R1 200–201; S1 134–136, S2 335–337 | S1/S2 draw a thin navy outer frame (`graphregion lcolor(navy)`); not reproduced (R1 has none). |
| Line series | width 0.9 | R1 175 `size = 0.9` (= `linewidth` in ggplot2 ≥ 3.4) | S1/S2 `lwidth(medthin)` 79, 281 |
| Points | size 2.5, filled circle | R1 176; S1/S2 `msymbol(O)` 77, 279 | |
| Main colour | `#66C2A5` | R1 175–176 | = ColorBrewer Set2 colour 1 |
| Further categories | next ColorBrewer Set2 colours (`#FC8D62`, `#8DA0CB`, `#E78AC3`, `#B3B3B3`) | extension of R1's Set2 colour | only where ≥ 2 categories are unavoidable |
| Bar fill | `#99C7A4`, no outline, bar width 0.55 | S1 61–63 (`fcolor("153 199 164") lcolor(none) barwidth(0.55)`) | S2 264 uses Stata `eltblue` for bars; S1's explicit RGB used |
| Pre-period / secondary marks | `grey40` | R1 193 (border colour); neutral | needed for placebo estimates; no direct precedent |
| Number format | thousands separator `,`; no scientific notation | R1 181; S1 100 `%12.0fc` | |
| y expansion for bars from zero | `expansion(mult = c(0, 0.03))` | R1 184 | |
| x-axis title | `"Year"` for time axes | R1 187 | S1/S2 leave it blank (121, 322) |
| Axis title units | unit in parentheses, e.g. `Budget (million KRW)` | R1 188 | S1/S2 put the unit alone (`"KRW million"`, `"%"`) |
| Value labels on bars/points | not used | R1 has none | S1/S2 label every bar (65–71, 267–273); not used here because event-study and forest plots would become unreadable and the brief asks for no unnecessary annotation |
| Facets | theme_bw default strips | no facet in any script | |
| Export | PNG, 2400 px wide | S1 148, S2 349 `graph export ... width(2400)` | R1 has no `ggsave` |
| Figure width / DPI | 8 in × 300 dpi = 2400 px | derived from the 2400-px convention | |
| Aspect ratio | Stata default 5.5 × 4 in (≈ 1.38) for single-panel figures; taller for stacked panels | Stata default graph size (S1/S2 do not override it) | |
| Additional format | PDF (requested in the brief; not in my earlier workflow) | — | |

## 2. Final decisions (author, 2026-09-28)

1. **Font:** **Arial Narrow** (S1 line 10, S2 line 213). Fallback where Arial Narrow is not installed: **Nimbus Sans Narrow** (metric-compatible). The published PNG/PDF files in `figures/` were rendered with the fallback, because Arial Narrow is not installed on the build machine; on a machine with Arial Narrow the same scripts use it automatically (`THESIS_FONT` in `00_theme_thesis.R`).
2. **No figure numbers and no thesis titles inside the graphics** (`show_title = FALSE`). Figure numbers and full captions are added in the thesis document, as in my R budget figure (R1 line 192, `plot.title = element_blank()`). The graphics keep only panel labels, axes, legends and the necessary methodological note.
3. **Unchanged:** the theme, font sizes, margins, line widths, point sizes and colours in §1. Only the font family changed. The note wrap width was widened from 108 to 128 characters so that notes in the narrower font fill the plot width (`NOTE_WIDTH`).

The table in §1 still lists `sans` as R1's choice; it is superseded for the thesis by decision 1.

## 3. What was deliberately not copied from the existing Python figures

DejaVu Sans 9-pt text, navy/blue `#1F4E79`/`#5B9BD5` palette, removed top/right spines, left-aligned `suptitle`, 220-dpi export. None of these appear in my own scripts.
