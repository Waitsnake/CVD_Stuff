# Current State of CVD Research – A Practical Perspective

## Overview

During the development of DCK17L and DCK18L, a large number of color vision deficiency (CVD) papers were reviewed, ranging from early perceptual models to modern physiological simulations.

An unexpected observation emerged:

Despite decades of research activity, there appear to be very few practically usable advances in real-time color vision deficiency simulation since the publication of Machado et al. (2009).

Today, most publicly available software still relies on one of three model families:

* Brettel et al. (1997)
* Viénot et al. (1999)
* Machado et al. (2009)

These models continue to dominate tools such as DaltonLens, Color Oracle, Vischeck-derived implementations, GIMP display filters, and many web-based simulators.

---

## Historical Development

### Brettel et al. (1997)

Brettel remains one of the most influential CVD simulation models ever published.

The model was developed and validated using observations from actual dichromats and introduced the confusion-plane approach that remains a reference today.

It is also one of the few widely adopted methods that provides reasonable tritan simulation.

### Viénot et al. (1999)

Viénot simplified Brettel's approach to reduce computational cost.

The resulting model became popular because it provides very similar results for protan and deutan simulation while being easier to implement and faster to execute.

Many modern implementations are still based on this simplification.

### Machado et al. (2009)

Machado introduced a physiologically motivated model capable of simulating anomalous trichromacy through continuous severity levels.

This represented the last major practical advance that became widely implemented in software.

To this day, Machado remains the most commonly used model whenever adjustable severity is required.

---

## Modern Research

The literature after 2009 does not indicate a similar practical breakthrough.

Instead, research increasingly focuses on physiological accuracy.

Examples include:

* Yaguchi et al. (2018)
* Sun et al. (2025)

These works attempt to model color vision deficiency at a deeper biological level using:

* photopigment absorption curves
* cone spectral sensitivities
* observer models
* multispectral image data

The scientific depth is impressive.

However, these approaches generally require information that is unavailable in normal digital images.

Typical image-processing applications only have access to:

```text
RGB
```

whereas many modern physiological models require:

```text
Spectral Radiance
for every pixel
```

or detailed observer-specific parameters.

As a result, these methods are difficult to deploy in real-world software such as:

* desktop accessibility filters
* games
* browsers
* video players
* GPU shaders

No widely adopted open-source RGB-to-RGB implementation comparable to Brettel, Viénot, or Machado appears to have emerged from this research direction.

---

## Open Science vs. Practical Availability

Another surprising observation is that many modern papers describe sophisticated simulation theories but do not provide practical reference implementations.

In several cases:

* source code is unavailable
* implementation details are incomplete
* models depend on multispectral data
* papers are behind paywalls

Consequently, the gap between scientific research and deployable software remains large.

A model may be scientifically superior while simultaneously being unusable for real-time accessibility applications.

---

## Daltonization Research

An even more surprising finding is the relative lack of research on correction methods.

Most published work focuses on:

```text
How does a color deficient observer see the image?
```

rather than:

```text
How can the image be modified to improve perception?
```

Simulation receives the overwhelming majority of attention.

Correction methods are comparatively rare and often rely on:

* heuristic color shifts
* fixed transformation matrices
* saturation modifications

Few modern works appear to investigate simulation-error-driven correction approaches.

---

## Practical Situation in 2026

From a practical software engineering perspective, the state of the field can be summarized as:

### Simulation

Widely used models:

* Brettel 1997
* Viénot 1999
* Machado 2009

Newer physiological models exist but have not yet produced broadly adopted open RGB-based implementations.

### Correction

No dominant modern correction framework exists.

Most existing daltonization approaches remain variations of ideas that are already many years old.

Compared to simulation research, correction research appears significantly less active.

---

## Conclusion

The current CVD research landscape presents an unusual situation.

Scientific understanding of color vision deficiencies continues to improve through increasingly sophisticated physiological models.

However, many of these advances have not translated into practical, open, real-time algorithms suitable for everyday software.

As a result, most current accessibility tools still rely on simulation models developed between 1997 and 2009.

At the same time, there appears to be relatively little research effort dedicated to improving correction and compensation methods for affected users.

This suggests that practical color vision accessibility remains an area where significant experimentation and innovation may still be possible.
