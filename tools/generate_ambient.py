"""
Tạo ambient audio (sine wave drones) cho Cosmic Wish.
Output: assets/audio/ambient.ogg
"""
import math
import struct
import wave
import os

SAMPLE_RATE = 44100
DURATION = 20  # seconds, will loop
OUTPUT = 'assets/audio/ambient.ogg'

def write_wav(path, samples, rate=SAMPLE_RATE):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        for s in samples:
            v = max(-1.0, min(1.0, s))
            w.writeframes(struct.pack('<h', int(v * 32767)))

def generate_ambient(duration=DURATION, rate=SAMPLE_RATE):
    n = int(duration * rate)

    # Drones: A2 (110Hz), E3 (164.81Hz), A3 (220Hz) - minor/cosmic
    freqs = [110.0, 164.81, 220.0, 329.63]  # A2, E3, A3, E4
    amps = [0.30, 0.20, 0.15, 0.10]

    # LFO for breathing modulation (5s period)
    lfo_rate = 1.0 / 5.0

    samples = []
    for i in range(n):
        t = i / rate
        # Breathing envelope (slow swell)
        lfo = 0.5 + 0.5 * math.sin(2 * math.pi * lfo_rate * t)
        # Slow fade in/out
        fade = min(t / 2, (duration - t) / 2, 1.0)
        fade = max(0.0, fade)

        s = 0.0
        for f, a in zip(freqs, amps):
            s += a * math.sin(2 * math.pi * f * t)
        # Add subtle detuned high harmonic
        s += 0.05 * math.sin(2 * math.pi * 523.25 * t)
        # Add pink noise for warmth
        s += 0.04 * (math.sin(t * 12345.678) * 0.5 + math.sin(t * 9876.543) * 0.3)

        s *= 0.4 * lfo * fade
        samples.append(s)

    return samples

if __name__ == '__main__':
    os.makedirs('assets/audio', exist_ok=True)
    samples = generate_ambient()

    # Save as WAV first
    wav_path = 'assets/audio/ambient.wav'
    write_wav(wav_path, samples)
    print(f"Generated {wav_path}")

    # Try to convert to OGG via ffmpeg if available
    ogg_path = OUTPUT
    if os.system('ffmpeg -version > /dev/null 2>&1') == 0:
        os.system(f'ffmpeg -y -i {wav_path} -c:a libvorbis -q:a 3 {ogg_path} 2>/dev/null')
        if os.path.exists(ogg_path):
            os.remove(wav_path)
            print(f"Converted to {ogg_path}")
        else:
            os.rename(wav_path, 'assets/audio/ambient.wav')
            print("ffmpeg conversion failed, kept WAV")
    else:
        # Keep WAV - just_audio supports WAV too
        os.rename(wav_path, 'assets/audio/ambient.wav')
        print("ffmpeg not available, using WAV (just_audio supports it)")
