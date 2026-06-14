# DCK18L – Difference-based Color Vision Deficiency Correction

## Introduction

DCK18L (**D**alton **C**orrection **K**oehler version **18** with **L**uminance preservation) is an experimental color vision deficiency (CVD) correction framework.

DCK18L is the successor of DCK17L and extends the original method with an additional **Soft Compression (SC)** stage designed to reduce saturation clipping while preserving local image detail.

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

DCK18L first computes the channel differences of both colors:

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

In other words, DCK18L does not attempt to invent new colors. It attempts to restore color contrast that the simulation predicts has become less distinguishable.

---

## DCK18 Correction

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

Strong corrections often caused highly saturated colors to collapse into large clipped regions.

For example:

```text
Original

A = (255, 0, 0)
B = (210, 0, 0)
C = (190, 0, 0)
```

contain visible surface differences.

After aggressive correction and hard clamping:

```text
A = (255, 0, 0)
B = (255, 0, 0)
C = (255, 0, 0)
```

all detail is lost.

This effect was especially visible in:

* red clothing
* red vehicles
* red logos
* shaded red surfaces

DCK18L therefore introduces Soft Compression.

Instead of clipping channels independently, all RGB channels are scaled proportionally whenever one channel exceeds the valid range.

Example:

```text
Before:

(1.20, 1.10, 0.90)

Hard Clamp:

(1.00, 1.00, 0.90)

Soft Compression:

(1.00, 0.92, 0.75)
```

This preserves relative color relationships and helps retain local contrast and image structure.

In practice, Soft Compression significantly improves visual quality for real-world images.

---

## Luminance Preservation (LP)

Increasing color separation often increases overall luminance.

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

Luminance Preservation greatly improves image stability and reduces brightness artifacts.

Although disabling LP may improve some color-vision test scores, LP generally produces more natural-looking results for photographs, videos, desktop environments, and everyday use.

---

## DCK18L Is a Framework

DCK18L itself is **not** a color vision deficiency simulation model.

Instead, it operates on the output of a simulation model.

The workflow is:

```text
Original Image
↓
CVD Simulation
↓
Information Loss Estimation
↓
DCK18 Correction
↓
Soft Compression
↓
Luminance Preservation
↓
Final Image
```

Therefore, DCK18L can only be as accurate as the simulation model used to generate the information loss.

The correction algorithm and the simulation model are independent components.

Future simulation models can therefore be used by DCK18L without modifying the correction algorithm itself.

---

## Simulation Models

### Machado et al. (2009)

Machado provides physiologically motivated severity levels and generally produces stronger color shifts.

In practice this often results in stronger DCK18L corrections and increased color separation.

Some users may prefer this behavior in accessibility-focused workflows or situations where maximum distinguishability is desired.

### Viénot et al. (1999)

Viénot generally produces more conservative simulations.

For protan and deutan deficiencies it often preserves unaffected colors more closely and tends to produce weaker but visually natural corrections.

### Brettel et al. (1997)

Brettel remains one of the most influential and experimentally validated color vision deficiency simulation models.

For tritan deficiencies it is generally considered more accurate than simplified approaches and is therefore preferred.

Current DCK18L tritan implementations use Brettel-based simulation by default.

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

DCK18L does not claim to reproduce the exact perception of a specific observer.

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

DCK18L should therefore be viewed as a correction framework built on top of existing CVD simulation models rather than a standalone model of color perception.

---

## Status

DCK18L is currently an experimental method.

The implementation is released for public testing and evaluation.

Feedback from users with protan, deutan, and tritan color vision deficiencies is highly appreciated.

Particular interest exists in testing:

* different simulation models
* severity calibration methods
* protan, deutan, and tritan variants
* DCK coefficients
* real-world usability in desktop environments, gaming, and mobile applications

The long-term goal is to explore whether simulation-error-based correction can provide a useful alternative to traditional daltonization approaches.

---

## License

This project is released under the MIT License.
