# study

Small visualizers and calculators made for automotive and ham radio classes. Python 3, one file each.

| Script | Subject | Needs |
|---|---|---|
| [`pwm_signal_gui.py`](pwm_signal_gui.py) | Automotive: PWM signals | tkinter |
| [`python_phasor_pm.py`](python_phasor_pm.py) | Ham radio: phase modulation | matplotlib |
| [`fuel_injection_calc.py`](fuel_injection_calc.py) | Automotive: fuel per stroke | — |

---

## pwm_signal_gui.py

An oscilloscope-style live square wave with adjustable frequency and duty cycle, to see how each one changes the
signal as you move it. Built for an automotive class.

```bash
python study/pwm_signal_gui.py
```

## python_phasor_pm.py

A rotating phasor next to its time-domain waveform, with live sliders for carrier frequency, message frequency,
modulation index and playback speed, plus play/pause and reset. Goes with the
[Ham Extra learner manual](https://logannightingale.com/papers/ham-radio-math.pdf).

```bash
python study/python_phasor_pm.py
```

## fuel_injection_calc.py

Asks for fuel type (diesel or gasoline, each with a default BSFC), cylinder count, power and engine speed, then reports
fuel mass and volume per stroke and the total rate in g/min and kg/h, for 4-stroke engines.

```bash
python study/fuel_injection_calc.py
```
