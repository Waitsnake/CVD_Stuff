# DCK17L – Difference-based Color Vision Deficiency Correction

## Introduction

DCK17L (**D**alton **C**orrection **K**oehler version**17** with **L**uminance preservation) is an experimental color vision deficiency (CVD) correction framework.

Unlike traditional daltonization methods, DCK17L does not directly modify colors based on predefined correction matrices. Instead, it analyzes the information loss predicted by a CVD simulation model and attempts to restore this lost information by enhancing color-channel differences.

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

DCK17L first computes the channel differences of both colors:

[
RG = R - G
]

[
RB = R - B
]

[
GB = G - B
]

for both the original and simulated color.

The information loss is then estimated as:

[
error_{RG} = RG_{original} - RG_{simulated}
]

[
error_{RB} = RB_{original} - RB_{simulated}
]

[
error_{GB} = GB_{original} - GB_{simulated}
]

These error values represent color contrast information that the simulation predicts would be lost for a viewer with the selected color vision deficiency.

---

## DCK17 Correction

The correction is applied directly to the RGB channels:

[
R' = R + error_{RG} + error_{RB}
]

[
G' = G - error_{RG} + error_{GB}
]

[
B' = B - error_{RB} - error_{GB}
]

The resulting color is then clamped into the valid RGB range.

Unlike earlier DCK16 variants, DCK17L uses the simulation error directly and therefore typically works well with fixed coefficients of 1.0.

---

## Luminance Preservation

A practical problem observed during testing was brightness overshoot.

Increasing color separation often increases overall luminance, resulting in unnatural and oversaturated images.

To compensate for this effect, DCK17L performs a luminance preservation step.

Luminance is calculated as:

[
Y =
0.2126R +
0.7152G +
0.0722B
]

The luminance difference between the corrected and original image is:

[
\Delta Y =
Y_{corrected} -
Y_{original}
]

This difference is subtracted equally from all channels:

[
RGB_{final}
===========

## RGB_{corrected}

(\Delta Y,\Delta Y,\Delta Y)
]

This simple step significantly improves visual stability and reduces brightness artifacts introduced by the correction process.

---

## DCK17L Is a Framework

DCK17L itself is not a color vision deficiency model.

Instead, it operates on the output of a simulation model.

The workflow is:

Original Image

↓

CVD Simulation

↓

Information Loss Estimation

↓

DCK17 Correction

↓

Luminance Preservation

↓

Final Image

Therefore, DCK17L can only be as accurate as the simulation model used to generate the information loss.

---

## Simulation Models

### Machado et al. (2009)

Machado provides continuous severity levels and tends to generate stronger color shifts.

In practice this often results in stronger DCK17L corrections and increased color separation.

Some users may prefer this behavior in applications where maximum distinguishability is desired.

### Viénot et al. (1999)

Viénot generally produces more conservative simulations.

For protan and deutan deficiencies it often preserves the appearance of unaffected colors more closely while concentrating the changes around confusion regions.

This usually results in weaker but potentially more realistic DCK17L corrections.

### Brettel et al. (1997)

For tritan deficiencies, Brettel's model is generally considered more accurate than the simplified Viénot approach and is therefore preferred.

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

---

## Status

DCK17L is currently an experimental method.

The implementation is released for public testing and evaluation.

Feedback from users with protan, deutan, and tritan color vision deficiencies is highly appreciated.
