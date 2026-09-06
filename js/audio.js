// ==============================================================================
// Padel Scoreboard Sound Synthesizer (Web Audio API)
// Pure synthesized court audio - no external sound files required!
// ==============================================================================

class SoundEngine {
    constructor() {
        this.ctx = null;
        this.muted = false;
        this.volume = 0.7;
    }

    init() {
        if (!this.ctx) {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (AudioCtx) {
                this.ctx = new AudioCtx();
            }
        }
        if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
    }

    setMuted(muted) {
        this.muted = muted;
    }

    setVolume(vol) {
        this.volume = Math.max(0, Math.min(1, vol));
    }

    // Short crisp point score beep
    playPointScore(isTeam1 = true) {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        // Higher pitch for Team 1, lower pleasant pitch for Team 2
        osc.type = 'sine';
        const startFreq = isTeam1 ? 660 : 520;
        const endFreq = isTeam1 ? 880 : 700;

        osc.frequency.setValueAtTime(startFreq, now);
        osc.frequency.exponentialRampToValueAtTime(endFreq, now + 0.08);

        gain.gain.setValueAtTime(0.001, now);
        gain.gain.linearRampToValueAtTime(0.25 * this.volume, now + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(now);
        osc.stop(now + 0.13);
    }

    // Side Swap Whoosh / Sweep Chime
    playSideSwap() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        
        // Synth chord sweep
        const freqs = [392.00, 523.25, 659.25, 783.99, 1046.50]; // G4, C5, E5, G5, C6
        freqs.forEach((freq, idx) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, now + idx * 0.06);

            gain.gain.setValueAtTime(0.001, now + idx * 0.06);
            gain.gain.linearRampToValueAtTime(0.18 * this.volume, now + idx * 0.06 + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.06 + 0.35);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + idx * 0.06);
            osc.stop(now + idx * 0.06 + 0.36);
        });
    }

    // Game won notification chime
    playGameWon(teamName = "Team 1") {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
        notes.forEach((freq, idx) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, now + idx * 0.09);

            gain.gain.setValueAtTime(0.001, now + idx * 0.09);
            gain.gain.linearRampToValueAtTime(0.3 * this.volume, now + idx * 0.09 + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.09 + 0.45);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + idx * 0.09);
            osc.stop(now + idx * 0.09 + 0.46);
        });
    }

    // Set won fanfare
    playSetWon() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const melody = [
            { f: 523.25, t: 0.0, d: 0.15 },
            { f: 659.25, t: 0.15, d: 0.15 },
            { f: 783.99, t: 0.3, d: 0.15 },
            { f: 1046.5, t: 0.45, d: 0.5 }
        ];

        melody.forEach(item => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(item.f, now + item.t);

            gain.gain.setValueAtTime(0.001, now + item.t);
            gain.gain.linearRampToValueAtTime(0.32 * this.volume, now + item.t + 0.03);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + item.t + item.d);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + item.t);
            osc.stop(now + item.t + item.d + 0.05);
        });
    }

    // Championship match victory fanfare with brass synthesis
    playMatchWon() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const fanfare = [
            { f: 523.25, t: 0.0, d: 0.18 },
            { f: 523.25, t: 0.18, d: 0.18 },
            { f: 523.25, t: 0.36, d: 0.18 },
            { f: 659.25, t: 0.54, d: 0.36 },
            { f: 587.33, t: 0.90, d: 0.18 },
            { f: 659.25, t: 1.08, d: 0.18 },
            { f: 783.99, t: 1.26, d: 0.36 },
            { f: 1046.5, t: 1.62, d: 0.80 }
        ];

        fanfare.forEach(item => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'sawtooth';
            const filter = this.ctx.createBiquadFilter();
            filter.type = 'lowpass';
            filter.frequency.setValueAtTime(1600, now + item.t);

            osc.frequency.setValueAtTime(item.f, now + item.t);

            gain.gain.setValueAtTime(0.001, now + item.t);
            gain.gain.linearRampToValueAtTime(0.22 * this.volume, now + item.t + 0.04);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + item.t + item.d);

            osc.connect(filter);
            filter.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + item.t);
            osc.stop(now + item.t + item.d + 0.05);
        });
    }

    // BLE Connect 3x flash sound
    playBLEConnect() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        [0, 0.16, 0.32].forEach((offset) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(900, now + offset);
            osc.frequency.exponentialRampToValueAtTime(1200, now + offset + 0.08);

            gain.gain.setValueAtTime(0.001, now + offset);
            gain.gain.linearRampToValueAtTime(0.25 * this.volume, now + offset + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + offset + 0.1);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + offset);
            osc.stop(now + offset + 0.11);
        });
    }

    // Racket button click sound
    playButtonClick() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'square';
        osc.frequency.setValueAtTime(400, now);
        osc.frequency.exponentialRampToValueAtTime(150, now + 0.04);

        gain.gain.setValueAtTime(0.12 * this.volume, now);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.04);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(now);
        osc.stop(now + 0.05);
    }
}

window.soundEngine = new SoundEngine();
