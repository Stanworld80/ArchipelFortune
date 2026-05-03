import wave
import struct
import math
import os

def generate_tone(freq, duration_ms, sample_rate=44100, amplitude=16000, waveform='square'):
    num_samples = int(sample_rate * (duration_ms / 1000.0))
    samples = []
    for i in range(num_samples):
        t = float(i) / sample_rate
        if waveform == 'square':
            val = amplitude if math.sin(2.0 * math.pi * freq * t) > 0 else -amplitude
        elif waveform == 'sawtooth':
            val = amplitude * (2.0 * (t * freq - math.floor(t * freq + 0.5)))
        else: # sine
            val = amplitude * math.sin(2.0 * math.pi * freq * t)
        
        # Envelope (fade out)
        env = max(0, 1 - (i / num_samples))
        val *= env
        
        samples.append(int(val))
    return samples

def save_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1) # mono
        f.setsampwidth(2) # 2 bytes
        f.setframerate(sample_rate)
        for s in samples:
            f.writeframes(struct.pack('<h', s))

def generate_island_found():
    # Happy arpeggio (C E G C)
    notes = [523.25, 659.25, 783.99, 1046.50]
    samples = []
    for f in notes:
        samples.extend(generate_tone(f, 150, waveform='square'))
    save_wav('island_found.wav', samples)

def generate_treasure_great():
    # Victorious chime
    notes = [440.0, 554.37, 659.25, 880.0, 1108.73]
    samples = []
    for f in notes:
        samples.extend(generate_tone(f, 100, waveform='sine'))
    samples.extend(generate_tone(1108.73, 500, waveform='sine'))
    save_wav('treasure_great.wav', samples)

def generate_poor_loot():
    # Sad descending tone
    notes = [349.23, 329.63, 311.13, 293.66]
    samples = []
    for f in notes:
        samples.extend(generate_tone(f, 250, waveform='sawtooth'))
    save_wav('poor_loot.wav', samples)

def generate_game_over():
    # Dramatic descending tone
    notes = [392.00, 311.13, 261.63, 196.00]
    samples = []
    for f in notes[:-1]:
        samples.extend(generate_tone(f, 300, waveform='sawtooth', amplitude=20000))
    samples.extend(generate_tone(notes[-1], 1500, waveform='sawtooth', amplitude=20000))
    save_wav('game_over.wav', samples)

def generate_bgm():
    # simple repeating 4-note bassline for a background ambient loop
    # We will make it short, loopable in flutter
    notes = [220.0, 196.0, 164.81, 196.0]
    samples = []
    for f in notes:
        samples.extend(generate_tone(f, 500, waveform='sine', amplitude=8000))
    save_wav('bgm.wav', samples)

def generate_victory():
    # Grand triumphant fanfarre
    # C4, G4, C5, E5, G5
    notes = [261.63, 392.00, 523.25, 659.25, 783.99]
    samples = []
    for f in notes[:-1]:
        samples.extend(generate_tone(f, 200, waveform='sine', amplitude=20000))
    # Long final note
    samples.extend(generate_tone(notes[-1], 2000, waveform='sine', amplitude=20000))
    save_wav('victory.wav', samples)

def generate_treasure_normal():
    # Pleasant chime
    notes = [523.25, 659.25, 783.99]
    samples = []
    for f in notes:
        samples.extend(generate_tone(f, 150, waveform='sine'))
    save_wav('treasure_normal.wav', samples)

if __name__ == '__main__':
    generate_island_found()
    generate_treasure_great()
    generate_treasure_normal()
    generate_poor_loot()
    generate_bgm()
    generate_game_over()
    generate_victory()
    print("Sounds generated!")
