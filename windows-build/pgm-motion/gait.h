// PGM original procedural gait experiment. SPDX-License-Identifier: MIT
#pragma once
#include <algorithm>
#include <cmath>
namespace pgm_motion {
struct pose { double lean_degrees; double lift_tiles; };
inline pose walking(double progress, bool paused=false) {
    if (paused || !std::isfinite(progress) || progress<=0 || progress>=1) return {0,0};
    constexpr double pi=3.14159265358979323846;
    // Feet return to their native location at either end of every transition.
    return {4.0*std::sin(2*pi*progress), .035*std::sin(pi*progress)};
}
// Work gesture (v23): readable tool swing on the whole sprite.
// 0-55 %: wind-up, leaning back away from the job; 55-70 %: fast strike toward the job
// (overshoot, small hop); 70-100 %: recovery to the native pose. dir=+1/-1 faces the job.
inline pose working(double phase, bool paused=false, int dir=1) {
    if (paused || !std::isfinite(phase)) return {0,0};
    phase-=std::floor(phase);
    const double d = dir < 0 ? -1.0 : 1.0;
    auto smooth=[](double t){ t=std::clamp(t,0.0,1.0); return t*t*(3-2*t); };
    constexpr double back=-10.0, strike=16.0;
    double lean, lift;
    if (phase < .55) { const double t=smooth(phase/.55); lean=back*t; lift=.05*t; }
    else if (phase < .70) { const double t=(phase-.55)/.15; lean=back+(strike-back)*t*t; lift=.05*(1-t); }
    else { const double t=smooth((phase-.70)/.30); lean=strike*(1-t); lift=0; }
    return {d*lean, lift};
}
}
