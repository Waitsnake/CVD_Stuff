# DCK18L / DCK19L – Difference-based Color Vision Deficiency Correction

## Introduction

DCK18L (**D**alton **C**orrection **K**oehler version **18** with **L**uminance Preservation) is an experimental color vision deficiency (CVD) correction framework.

DCK18L is the successor of DCK17L and extends the original method with two stabilization stages:

* **Soft Compression (SC)**
* **Luminance Preservation (LP)**

Unlike traditional daltonization methods, DCK18L does not directly modify colors using predefined correction matrices. Instead, it analyzes the information loss predicted by a CVD simulation model and attempts to restore this lost information by enhancing color-channel differences.

The method is intentionally independent from any specific CVD simulation model.

Current implementations use:

* Machado et al. (2009)
* Viénot et al. (1999)
* Brettel et al. (1997) for tritan simulations

but any future simulation model could theoretically be used.

---

## Core Idea

Let

* **rgb** be the original color
* **simulated** be the color predicted by a CVD simulation

DCK first computes the channel differences of both colors:

```text
RG = R - G
RB = R - B
GB = G - B
```

for both the original and simulated color.

The information loss is then estimated as:

```text
errorRG = RGoriginal - RGsimulated
errorRB = RBoriginal - RBsimulated
errorGB = GBoriginal - GBsimulated
```

These error values represent color contrast information that the simulation predicts would be lost for a viewer with the selected color vision deficiency.

In other words, DCK does not attempt to invent new colors. It attempts to restore color contrast that the simulation predicts has become less distinguishable.

---

## DCK Correction

The correction is applied directly to the RGB channels:

```text
R' = R + errorRG * dckRG + errorRB * dckRB

G' = G - errorRG * dckRG + errorGB * dckGB

B' = B - errorRB * dckRB - errorGB * dckGB
```

Typical values are:

```text
dckRG = 1.0
dckRB = 1.0
dckGB = 1.0
```

The correction is intentionally simple and directly follows the color differences lost according to the selected simulation model.

The resulting color is not immediately hard-clamped.

Instead, DCK18L applies Soft Compression first.

---

## Soft Compression (SC)

During practical testing, a major limitation of DCK17L became apparent.

Strong corrections often caused highly saturated colors to collapse into clipped regions.

For example:

```text
Original

A = (255, 0, 0)
B = (210, 0, 0)
C = (190, 0, 0)
```

contain visible surface differences.

A naive correction may push all three colors towards the same channel limit:

```text
A = (255, 0, 0)
B = (255, 0, 0)
C = (255, 0, 0)
```

destroying local contrast and surface detail.

Current DCK18L versions use a distance-dependent Soft Compression model.

The correction applied to each channel is gradually reduced as the channel approaches its valid range limit.

Conceptually:

```text
large distance to limit
→ almost full correction

small distance to limit
→ reduced correction
```

This allows DCK18L to preserve color separation in most of the image while reducing the risk of local saturation collapse.

The amount of compression is controlled by:

```text
scStrength
```

Typical values:

```text
0.0
    disabled

1.0
    default

>1.0
    stronger protection against clipping
    but weaker color separation
```

SC is primarily intended as a safety mechanism.

Excessively large values may reduce the very color differences that DCK18L attempts to recover.

---

## Luminance Preservation (LP)

Practical testing revealed that Soft Compression alone is often insufficient to preserve local image detail in strongly saturated regions.

Increasing color separation frequently increases overall luminance.

Without compensation, corrected images can appear unnaturally bright and oversaturated.

Luminance is calculated as:

```text
Y =
    0.2126 * R +
    0.7152 * G +
    0.0722 * B
```

The luminance difference between the corrected and original image is:

```text
deltaY = Ycorrected - Yoriginal
```

This difference is subtracted equally from all channels:

```text
RGBfinal =
    RGBcorrected -
    (deltaY, deltaY, deltaY)
```

Although originally introduced as a luminance stabilization stage, practical testing showed that LP also helps preserve local detail in clipping-prone regions.

In many real-world situations LP has proven to be at least as important as Soft Compression for maintaining natural-looking results.

Typical values:

```text
0.0
    disabled

1.0
    recommended

>1.0
    stronger detail preservation
    but increased color shifts
```

---

## DCK19L – Adaptive Luminance Preservation (ALP)

DCK19L is an experimental extension of DCK18L.

It retains the DCK18L correction stage and Soft Compression stage but replaces fixed Luminance Preservation with an Adaptive Luminance Preservation (ALP) model.

The motivation is simple:

```text
small information loss
→ standard LP

large information loss
→ stronger LP
```

Instead of using a fixed LP strength everywhere, DCK19L estimates the visibility of lost color information:

```text
visibility =
sqrt(
    errorRG² +
    errorRB² +
    errorGB²)
```

The value is normalized by:

```text
sqrt(3)
```

and used to increase LP strength adaptively:

```text
adaptiveLP =
LP *
(1 + visibility)
```

The goal is not to create stronger color separation but to preserve local image detail in regions where severe corrections would otherwise collapse into clipped colors.

Practical testing has shown:

```text
DCK18L
→ higher color fidelity

DCK19L
→ stronger detail preservation
```

Especially in highly saturated red regions, DCK19L may preserve surface structure that DCK18L partially loses.

However, DCK19L may also introduce larger color shifts than DCK18L.

For example:

```text
red
→ pink

pink
→ magenta/violet
```

at high correction strengths.

For this reason DCK19L should currently be regarded as experimental.

DCK18L remains the recommended default algorithm.

---

## DCK Is a Framework

DCK itself is not a color vision deficiency simulation model.

Instead, it operates on the output of a simulation model.

DCK18L workflow:

```text
Original Image
↓
CVD Simulation
↓
Information Loss Estimation
↓
DCK Correction
↓
Soft Compression
↓
Luminance Preservation
↓
Final Image
```

DCK19L workflow:

```text
Original Image
↓
CVD Simulation
↓
Information Loss Estimation
↓
DCK Correction
↓
Soft Compression
↓
Adaptive Luminance Preservation
↓
Final Image
```

Therefore, DCK can only be as accurate as the simulation model used to generate the information loss.

The correction algorithm and simulation model are independent components.

Future simulation models can therefore be used without modifying the correction algorithm itself.

---

## Simulation Models

### Machado et al. (2009)

Machado provides physiologically motivated severity levels and generally produces stronger color shifts.

In practice this often results in stronger DCK corrections and increased color separation.

Some users may prefer this behavior in accessibility-focused workflows or situations where maximum distinguishability is desired.

### Viénot et al. (1999)

Viénot generally produces more conservative simulations.

For protan and deutan deficiencies it often preserves unaffected colors more closely and tends to produce weaker but visually natural corrections.

### Brettel et al. (1997)

Brettel remains one of the most influential and experimentally validated color vision deficiency simulation models.

For tritan deficiencies it is generally considered more accurate than simplified approaches and is therefore preferred.

Current DCK tritan implementations use Brettel-based simulation by default.

---

## Severity Calibration

The most important parameter is often not the correction algorithm itself but the severity used by the simulation model.

If severity is underestimated:

* information loss is underestimated
* correction becomes too weak

If severity is overestimated:

* information loss is exaggerated
* correction becomes too strong

Determining a realistic severity for an individual user is therefore essential.

A correction can only be as good as the simulation model and severity setting on which it is based.

In many practical situations, severity calibration has a larger impact on the final result than switching between different correction algorithms.

---

## Limitations

### Dependence on Simulation Accuracy

DCK does not claim to reproduce the exact perception of a specific observer.

The algorithm assumes that the selected simulation model and severity level provide a reasonable approximation of the user's color vision deficiency.

Any inaccuracies in the simulation model will directly affect the correction result.

Consequently:

```text
Correction Quality
        depends on
Simulation Accuracy
        and
Severity Accuracy
```

DCK should therefore be viewed as a correction framework built on top of existing CVD simulation models rather than a standalone model of color perception.

### Potential Severity Dependence

DCK differs from many traditional daltonization approaches in an important way.

Rather than remapping colors into alternative perceptual channels, DCK attempts to enhance color-difference information that is predicted to be reduced by a color vision deficiency simulation.

The method therefore operates on the assumption that at least some of the original color information remains available to the observer.

For mild and moderate forms of color vision deficiency, this assumption may be valid.

However, the behavior at higher severity levels remains unclear.

If a large portion of the original color information collapses into similar perceptual categories, the amount of recoverable information may become increasingly limited.

In such situations, approaches that intentionally remap colors into alternative perceptual channels may prove more effective than approaches based primarily on contrast restoration.

A useful way to view DCK is therefore not as a color replacement algorithm, but as a color contrast reconstruction algorithm.

Its effectiveness may depend on how much residual color discrimination remains available to the observer.

This hypothesis is currently based on practical observations and simulation experiments and has not yet been validated through controlled user studies.

---

## Status

DCK18L is currently the recommended implementation.

DCK19L is currently experimental.

The implementation is released for public testing and evaluation.

Feedback from users with protan, deutan, and tritan color vision deficiencies is highly appreciated.

Particular interest exists in testing:

* different simulation models
* severity calibration methods
* protan, deutan, and tritan variants
* DCK coefficients
* Soft Compression settings
* Luminance Preservation settings
* Adaptive Luminance Preservation behavior
* real-world usability in desktop environments, gaming, and mobile applications

The long-term goal is to explore whether simulation-error-based correction can provide a useful alternative to traditional daltonization approaches.

---

## License

This project is released under the MIT License.
