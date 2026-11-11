#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/generate_cozy_soundscape.py
---------------------------------
Bộ công cụ tổng hợp Âm thanh Nông trại Ấm áp (Cozy Farm Soundscape Generator)
Dành cho Hay Day Offline - Tự động tạo 100% tài nguyên âm thanh .wav chuẩn 44.1kHz 16-bit Mono.
Không phụ thuộc thư viện ngoài: hoàn toàn sử dụng thư viện chuẩn Python (wave, struct, math).

Tuyệt đối 0% White Noise / Random Static:
- 100% sóng Sine / Triangle hài âm thuần khiết (Music Box / Celesta / Wooden Marimba / Warm Acoustic Harmonics).
- Khởi âm mượt (Smooth Cosine/Exponential Attack) và tắt dần tự nhiên (Exponential Decay).
- Biên độ dịu êm (<= 0.35), không bao giờ rè hay vỡ tiếng trên loa laptop.
"""

import os
import wave
import struct
import math

SAMPLE_RATE = 44100
MAX_AMP = 0.35
AUDIO_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "audio"))


def clamp_and_fade(samples: list[float], peak_limit: float = MAX_AMP) -> list[float]:
    if not samples:
        return samples
    n = len(samples)
    fade_len = min(int(0.008 * SAMPLE_RATE), n // 4)
    out = list(samples)
    for i in range(fade_len):
        w = 0.5 * (1.0 - math.cos(math.pi * i / float(max(1, fade_len))))
        out[i] *= w
        out[n - 1 - i] *= w
    current_peak = max((abs(x) for x in out), default=0.0)
    if current_peak > peak_limit and current_peak > 1e-6:
        scale = peak_limit / current_peak
        out = [x * scale for x in out]
    return [max(-peak_limit, min(peak_limit, x)) for x in out]


def write_wav(filename: str, samples: list[float]):
    os.makedirs(AUDIO_DIR, exist_ok=True)
    filepath = os.path.join(AUDIO_DIR, filename)
    clean_samples = clamp_and_fade(samples, MAX_AMP)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)      # Mono
        wav_file.setsampwidth(2)      # 16-bit PCM
        wav_file.setframerate(SAMPLE_RATE)

        raw_frames = bytearray()
        for s in clean_samples:
            int_val = int(max(-1.0, min(1.0, s)) * 32767.0)
            raw_frames.extend(struct.pack("<h", int_val))
        wav_file.writeframes(raw_frames)
    dur = len(clean_samples) / float(SAMPLE_RATE)
    print(f"[Soundscape] Generated: {filename:<28} ({len(clean_samples):>7} samples, {dur:.2f}s)")


# ==============================================================================
# 1. PURE HARMONIC SYNTHESIS ENGINES (ZERO NOISE)
# ==============================================================================

def triangle_wave(phase: float) -> float:
    """Smooth band-limited triangle approximation using first 3 odd sine harmonics."""
    return (
        math.sin(phase)
        - (1.0 / 9.0) * math.sin(3.0 * phase)
        + (1.0 / 25.0) * math.sin(5.0 * phase)
    )


def synthesize_warm_string(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> list[float]:
    """Pure harmonic plucked nylon guitar / harp string without any random noise."""
    num_samples = int(duration * sample_rate)
    samples = []
    tau1 = 0.55 * math.sqrt(220.0 / max(80.0, freq))
    tau2 = 0.22 * math.sqrt(220.0 / max(80.0, freq))
    tau3 = 0.09
    for i in range(num_samples):
        t = i / float(sample_rate)
        attack = 1.0 - math.exp(-t * 280.0)
        e1 = math.exp(-t / tau1)
        e2 = math.exp(-t / tau2)
        e3 = math.exp(-t / tau3)
        p = 2.0 * math.pi * freq * t
        val = (
            triangle_wave(p) * 0.68 * e1
            + math.sin(2.0 * p + 0.2) * 0.22 * e2
            + math.sin(3.0 * p + 0.5) * 0.08 * e3
            + math.sin(4.0 * p + 0.8) * 0.02 * e3
        ) * attack
        samples.append(val * 0.30)
    return samples


def synthesize_marimba(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> list[float]:
    """Pure modal synthesis of a warm wooden marimba / kalimba bar."""
    num_samples = int(duration * sample_rate)
    samples = []
    tau1 = 0.30 * math.sqrt(300.0 / max(120.0, freq))
    tau2 = 0.055 * math.sqrt(300.0 / max(120.0, freq))
    tau3 = 0.015
    f2 = freq * 2.0
    f3 = freq * 3.92
    for i in range(num_samples):
        t = i / float(sample_rate)
        attack = 1.0 - math.exp(-t * 500.0)
        env1 = math.exp(-t / tau1)
        env2 = math.exp(-t / tau2)
        env3 = math.exp(-t / tau3)
        val = (
            math.sin(2.0 * math.pi * freq * t) * 0.78 * env1
            + math.sin(2.0 * math.pi * f2 * t) * 0.16 * env2
            + math.sin(2.0 * math.pi * f3 * t) * 0.06 * env3
        ) * attack
        samples.append(val * 0.30)
    return samples


def synthesize_celesta_bell(freq: float, duration: float, sample_rate: int = SAMPLE_RATE) -> list[float]:
    """Warm music-box / celesta chime using pure sine overtones."""
    num_samples = int(duration * sample_rate)
    samples = []
    for i in range(num_samples):
        t = i / float(sample_rate)
        attack = 1.0 - math.exp(-t * 420.0)
        env1 = math.exp(-t * 5.0)
        env2 = math.exp(-t * 11.0)
        env3 = math.exp(-t * 20.0)
        p = 2.0 * math.pi * freq * t
        val = (
            math.sin(p) * 0.75 * env1
            + math.sin(2.0 * p) * 0.18 * env2
            + math.sin(3.0 * p) * 0.07 * env3
        ) * attack
        samples.append(val * 0.28)
    return samples


# ==============================================================================
# 2. SOUND EFFECTS (SFX) GENERATORS (100% NOISE-FREE)
# ==============================================================================

def gen_click() -> list[float]:
    """sfx_click.wav: Tiếng gõ thanh gỗ marimba nhẹ êm tai (440 Hz)."""
    duration = 0.08
    m = synthesize_marimba(440.0, duration, SAMPLE_RATE)
    return [s * math.exp(-16.0 * (i / float(SAMPLE_RATE))) for i, s in enumerate(m)]


def gen_ui_wood_click() -> list[float]:
    """sfx_ui_wood_click.wav: Tiếng thanh gỗ ấm áp (523.25 Hz - C5)."""
    duration = 0.09
    m = synthesize_marimba(523.25, duration, SAMPLE_RATE)
    return [s * math.exp(-18.0 * (i / float(SAMPLE_RATE))) for i, s in enumerate(m)]


def gen_plant() -> list[float]:
    """sfx_plant.wav: Hai nốt kalimba/harp mộc mạc G4 -> D5 khi gieo hạt."""
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    notes = [(0.00, 392.00, 0.8), (0.05, 587.33, 1.0)]
    for start_t, freq, weight in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        tone = synthesize_marimba(freq, 0.12, SAMPLE_RATE)
        for i, val in enumerate(tone):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * weight * 0.85
    return samples


def gen_harvest() -> list[float]:
    """sfx_harvest.wav: Hợp âm marimba 4 nốt vui tươi (C5-E5-G5-C6)."""
    duration = 0.34
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    notes = [
        (0.00, 523.25, 0.70),  # C5
        (0.04, 659.25, 0.80),  # E5
        (0.08, 783.99, 0.90),  # G5
        (0.12, 1046.50, 1.00), # C6
    ]
    for start_t, freq, weight in notes:
        m_samples = synthesize_marimba(freq, 0.20, SAMPLE_RATE)
        start_idx = int(start_t * SAMPLE_RATE)
        for i, val in enumerate(m_samples):
            idx = start_idx + i
            if idx < num_samples:
                samples[idx] += val * weight * 0.75
    return samples


def gen_coin() -> list[float]:
    """sfx_coin.wav: Tiếng chuông celesta đôi trong trẻo (C6 -> E6)."""
    duration = 0.26
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    strikes = [
        (0.000, 1046.50, 0.80),  # C6
        (0.035, 1318.51, 1.00),  # E6
    ]
    for start_t, freq, weight in strikes:
        start_idx = int(start_t * SAMPLE_RATE)
        bell = synthesize_celesta_bell(freq, 0.22, SAMPLE_RATE)
        for i, val in enumerate(bell):
            idx = start_idx + i
            if idx < num_samples:
                samples[idx] += val * weight * 0.85
    return samples


def gen_coins_jingle() -> list[float]:
    """sfx_coins_jingle.wav: Chuỗi 6 nốt chuông music-box rộn ràng khi bán hàng."""
    duration = 0.75
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    coin_strikes = [
        (0.00, 783.99, 0.65),   # G5
        (0.06, 987.77, 0.72),   # B5
        (0.12, 1046.50, 0.78),  # C6
        (0.18, 1318.51, 0.85),  # E6
        (0.24, 1567.98, 0.92),  # G6
        (0.31, 2093.00, 1.00),  # C7
    ]
    for start_t, freq, weight in coin_strikes:
        start_idx = int(start_t * SAMPLE_RATE)
        bell = synthesize_celesta_bell(freq, 0.35, SAMPLE_RATE)
        for i, val in enumerate(bell):
            idx = start_idx + i
            if idx < num_samples:
                samples[idx] += val * weight * 0.70
    return samples


def gen_welcome_chime() -> list[float]:
    """sfx_welcome_chime.wav: Dải chuông gió ngũ âm (C5-D5-E5-G5-A5-C6) êm dịu."""
    duration = 1.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    chimes = [
        (0.00, 523.25, 0.65),  # C5
        (0.07, 587.33, 0.70),  # D5
        (0.14, 659.25, 0.75),  # E5
        (0.21, 783.99, 0.82),  # G5
        (0.28, 880.00, 0.90),  # A5
        (0.36, 1046.50, 1.00), # C6
    ]
    for start_t, freq, weight in chimes:
        start_idx = int(start_t * SAMPLE_RATE)
        bell = synthesize_celesta_bell(freq, 0.85, SAMPLE_RATE)
        for i, val in enumerate(bell):
            idx = start_idx + i
            if idx < num_samples:
                samples[idx] += val * weight * 0.65
    return samples


def gen_steamboat_whistle() -> list[float]:
    """sfx_steamboat_whistle.wav: Tiếng còi tàu gỗ 2 ống hòa âm F4 + A4 êm ái, 0% tạp âm."""
    duration = 1.40
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    f1, f2 = 349.23, 440.00  # F4 + A4 warm interval
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        if t < 0.18:
            env = 0.5 * (1.0 - math.cos(math.pi * (t / 0.18)))
        elif t < 0.95:
            env = 1.0
        else:
            rel_t = (t - 0.95) / 0.45
            env = 0.5 * (1.0 + math.cos(math.pi * min(1.0, rel_t)))

        vib = 1.0 + 0.004 * math.sin(2.0 * math.pi * 5.0 * t)
        p1 = 2.0 * math.pi * f1 * vib * t
        p2 = 2.0 * math.pi * f2 * vib * t
        tone = (
            triangle_wave(p1) * 0.50
            + triangle_wave(p2) * 0.40
            + math.sin(2.0 * p1) * 0.10
        )
        samples.append(tone * env * 0.26)
    return samples


def gen_splash() -> list[float]:
    """sfx_splash.wav: Tiếng giọt nước plop tròn trịa bằng sóng sine vuốt tần số."""
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        env = math.exp(-16.0 * t) * (1.0 - math.exp(-220.0 * t))
        freq = 300.0 + 620.0 * math.pow(min(1.0, t / 0.14), 1.4)
        phase += 2.0 * math.pi * freq / float(SAMPLE_RATE)
        val = (math.sin(phase) * 0.82 + math.sin(2.0 * phase) * 0.18) * env
        samples.append(val * 0.30)
    return samples


def gen_error() -> list[float]:
    """sfx_error.wav: Tiếng gõ gỗ trầm kép (261.6Hz -> 196.0Hz) nhẹ nhàng."""
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    taps = [(0.00, 261.63, 0.85), (0.08, 196.00, 0.75)]
    for start_t, freq, weight in taps:
        start_idx = int(start_t * SAMPLE_RATE)
        m = synthesize_marimba(freq, 0.12, SAMPLE_RATE)
        for i, val in enumerate(m):
            idx = start_idx + i
            if idx < num_samples:
                samples[idx] += val * weight * 0.90
    return samples


def gen_page_flip_almanac() -> list[float]:
    """sfx_page_flip_almanac.wav: Nốt lướt harp nhẹ (G4 -> B4 -> D5) thay cho tiếng sột soạt."""
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    notes = [(0.00, 392.00, 0.6), (0.03, 493.88, 0.75), (0.06, 587.33, 0.9)]
    for start_t, freq, weight in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        tone = synthesize_warm_string(freq, 0.12, SAMPLE_RATE)
        for i, val in enumerate(tone):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * weight * 0.75
    return samples


def gen_cloth_rustle() -> list[float]:
    """sfx_cloth_rustle.wav: Hai nốt marimba mềm mại (E4 -> A4) khi đổi trang phục."""
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    notes = [(0.00, 329.63, 0.75), (0.04, 440.00, 0.90)]
    for start_t, freq, weight in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        tone = synthesize_marimba(freq, 0.12, SAMPLE_RATE)
        for i, val in enumerate(tone):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * weight * 0.80
    return samples


def gen_dice_roll() -> list[float]:
    """sfx_dice_roll.wav: 4 tiếng gõ gỗ kalimba nảy vui tai."""
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    clicks = [(0.00, 392.0), (0.06, 440.0), (0.12, 523.25), (0.18, 587.33)]
    for start_t, freq in clicks:
        start_idx = int(start_t * SAMPLE_RATE)
        m = synthesize_marimba(freq, 0.08, SAMPLE_RATE)
        for i, val in enumerate(m):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * 0.85
    return samples


def gen_camera_shutter_chibi() -> list[float]:
    """sfx_camera_shutter_chibi.wav: Tiếng gõ gỗ kép + chuông lấp lánh thuần khiết."""
    duration = 0.26
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    events = [
        (0.00, synthesize_marimba(659.25, 0.06, SAMPLE_RATE), 0.80),
        (0.05, synthesize_marimba(783.99, 0.06, SAMPLE_RATE), 0.85),
        (0.09, synthesize_celesta_bell(1567.98, 0.16, SAMPLE_RATE), 0.90),
    ]
    for start_t, tone, weight in events:
        start_idx = int(start_t * SAMPLE_RATE)
        for i, val in enumerate(tone):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * weight
    return samples


def gen_gentle_rain_loop() -> list[float]:
    """sfx_gentle_rain_loop.wav: Tiếng giọt sương music-box êm dịu (0% white noise)."""
    duration = 2.40
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    droplets = [
        (0.10, 523.25), (0.45, 659.25), (0.80, 783.99),
        (1.15, 659.25), (1.55, 587.33), (1.95, 523.25),
    ]
    for start_t, freq in droplets:
        start_idx = int(start_t * SAMPLE_RATE)
        bell = synthesize_celesta_bell(freq, 0.38, SAMPLE_RATE)
        for i, val in enumerate(bell):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val * 0.45
    return samples


# ==============================================================================
# 3. COZY AMBIENT BGM LOOP (PURE HARMONIC MUSIC BOX & MARIMBA)
# ==============================================================================

def gen_cozy_farm_bgm() -> list[float]:
    """
    bgm_cozy_farm.wav
    Bản nhạc nền đồng quê ấm áp (Pure Harmonic Acoustic Guitar + Marimba + Celesta):
    - Thời lượng: 25.60 giây (8 ô nhịp 4/4 @ 75 BPM).
    - Hoàn toàn sử dụng sóng Sine/Triangle hài âm tự nhiên, 0% nhiễu, không bao giờ gây tiếng rè.
    """
    sample_rate = SAMPLE_RATE
    bpm = 75.0
    beat_dur = 60.0 / bpm  # 0.8s
    total_beats = 32
    loop_duration = total_beats * beat_dur  # 25.6s
    loop_samples = int(loop_duration * sample_rate)

    max_ring_samples = int(2.0 * sample_rate)
    raw_buffer = [0.0] * (loop_samples + max_ring_samples)

    def add_event(start_beat: float, instrument_samples: list[float], gain: float):
        start_idx = int(start_beat * beat_dur * sample_rate)
        for i, s in enumerate(instrument_samples):
            idx = start_idx + i
            if idx < len(raw_buffer):
                raw_buffer[idx] += s * gain

    # --- TRACK 1: WARM HARMONIC GUITAR ARPEGGIOS ---
    guitar_patterns = [
        # Bar 1: Cmaj7
        [(0.0, 261.63), (1.0, 329.63), (2.0, 392.00), (3.0, 493.88)],
        # Bar 2: G/B
        [(4.0, 246.94), (5.0, 293.66), (6.0, 392.00), (7.0, 493.88)],
        # Bar 3: Am7
        [(8.0, 220.00), (9.0, 261.63), (10.0, 329.63), (11.0, 392.00)],
        # Bar 4: Fmaj7
        [(12.0, 174.61), (13.0, 261.63), (14.0, 349.23), (15.0, 440.00)],
        # Bar 5: C/E
        [(16.0, 261.63), (17.0, 329.63), (18.0, 392.00), (19.0, 523.25)],
        # Bar 6: Dm7
        [(20.0, 293.66), (21.0, 349.23), (22.0, 440.00), (23.0, 523.25)],
        # Bar 7: G6
        [(24.0, 196.00), (25.0, 293.66), (26.0, 392.00), (27.0, 440.00)],
        # Bar 8: C
        [(28.0, 261.63), (29.0, 329.63), (30.0, 392.00), (31.0, 329.63)],
    ]
    for bar in guitar_patterns:
        for beat, freq in bar:
            gt = synthesize_warm_string(freq, 1.1, sample_rate)
            add_event(beat, gt, gain=0.45)

    # --- TRACK 2: WOODEN MARIMBA & CELESTA PASTORAL MELODY ---
    melody_notes = [
        (0.5, 523.25, 0.85), (1.5, 659.25, 0.85), (3.0, 783.99, 0.95),
        (4.5, 587.33, 0.85), (6.0, 659.25, 0.85), (7.0, 523.25, 0.90),
        (8.5, 440.00, 0.85), (9.5, 523.25, 0.85), (10.5, 659.25, 0.85), (11.5, 880.00, 0.95),
        (12.5, 783.99, 0.90), (14.0, 659.25, 0.85), (15.0, 587.33, 0.90),
        (16.5, 523.25, 0.85), (17.5, 659.25, 0.85), (18.5, 783.99, 0.90), (19.5, 1046.50, 0.95),
        (20.5, 880.00, 0.90), (22.0, 783.99, 0.85), (23.0, 659.25, 0.90),
        (24.5, 587.33, 0.85), (25.5, 659.25, 0.85), (26.5, 587.33, 0.85), (27.5, 493.88, 0.90),
        (28.5, 523.25, 0.95), (30.0, 659.25, 0.85), (31.0, 523.25, 0.85),
    ]
    for beat, freq, weight in melody_notes:
        mb = synthesize_marimba(freq, 0.85, sample_rate)
        add_event(beat, mb, gain=0.50 * weight)

    # --- SEAMLESS LOOP WRAP-AROUND ---
    final_samples = raw_buffer[:loop_samples]
    for i in range(max_ring_samples):
        tail_idx = loop_samples + i
        if tail_idx < len(raw_buffer):
            final_samples[i] += raw_buffer[tail_idx]

    return clamp_and_fade(final_samples, peak_limit=0.30)


# ==============================================================================
# 4. MAIN ENTRY POINT
# ==============================================================================

def main():
    print("=" * 68)
    print("  HAY DAY OFFLINE: PURE HARMONIC COZY SOUNDSCAPE GENERATOR")
    print("=" * 68)

    write_wav("sfx_click.wav", gen_click())
    write_wav("sfx_ui_wood_click.wav", gen_ui_wood_click())
    write_wav("sfx_plant.wav", gen_plant())
    write_wav("sfx_harvest.wav", gen_harvest())
    write_wav("sfx_coin.wav", gen_coin())
    write_wav("sfx_coins_jingle.wav", gen_coins_jingle())
    write_wav("sfx_welcome_chime.wav", gen_welcome_chime())
    write_wav("sfx_steamboat_whistle.wav", gen_steamboat_whistle())
    write_wav("sfx_splash.wav", gen_splash())
    write_wav("sfx_error.wav", gen_error())
    write_wav("sfx_page_flip_almanac.wav", gen_page_flip_almanac())
    write_wav("sfx_cloth_rustle.wav", gen_cloth_rustle())
    write_wav("sfx_dice_roll.wav", gen_dice_roll())
    write_wav("sfx_camera_shutter_chibi.wav", gen_camera_shutter_chibi())
    write_wav("sfx_gentle_rain_loop.wav", gen_gentle_rain_loop())

    print("\n--- Generating Cozy Farm Background Loop (25.6s @ 75 BPM) ---")
    write_wav("bgm_cozy_farm.wav", gen_cozy_farm_bgm())

    print("=" * 68)
    print("  ALL 16 PURE HARMONIC COZY SOUNDS GENERATED SUCCESSFULLY!")
    print("=" * 68)


if __name__ == "__main__":
    main()
