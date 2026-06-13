# DCK17L – Difference-based Color Vision Deficiency Correction

## Introduction

DCK17L (**D**alton **C**orrection **K**oehler version **17** with **L**uminance preservation) is an experimental color vision deficiency (CVD) correction framework.

Unlike traditional daltonization methods, DCK17L does not directly modify colors using predefined correction matrices. Instead, it analyzes the information loss predicted by a CVD simulation model and attempts to restore this lost information by enhancing color-channel differences.

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

In other words, DCK17L does not attempt to "invent" new colors. It attempts to restore color contrast that the simulation predicts has become less distinguishable.

---

## DCK17 Correction

The correction is applied directly to the RGB channels:

```text
R' = R + errorRG + errorRB
G' = G - errorRG + errorGB
B' = B - errorRB - errorGB
```

The resulting color is then clamped into the valid RGB range.

Unlike earlier DCK16 variants, DCK17L uses the simulation error directly and therefore typically works well with fixed coefficients of **1.0**.

This removes much of the manual tuning that was required in earlier RG/RB/GB expansion approaches.

---

## Luminance Preservation

A practical problem observed during testing was brightness overshoot.

Increasing color separation often increases overall luminance, resulting in unnatural and oversaturated images.

To compensate for this effect, DCK17L performs a luminance preservation step.

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

This simple step significantly improves visual stability and reduces brightness artifacts introduced by the correction process.

In practice, luminance preservation turned out to be an essential component of DCK17L. Without it, strong corrections frequently produced images that appeared unnaturally bright or visually unstable.

---

## DCK17L Is a Framework

DCK17L itself is **not** a color vision deficiency simulation model.

Instead, it operates on the output of a simulation model.

The workflow is:

```text
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
```

Therefore, DCK17L can only be as accurate as the simulation model used to generate the information loss.

This separation is intentional.

The correction algorithm and the simulation model are independent components. Improvements in future simulation models can therefore be used by DCK17L without changing the correction method itself.

---

## Simulation Models

### Machado et al. (2009)

Machado provides continuous severity levels and generally produces stronger color shifts.

In practice this often results in stronger DCK17L corrections and increased color separation.

Some users may prefer this behavior in applications where maximum distinguishability is desired, such as syntax highlighting, user interfaces, or accessibility-focused workflows.

### Viénot et al. (1999)

Viénot generally produces more conservative simulations.

For protan and deutan deficiencies it often preserves the appearance of unaffected colors more closely while concentrating changes around confusion regions.

This usually results in weaker but potentially more realistic DCK17L corrections.

### Brettel et al. (1997)

For tritan deficiencies, Brettel's model is generally considered more accurate than the simplified Viénot approach and is therefore preferred.

Current DCK17L tritan implementations use Brettel-based simulation by default.

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

For many users, finding the correct severity may have a larger impact on the final result than switching between different correction algorithms.

---

## Limitations

DCK17L does not claim to reproduce the exact perception of a specific observer.

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

DCK17L should therefore be viewed as a correction framework built on top of existing CVD simulation models rather than a standalone model of color perception.

---

## Status

DCK17L is currently an experimental method.

The implementation is released for public testing and evaluation.

Feedback from users with protan, deutan, and tritan color vision deficiencies is highly appreciated.

Particular interest exists in testing:

* different simulation models
* severity calibration methods
* protan, deutan, and tritan variants
* real-world usability in desktop environments, gaming, and mobile applications

The long-term goal is to explore whether simulation-error-based correction can provide a useful alternative to traditional daltonization approaches.

## License

This project is released under the MIT License.
