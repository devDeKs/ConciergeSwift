# Concierge Finance - Brand Guidelines

## Brand Identity

**Concierge Finance** is a premium financial assistant that combines the elegance of luxury concierge services with cutting-edge fintech capabilities.

---

## Logo

The logo combines a stylized **"C"** monogram with a **concierge bell** icon, representing personalized financial service with luxury hospitality.

### Symbol Meaning
- **C Monogram**: Represents "Concierge" and creates brand recognition
- **Bell Icon**: Classic concierge service symbol
- **Upward Elements**: Growth and financial prosperity

### Logo Variations
- **Primary**: Gold on dark background
- **Reverse**: Dark on light background
- **Monochrome**: Single color applications

---

## Color Palette

### Primary Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Midnight** | `#020410` | rgb(2, 4, 16) | Primary background |
| **Midnight Light** | `#0B1021` | rgb(11, 16, 33) | Secondary surfaces |
| **Gold** | `#B4975A` | rgb(180, 151, 90) | Primary accent |
| **Gold Light** | `#D6C08D` | rgb(214, 192, 141) | Highlights |
| **Gold Dark** | `#7D6635` | rgb(125, 102, 53) | Shadows, depth |

### Secondary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Midnight Accent** | `#182245` | Cards, containers |
| **Success** | `#10B981` | Positive values, income |
| **Danger** | `#EF4444` | Negative values, expenses |
| **Info** | `#3B82F6` | Informational elements |

### Gradients

```css
/* Gold Gradient */
background: linear-gradient(135deg, #D6C08D 0%, #B4975A 50%, #7D6635 100%);

/* Text Gold Gradient */
background: linear-gradient(to bottom right, #D6C08D, #B4975A, #7D6635);
-webkit-background-clip: text;
color: transparent;
```

---

## Typography

### Primary Font
**Playfair Display** - Headings, hero text
- Elegant serif with premium feel
- Use for impactful statements

### Secondary Font
**Geist Sans** - Body text, UI elements
- Modern, clean sans-serif
- Excellent readability

### Font Scale
| Element | Size | Weight |
|---------|------|--------|
| Hero Title | 2.5rem - 3rem | 700 |
| Section Title | 1.5rem | 600 |
| Body | 1rem | 400 |
| Caption | 0.75rem | 500 |
| Micro | 0.625rem | 500 |

---

## Design Principles

### 1. Premium Minimalism
- Clean layouts with generous whitespace
- Subtle shadows and blur effects
- Restrained use of color

### 2. Dark Mode First
- Primary experience is dark themed
- Easier on eyes for financial data
- Premium, modern aesthetic

### 3. Subtle Animation
- Smooth transitions (300-500ms)
- Easing: `cubic-bezier(0.25, 1, 0.5, 1)`
- Never jarring or distracting

### 4. Glassmorphism
- Frosted glass effects
- `backdrop-filter: blur(20px)`
- Semi-transparent surfaces

---

## UI Components

### Buttons
```css
/* Primary Button */
background: #B4975A;
color: #020410;
border-radius: 0.5rem;
box-shadow: 0 0 20px -5px rgba(180, 151, 90, 0.4);
```

### Cards
```css
/* Glass Card */
background: rgba(24, 34, 69, 0.5);
backdrop-filter: blur(20px);
border: 1px solid rgba(255, 255, 255, 0.05);
border-radius: 0.75rem;
```

### Inputs
```css
/* Form Input */
background: rgba(24, 34, 69, 0.3);
border: 1px solid rgba(255, 255, 255, 0.1);
border-radius: 1rem;
```

---

## Spacing System

Based on 4px grid:
- `xs`: 4px
- `sm`: 8px
- `md`: 16px
- `lg`: 24px
- `xl`: 32px
- `2xl`: 48px

---

## Voice & Tone

### Personality
- **Sophisticated** but approachable
- **Confident** without arrogance
- **Helpful** like a trusted advisor
- **Modern** with timeless quality

### Writing Style
- Clear, concise language
- Professional but friendly
- Action-oriented
- Avoid jargon when possible

---

## App Icon

The app icon uses the simplified C+Bell monogram:
- Deep midnight blue background (`#020410`)
- Gold symbol (`#B4975A`)
- Generous padding for maskable icon compliance
- Works at all sizes from 16px to 512px

---

## Safe Area & Minimum Size

- **Logo minimum size**: 32px height
- **Clear space**: Equal to the height of the bell top
- **App icon safe zone**: 20% padding from edges

---

*Last updated: January 2026*
