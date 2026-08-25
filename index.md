---
---

<script>
window.MathJax = {
  tex: { inlineMath: [['$', '$'], ['\\(', '\\)']], displayMath: [['$$', '$$'], ['\\[', '\\]']] },
  svg: { fontCache: 'global' }
};
</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>

<style>
  .project-hero { padding: 2rem; margin: 1rem 0 2rem; border-radius: 18px; background: linear-gradient(135deg, #082f49 0%, #0369a1 62%, #0891b2 100%); color: #fff; }
  .project-hero h1 { margin: 0 0 .5rem; color: #fff; border: 0; }
  .project-hero p { margin: .35rem 0; }
  .project-meta { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: .75rem; margin-top: 1.4rem; }
  .project-meta div { padding: .75rem .9rem; border: 1px solid rgba(255,255,255,.22); border-radius: 12px; background: rgba(255,255,255,.08); }
  .project-meta strong { display: block; color: #e0f2fe; font-size: .78rem; text-transform: uppercase; letter-spacing: .05em; }
  .project-meta a { color: #fff; text-decoration: underline; }
  .project-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; align-items: stretch; }
  .project-card { padding: 1rem; border: 1px solid #dbeafe; border-radius: 14px; background: #f8fafc; }
  .project-card h3 { margin-top: 0; }
  .project-figure { margin: 1.5rem auto; text-align: center; }
  .project-figure img { max-width: 100%; height: auto; border-radius: 12px; box-shadow: 0 10px 28px rgba(15,23,42,.12); }
  .project-figure figcaption { max-width: 780px; margin: .7rem auto 0; color: #475569; font-size: .92rem; line-height: 1.45; }
  .project-photo-row { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; align-items: start; }
  .project-photo-row figure { margin: 0; }
  .project-photo-row img { width: 100%; aspect-ratio: 4 / 3; object-fit: cover; border-radius: 12px; }
  .project-note { padding: 1rem 1.1rem; margin: 1.2rem 0; border-left: 4px solid #0284c7; border-radius: 0 10px 10px 0; background: #f0f9ff; }
  @media (max-width: 680px) { .project-hero { padding: 1.3rem; } .project-grid, .project-photo-row { grid-template-columns: 1fr; } }
</style>

<section class="project-hero">
  <h1>Contactless Vital-Sign Detection with 60 GHz FMCW Radar</h1>
  <p>From raw radar samples to breathing- and heart-rate estimation through range selection and phase-based micro-motion analysis.</p>
  <div class="project-meta">
    <div><strong>Project period</strong>October 2025 – January 2026</div>
    <div><strong>Institution</strong>ENSEA, France</div>
    <div><strong>Supervisor</strong><a href="https://www.etis-lab.fr/2023/01/11/chen-luan/" target="_blank" rel="noopener noreferrer">Dr. Luan Chen</a></div>
    <div><strong>Platform</strong>TI IWR6843ISK, 60–64 GHz</div>
  </div>
</section>

## Project at a glance

This project investigates how a frequency-modulated continuous-wave (FMCW) radar can recover the small chest displacements caused by breathing and cardiac activity without attaching a sensor to the subject. The work combines radar configuration, data acquisition, range-domain processing, phase extraction, and spectral estimation.

<div class="project-grid">
  <div class="project-card">
    <h3>Research question</h3>
    <p>Can a 60 GHz FMCW radar isolate a subject in range and track sub-millimetre chest motion well enough to estimate respiratory and cardiac periodicity?</p>
  </div>
  <div class="project-card">
    <h3>What we implemented</h3>
    <p>A processing workflow built around range FFT, target-bin selection, phase unwrapping, static/DC compensation, detrending, filtering, and slow-time spectral analysis.</p>
  </div>
</div>

<figure class="project-figure">
  <img src="./images/Luan_Breath.png" alt="Illustration of chest displacement during inhalation and exhalation relative to the radar">
  <figcaption><strong>Figure 1.</strong> Contactless sensing principle: inhalation and exhalation change the radar-to-chest distance, producing a measurable phase variation in the reflected signal.</figcaption>
</figure>

## Experimental platform and workflow

The setup used a Texas Instruments IWR6843ISK mmWave evaluation board connected to a computer for configuration, acquisition, and visualization. The subject remained in front of the radar while the system selected the dominant range bin and tracked its phase over successive chirps.

<div class="project-photo-row">
  <figure class="project-figure">
    <img src="./images/IWR6843ISK.jpg" alt="Texas Instruments IWR6843ISK radar board used in the project">
    <figcaption><strong>(a)</strong> IWR6843ISK radar platform.</figcaption>
  </figure>
  <figure class="project-figure">
    <img src="./images/Experiment_frame.png" alt="Experimental arrangement for radar vital-sign monitoring">
    <figcaption><strong>(b)</strong> Measurement geometry and subject placement.</figcaption>
  </figure>
</div>

<figure class="project-figure">
  <img src="./images/Proposed signal processing chain of the vital signs detection.png" alt="Signal-processing chain from beat signal to vital-rate estimation">
  <figcaption><strong>Figure 2.</strong> Processing chain used to transform the sampled beat signal into a vital-rate estimate.</figcaption>
</figure>

## 1. FMCW measurement model

For one linear chirp, the transmitted complex signal can be written as

$$
s_{\mathrm{tx}}(t)=A_{\mathrm{tx}}\exp\!\left[j\left(2\pi f_0t+\pi Kt^2\right)\right],
$$

where $f_0$ is the start frequency and $K$ is the chirp slope. A target at time-varying range $R(t)=R_0+x(t)$ introduces the round-trip delay

$$
\tau(t)=\frac{2R(t)}{c}.
$$

After mixing the received echo with the transmitted signal and neglecting small higher-order terms, the beat signal contains two useful components:

$$
y(t)\approx A\exp\!\left[j\left(2\pi f_b t+\frac{4\pi}{\lambda}x(t)+\phi_0\right)\right],
\qquad f_b\approx\frac{2KR_0}{c}.
$$

The beat frequency $f_b$ provides range information, while the slow-time phase term $4\pi x(t)/\lambda$ encodes the chest displacement.

<figure class="project-figure">
  <img src="./images/Block_diagram_of_an_FMCW_radar.png" alt="FMCW radar transmitter, propagation path, receiver, mixer, and intermediate-frequency signal">
  <figcaption><strong>Figure 3.</strong> Simplified FMCW radar architecture and generation of the intermediate-frequency beat signal.</figcaption>
</figure>

### Why 60 GHz?

Near the 62 GHz centre of the IWR6843ISK operating band, the wavelength is approximately 4.8 mm. A displacement $\Delta x$ produces a round-trip phase change

$$
\Delta\phi=\frac{4\pi\Delta x}{\lambda}.
$$

Thus, a 0.1 mm chest displacement corresponds to roughly 0.26 rad (15°) of phase change. This phase sensitivity—not the range resolution alone—is what makes the radar useful for micro-motion sensing. Range processing is still essential because it separates the subject from reflections at other distances.

## 2. From fast time to slow time

1. **Range FFT (fast time).** For every chirp, an FFT across ADC samples produces a complex range profile.
2. **Target-bin selection.** The range bin associated with the subject is selected using its energy and expected position.
3. **Phase extraction (slow time).** The complex value of that bin is tracked across chirps: $\phi[m]=\arg\{Z[k_0,m]\}$.
4. **Phase conditioning.** Phase unwrapping removes $2\pi$ discontinuities; DC/static compensation and detrending reduce offsets and slow drift.
5. **Rate estimation.** Filtering and spectral analysis identify periodic components in the respiratory and cardiac frequency bands.

<figure class="project-figure">
  <img src="./images/bin_chirp.png" alt="Two-dimensional organization of ADC samples and chirps for fast-time and slow-time processing">
  <figcaption><strong>Figure 4.</strong> Data organization: the range FFT operates across samples within each chirp; micro-motion analysis follows the selected range bin across chirps.</figcaption>
</figure>

## 3. Implementation and experiment

The most important practical difficulty is that the desired cardiac motion is much weaker than respiration, posture changes, and static leakage. The implementation therefore treats preprocessing as part of the estimator rather than as a cosmetic cleanup step.

<div class="project-grid">
  <div class="project-card"><h3>Phase unwrapping</h3><p>Restores continuity when the measured phase crosses the $-\pi$/$\pi$ boundary.</p></div>
  <div class="project-card"><h3>Static/DC compensation</h3><p>Reduces the complex offset produced by stationary reflectors and receiver leakage.</p></div>
  <div class="project-card"><h3>Detrending and filtering</h3><p>Suppresses baseline drift and separates respiratory and cardiac frequency regions.</p></div>
  <div class="project-card"><h3>Spectral peak selection</h3><p>Maps the dominant slow-time frequency to breaths per minute or beats per minute.</p></div>
</div>

<div class="project-photo-row" style="margin-top:1.5rem">
  <figure class="project-figure">
    <img src="./images/Hong_Presentation.jpg" alt="Hong Chen explaining the FMCW chirp model on a whiteboard during the ENSEA project">
    <figcaption><strong>(a)</strong> Deriving the FMCW chirp model during the project at ENSEA.</figcaption>
  </figure>
  <figure class="project-figure">
    <img src="./images/Ewan_taked.jpeg" alt="Radar hardware and TI vital-sign visualization in the ENSEA laboratory">
    <figcaption><strong>(b)</strong> Laboratory setup with live radar visualization.</figcaption>
  </figure>
</div>

## 4. Observed output and interpretation

<figure class="project-figure">
  <img src="./images/screenshot_TI_Visualizer.png" alt="Texas Instruments visualizer displaying radar vital-sign waveforms and estimated rates">
  <figcaption><strong>Figure 5.</strong> Example output from the TI visualizer during acquisition, including range selection and vital-sign waveforms.</figcaption>
</figure>

The experiment demonstrated the complete acquisition-to-estimation workflow and showed that breathing-induced motion is clearly observable in the selected-bin phase. Cardiac-rate extraction is more sensitive to body motion, subject orientation, range-bin stability, and filter settings.

<div class="project-note">
  <strong>Interpretation boundary.</strong> The figures document a working engineering prototype; they do not by themselves establish clinical accuracy. A stronger validation would require synchronized reference measurements, repeated trials across subjects and distances, and quantitative error metrics such as MAE, RMSE, and Bland–Altman limits of agreement.
</div>

## 5. Conclusions and next steps

The project confirms the physical and algorithmic feasibility of contactless vital-sign sensing with a 60 GHz FMCW radar. The key insight is that range FFT localizes the subject, while slow-time phase reveals micro-motion at a sensitivity much finer than the nominal range resolution.

Recommended next steps are to:

- automate stable target-bin tracking when the subject moves;
- evaluate respiratory and cardiac estimates against a synchronized reference sensor;
- report performance across multiple subjects, ranges, and orientations;
- quantify confidence or signal quality instead of returning a rate for every frame;
- package acquisition parameters and processing settings into a reproducible configuration.

<p style="margin-top:2rem;color:#64748b;font-size:.9rem">Completed at École Nationale Supérieure de l'Électronique et de ses Applications (ENSEA), France, under the supervision of <a href="https://www.etis-lab.fr/2023/01/11/chen-luan/" target="_blank" rel="noopener noreferrer">Dr. Luan Chen</a>.</p>
