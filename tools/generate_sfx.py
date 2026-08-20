"""
Tạo sound effects cho Cosmic Wish:
- chime.mp3: tiếng chuông trầm kết thúc loading
- swoosh.mp3: chuyển cảnh
"""
import math
import struct
import wave
import os

SAMPLE_RATE = 44100

def write_wav(path, samples, rate=SAMPLE_RATE):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        for s in samples:
            v = max(-1.0, min(1.0, s))
            w.writeframes(struct.pack('<h', int(v * 32767)))

def envelope(t, attack, decay, sustain, release, total):
    if t < attack:
        return t / attack
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    if t < total - release:
        return sustain
    if t < total:
        return sustain * (total - t) / release
    return 0.0

def gen_chime(duration=2.5, rate=SAMPLE_RATE):
    """Bell-like chime with multiple harmonics, fade."""
    n = int(duration * rate)
    samples = []
    # Fundamental + overtones
    freqs = [440.0, 880.0, 1320.0, 1760.0]
    amps = [0.5, 0.25, 0.15, 0.08]
    for i in range(n):
        t = i / rate
        env = envelope(t, 0.005, 0.4, 0.3, 1.5, duration)
        s = 0.0
        for f, a in zip(freqs, amps):
            s += a * math.sin(2 * math.pi * f * t)
        s *= 0.5 * env
        samples.append(s)
    return samples

def gen_swoosh(duration=0.6, rate=SAMPLE_RATE):
    """Filter sweep for transitions."""
    n = int(duration * rate)
    samples = []
    for i in range(n):
        t = i / rate
        progress = t / duration
        # White noise with bandpass sweep
        noise = (math.sin(t * 12345) * 0.5 + math.sin(t * 67890) * 0.3)
        # High frequency carrier
        carrier = math.sin(2 * math.pi * (300 + 1500 * progress) * t)
        env = math.sin(math.pi * progress)  # 0 → 1 → 0
        s = noise * carrier * env * 0.4
        samples.append(s)
    return samples

def gen_tap(duration=0.15, rate=SAMPLE_RATE):
    """Soft tap for button feedback."""
    n = int(duration * rate)
    samples = []
    for i in range(n):
        t = i / rate
        freq = 800 - 400 * (t / duration)
        env = math.exp(-t * 20)
        s = 0.3 * env * math.sin(2 * math.pi * freq * t)
        samples.append(s)
    return samples

if __name__ == '__main__':
    os.makedirs('assets/audio', exist_ok=True)

    write_wav('assets/audio/chime.wav', gen_chime())
    print("Generated assets/audio/chime.wav")

    write_wav('assets/audio/swoosh.wav', gen_swoosh())
    print("Generated assets/audio/swoosh.wav")

    write_wav('assets/audio/tap.wav', gen_tap())
    print("Generated assets/audio/tap.wav")
