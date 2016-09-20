# Notes on Second Order Filters #


If w is the center/cutoff frequency, and Q is the quality factor, then:

Denominator is always `s^2 + w/Q * s + w^2`

| Type     | Numerator   |
| ---      | ---         |
| Lowpass  | `w^2`       |
| Bandpass | `w/Q * s`   |
| Notch    | `s^2 + w^2` |
| Highpass | `s^2`       |
