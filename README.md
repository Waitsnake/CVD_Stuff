# DCK18L / DCK19L – Difference-based Color Vision Deficiency Correction

## Introduction

DCK18L (**D**alton **C**orrection **K**oehler version **18** with **L**uminance Preservation) is an experimental color vision deficiency (CVD) correction framework.

DCK18L is the successor of DCK17L and extends the original method with two stabilization stages:

* **Soft Compression (SC)**
* **Luminance Preservation (LP)**

DCK19L is an experimental extension that introduces:

* **Adaptive Luminance Preservation (ALP)**

Unlike traditional daltonization methods, DCK does not directly modify colors using predefined correction matrices. Instead, it analyzes the information loss predicted by a CVD simulation model and attempts to restore this lost information by enhancing color-channel differences.

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

DCK does not attempt to invent new colors.

It attempts to restore color contrast that the simulation predicts has become less distinguishable.

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

The correction directly follows the color differences lost according to the selected simulation model.

The resulting color is not immediately hard-clamped.

Instead, DCK applies additional stabilization stages.

---

## Soft Compression (SC)

Strong corrections can cause highly saturated colors to collapse into clipped regions.

For example:

```text
Original

A = (255, 0, 0)
B = (210, 0, 0)
C = (190, 0, 0)
```

contain visible surface differences.

A naive correction may push all three colors toward:

```text
A = (255, 0, 0)
B = (255, 0, 0)
C = (255, 0, 0)
```

destroying local contrast and surface detail.

Soft Compression reduces correction strength as channels approach their valid limits.

Conceptually:

```text
large distance to limit
→ almost full correction

small distance to limit
→ reduced correction
```

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
    stronger clipping protection
    but weaker color separation
```

SC is primarily intended as a safety mechanism.

---

## Luminance Preservation (LP)

Increasing color separation frequently increases luminance.

Without compensation, corrected images may appear unnaturally bright or oversaturated.

Luminance is calculated as:

```text
Y =
    0.2126 * R +
    0.7152 * G +
    0.0722 * B
```

The luminance difference becomes:

```text
deltaY =
    Ycorrected -
    Yoriginal
```

This difference is removed equally from all channels:

```text
RGBfinal =
    RGBcorrected -
    (deltaY, deltaY, deltaY)
```

Practical testing showed that LP not only stabilizes brightness but also helps preserve local detail in clipping-prone regions.

Typical values:

```text
0.0
    disabled

1.0
    recommended

>1.0
    stronger detail preservation
    but larger color shifts
```

---

## DCK19L – Adaptive Luminance Preservation (ALP)

DCK19L is an experimental extension of DCK18L.

Instead of applying a fixed LP strength everywhere, DCK19L estimates the amount of lost color separation.

The visibility metric is:

```text
visibility =
sqrt(
    errorRG² +
    errorRB² +
    errorGB²)
```

The value is normalized:

```text
visibility /= sqrt(3)
```

The adaptive LP strength becomes:

```text
adaptiveLP =
LP *
(1 + visibility)
```

Small corrections receive little additional LP.

Large corrections receive stronger LP.

The purpose is not stronger color separation.

The purpose is preserving detail in regions where strong corrections would otherwise collapse into clipping.

Practical observations suggest:

```text
DCK18L
→ higher color fidelity

DCK19L
→ stronger detail preservation
```

DCK19L can preserve surface structure in highly saturated regions that DCK18L may partially lose.

However, DCK19L can also increase color shifts.

Examples:

```text
red
→ pink

pink
→ magenta

pink
→ violet
```

Therefore DCK19L currently remains experimental.

DCK18L remains the recommended default algorithm.

---

## DCK Is a Framework

DCK itself is not a color vision deficiency simulation model.

Instead, it operates on the output of a simulation model.

DCK18L:

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

DCK19L:

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

Therefore DCK can only be as accurate as the simulation model used to generate the information loss.

The simulation model and correction algorithm are independent components.

Future simulation models can therefore be used without modifying the correction algorithm itself.

---

## Simulation Models

### Machado et al. (2009)

Machado provides physiologically motivated severity levels and generally produces stronger color shifts.

This often results in stronger DCK corrections and increased color separation.

### Viénot et al. (1999)

Viénot generally produces more conservative simulations.

For protan and deutan deficiencies it often preserves unaffected colors more closely and tends to produce weaker but visually natural corrections.

### Brettel et al. (1997)

Brettel remains one of the most influential and experimentally validated color vision deficiency simulation models.

For tritan deficiencies it is generally considered more accurate than simplified approaches.

Current tritan implementations therefore use Brettel-based simulation by default.

---

## Severity Calibration

The most important parameter is often not the correction algorithm itself but the severity used by the simulation model.

If severity is underestimated:

* information loss is underestimated
* correction becomes too weak

If severity is overestimated:

* information loss is exaggerated
* correction becomes too strong

Determining a realistic severity is therefore essential.

A correction can only be as good as the simulation model and severity setting on which it is based.

---

## Residual Color Information

DCK differs from many traditional daltonization methods.

Traditional daltonization often attempts to remap colors into alternative perceptual channels.

DCK instead attempts to increase the visibility of color information that still remains available.

This leads to an important limitation:

```text
No remaining information
→ no information to enhance
```

DCK therefore appears to operate as a residual color contrast enhancement method.

Its effectiveness may depend on how much color information remains available to the observer.

---

## Observations for Protan Deficiency

Practical observations using Viénot and Brettel simulations suggest that the amount of remaining red information may decrease substantially as severity increases.

For protan deficiencies, a possible interpretation is:

```text
severity 0.1 – 0.4
    substantial red information remains

severity 0.5 – 0.7
    red shifts toward reddish brown

severity 0.8 – 0.9
    red shifts toward greenish brown

severity 1.0
    little or no red information remains
```

This may explain why DCK can perform well for mild deficiencies while becoming less effective at very high severities.

However, these observations are currently limited to protan simulations and practical testing.

They should not be generalized to deutan or tritan deficiencies.

---

## Deutan and Tritan Limitations

The previous observations are currently specific to protan deficiencies.

Deutan deficiencies affect the medium-wavelength cone system and may behave differently.

Tritan deficiencies affect the short-wavelength cone system and may behave very differently.

The remaining amount of recoverable color information may therefore vary considerably between:

* protan
* deutan
* tritan

The severity ranges at which DCK becomes less effective may also differ.

At present there is insufficient user data to determine these limits.

---

## Potential Severity Dependence

DCK may work best when some residual color discrimination remains available.

For mild deficiencies this assumption may hold.

At very high severities the amount of remaining color information may become increasingly limited.

In such situations, approaches that intentionally remap colors into alternative perceptual channels may become more effective than approaches based primarily on contrast restoration.

This may imply:

```text
mild deficiency
→ DCK may be beneficial

moderate deficiency
→ effectiveness uncertain

severe deficiency
→ alternative approaches may be preferable
```

This hypothesis has not yet been validated through controlled user studies.

---

## Limitations

### Dependence on Simulation Accuracy

DCK does not claim to reproduce the exact perception of a specific observer.

The correction depends entirely on:

* simulation accuracy
* severity accuracy

Consequently:

```text
Correction Quality
        depends on
Simulation Accuracy
        and
Severity Accuracy
```

### Limited User Data

The current observations are primarily based on:

* practical use
* simulation experiments
* individual protan experiences

Large-scale user studies do not yet exist.

The effectiveness of DCK for:

* moderate protan deficiency
* severe protan deficiency
* deutan deficiency
* tritan deficiency

remains largely unknown.

Users should therefore not assume that DCK will necessarily improve their color perception.

---

## Status

DCK18L is currently the recommended implementation.

DCK19L remains experimental.

Feedback from users with:

* protanomaly
* protanopia
* deuteranomaly
* deuteranopia
* tritanomaly
* tritanopia

is highly appreciated.

Particular interest exists in:

* severity calibration
* simulation model comparisons
* moderate and severe deficiencies
* deutan testing
* tritan testing
* gaming applications
* desktop usage
* video applications
* real-world accessibility

The long-term goal is to explore whether simulation-error-based correction can provide a useful alternative to traditional daltonization methods while preserving as much of the original image appearance as possible.

---

## License

This project is released under the MIT License.