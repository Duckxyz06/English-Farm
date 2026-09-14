"""Original small synthesized score and effects for English Farm (no samples)."""
from pathlib import Path
import math
import wave
import numpy as np

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "game/assets/audio"
DEST.mkdir(parents=True, exist_ok=True)

def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)

def tone(buffer, start, duration, midi, volume=.12, soft=False):
    begin = int(start * RATE)
    size = min(int(duration * RATE), len(buffer) - begin)
    t = np.arange(size) / RATE
    f = note(midi)
    wavelet = np.sin(2*math.pi*f*t) + .24*np.sin(2*math.pi*f*2*t) + .06*np.sin(2*math.pi*f*3*t)
    envelope = (1-np.exp(-t*90)) * np.exp(-t*(2.2 if soft else 5.2)/duration)
    envelope *= np.minimum(1, np.maximum(0, (duration-t)/.06))
    buffer[begin:begin+size] += volume * wavelet * envelope

def write(name, samples):
    samples = np.clip(samples, -.94, .94)
    with wave.open(str(DEST/(name+".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((samples*32767).astype("<i2").tobytes())

beat = 60/90
score = np.zeros(int(32*beat*RATE))
chords = [(48,52,55),(45,48,52),(41,45,48),(43,47,50)] * 2
melody = [72,76,79,76,74,72,69,72,77,76,72,69,71,74,79,74,
          72,76,79,81,79,76,72,69,72,77,76,72,74,71,67,72]
for bar,chord in enumerate(chords):
    for pitch in chord:
        tone(score,bar*4*beat,3.7*beat,pitch,.065,True)
    for pulse in range(8):
        tone(score,(bar*4+pulse*.5)*beat,1.2*beat,chord[pulse%3]+12,.09)
for i,pitch in enumerate(melody):
    tone(score,i*beat,beat*.84,pitch,.075,True)
write("farm_theme",score)
for name,pitches in {
    "plant":[55,60], "water":[79,76,74,72],
    "harvest":[72,76,79], "success":[72,76,79,84]
}.items():
    samples = np.zeros(int((len(pitches)*.11+.5)*RATE))
    for i,pitch in enumerate(pitches):
        tone(samples,i*.11,.4,pitch,.18)
    write(name,samples)
print("Wrote original farm theme and four effects.")
