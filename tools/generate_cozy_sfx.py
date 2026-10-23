#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/generate_cozy_sfx.py
--------------------------
Tự động tổng hợp 6 file âm thanh .wav chuẩn 44100Hz 16-bit Mono
dùng thư viện chuẩn Python (wave, struct, math) không cần plugin ngoài:
1. sfx_click.wav   - Tiếng gõ gỗ nhẹ êm tai khi bấm nút UI / mở kho
2. sfx_plant.wav   - Tiếng gieo hạt / đặt đường gạch mềm mại (C5 -> E5)
3. sfx_harvest.wav - Tiếng thu hoạch nông sản / bánh mì / sữa (C5 - E5 - G5)
4. sfx_coin.wav    - Tiếng chuông vàng ting-ting trong trẻo
5. sfx_splash.wav  - Tiếng giọt nước nhảy lên vui nhộn khi câu cá
6. sfx_error.wav   - Tiếng báo trầm nhẹ khi click vào máy bận / vùng cấm
"""

import os
import wave
import struct
import math

SAMPLE_RATE = 44100
AUDIO_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "audio"))

def write_wav(filename: str, samples: list[float]):
    os.makedirs(AUDIO_DIR, exist_ok=True)
    filepath = os.path.join(AUDIO_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)      # Mono
        wav_file.setsampwidth(2)      # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        # Clamp & convert to 16-bit signed integers
        raw_frames = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            int_val = int(clamped * 32767.0)
            raw_frames.extend(struct.pack("<h", int_val))
        wav_file.writeframes(raw_frames)
    print(f"[SFX] Generated: {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def gen_click() -> list[float]:
    # Gõ gỗ trầm cực nhẹ êm tai (320Hz -> 260Hz, 0.10s)
    duration = 0.10
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    freq0 = 340.0
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        # Fast exponential decay
        env = math.exp(-38.0 * t)
        f = freq0 * (1.0 - 0.25 * (t / duration))
        val = (
            math.sin(2.0 * math.pi * f * t) * 0.75 +
            math.sin(2.0 * math.pi * f * 2.0 * t) * 0.2
        ) * env
        samples.append(val * 0.40)
    return samples

def gen_plant() -> list[float]:
    # Gieo hạt nốt trầm ấm F4 (349Hz) -> A4 (440Hz) êm dịu (0.15s)
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        env = math.exp(-15.0 * t) * (1.0 - math.exp(-100.0 * t))
        freq = 349.23 + (440.0 - 349.23) * math.pow(t / duration, 0.7)
        val = (
            math.sin(2.0 * math.pi * freq * t) * 0.8 +
            math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.15
        ) * env
        samples.append(val * 0.40)
    return samples

def gen_harvest() -> list[float]:
    # Hợp âm marimba trầm ấm F4, A4, C5 (0.24s)
    duration = 0.24
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [
        (0.00, 349.23, 0.6),  # F4
        (0.04, 440.00, 0.65), # A4
        (0.08, 523.25, 0.7)   # C5
    ]
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        mixed = 0.0
        for start_t, freq, weight in notes:
            if t >= start_t:
                dt = t - start_t
                env = math.exp(-12.0 * dt) * (1.0 - math.exp(-80.0 * dt))
                harm = (
                    math.sin(2.0 * math.pi * freq * dt) * 0.8 +
                    math.sin(2.0 * math.pi * freq * 2.0 * dt) * 0.2
                )
                mixed += harm * env * weight
        samples.append(mixed * 0.40)
    return samples


def gen_coin() -> list[float]:
    # Chuông vàng ting-ting trong trẻo (0.24s)
    duration = 0.24
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # 2 tiếng ting nối tiếp nhau
    ting1_start = 0.0
    ting2_start = 0.06
    f1 = 1975.53  # B6
    f2 = 2637.02  # E7
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        mixed = 0.0
        if t >= ting1_start:
            dt1 = t - ting1_start
            env1 = math.exp(-16.0 * dt1) * (1.0 - math.exp(-200.0 * dt1))
            mixed += (
                math.sin(2.0 * math.pi * f1 * dt1) * 0.7 +
                math.sin(2.0 * math.pi * f1 * 2.76 * dt1) * 0.2 +
                math.sin(2.0 * math.pi * f1 * 5.4 * dt1) * 0.1
            ) * env1 * 0.65
        if t >= ting2_start:
            dt2 = t - ting2_start
            env2 = math.exp(-14.0 * dt2) * (1.0 - math.exp(-200.0 * dt2))
            mixed += (
                math.sin(2.0 * math.pi * f2 * dt2) * 0.75 +
                math.sin(2.0 * math.pi * f2 * 2.76 * dt2) * 0.15 +
                math.sin(2.0 * math.pi * f2 * 5.4 * dt2) * 0.1
            ) * env2 * 0.75
        samples.append(mixed * 0.6)
    return samples

def gen_splash() -> list[float]:
    # Tiếng giọt nước nhảy lên vui nhộn plop (0.22s)
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        env = math.exp(-14.0 * t) * (1.0 - math.exp(-120.0 * t))
        # Sweeping up in pitch
        freq = 320.0 + 850.0 * math.pow(t / duration, 1.8)
        # Bubble modulation
        mod = 1.0 + 0.15 * math.sin(2.0 * math.pi * 38.0 * t)
        val = math.sin(2.0 * math.pi * freq * t * mod) * env
        samples.append(val * 0.8)
    return samples

def gen_error() -> list[float]:
    # Tiếng báo trầm nhẹ êm tai (0.20s)
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    freq = 196.0 # G3
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        env = math.exp(-18.0 * t) * (1.0 - math.exp(-80.0 * t))
        val = (
            math.sin(2.0 * math.pi * freq * t) * 0.8 +
            math.sin(2.0 * math.pi * (freq * 0.85) * t) * 0.2
        ) * env
        samples.append(val * 0.7)
    return samples

def main():
    print("==================================================")
    print("  GENERATING COZY 2.5D CHIBI SFX (.WAV MONO 44.1kHz)")
    print("==================================================")
    write_wav("sfx_click.wav", gen_click())
    write_wav("sfx_plant.wav", gen_plant())
    write_wav("sfx_harvest.wav", gen_harvest())
    write_wav("sfx_coin.wav", gen_coin())
    write_wav("sfx_splash.wav", gen_splash())
    write_wav("sfx_error.wav", gen_error())
    print("[SFX] All 6 audio files generated successfully!")

if __name__ == "__main__":
    main()
