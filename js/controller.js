// ==============================================================================
// Padel Scoreboard Presentation Controller & UI Orchestrator
// Coordinates all interactive controls, companion gadgets, and keyboard shortcuts
// ==============================================================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize renderer and match engine
    window.scoreboardRenderer.init();
    window.matchEngine.resetMatch();

    // 1. Point / Game Controls
    const btnPointT1 = document.getElementById('btnPointT1');
    const btnPointT2 = document.getElementById('btnPointT2');
    const btnUndo = document.getElementById('btnUndo');
    const btnSideSwap = document.getElementById('btnSideSwap');
    const btnReset = document.getElementById('btnReset');
    const btnAutoPlay = document.getElementById('btnAutoPlay');

    if (btnPointT1) btnPointT1.addEventListener('click', () => window.matchEngine.addPoint(1));
    if (btnPointT2) btnPointT2.addEventListener('click', () => window.matchEngine.addPoint(2));
    if (btnUndo) btnUndo.addEventListener('click', () => window.matchEngine.undo());
    if (btnSideSwap) btnSideSwap.addEventListener('click', () => window.matchEngine.toggleSideSwap());
    if (btnReset) {
        btnReset.addEventListener('click', () => {
            const overlay = document.getElementById('victoryOverlay');
            if (overlay) overlay.classList.remove('active');
            window.scoreboardRenderer.stopAttractMode();
            window.matchEngine.resetMatch();
        });
    }
    if (btnAutoPlay) btnAutoPlay.addEventListener('click', () => {
        window.scoreboardRenderer.stopAttractMode();
        window.matchEngine.toggleAutoPlay();
    });

    // 2. Scenario Presets
    document.querySelectorAll('[data-scenario]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const overlay = document.getElementById('victoryOverlay');
            if (overlay) overlay.classList.remove('active');
            window.scoreboardRenderer.stopAttractMode();

            const scenario = e.currentTarget.getAttribute('data-scenario');
            window.matchEngine.loadScenario(scenario);
        });
    });

    // 3. Golden Point Toggle
    const toggleGolden = document.getElementById('toggleGoldenPoint');
    if (toggleGolden) {
        toggleGolden.addEventListener('change', (e) => {
            window.matchEngine.toggleGoldenPoint(e.target.checked);
        });
    }

    // 4. Playback Speed Selector
    document.querySelectorAll('[data-speed]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('[data-speed]').forEach(b => b.classList.remove('active'));
            e.currentTarget.classList.add('active');
            const speed = parseFloat(e.currentTarget.getAttribute('data-speed'));
            window.matchEngine.setSpeed(speed);
        });
    });

    // 5. LED Theme Selector
    const themeSelect = document.getElementById('themeSelect');
    if (themeSelect) {
        themeSelect.addEventListener('change', (e) => {
            window.scoreboardRenderer.setTheme(e.target.value);
        });
    }

    // 6. Brightness Slider
    const brightnessSlider = document.getElementById('brightnessSlider');
    if (brightnessSlider) {
        brightnessSlider.addEventListener('input', (e) => {
            window.scoreboardRenderer.setBrightness(parseFloat(e.target.value));
        });
    }

    // 7. LED Dot Mode (Smooth Diffuser vs 4-LED Individual Dots)
    const toggleLedDots = document.getElementById('toggleLedDots');
    if (toggleLedDots) {
        toggleLedDots.addEventListener('change', (e) => {
            window.scoreboardRenderer.setLedDotMode(e.target.checked);
        });
    }

    // 8. Court Environment Lighting (Night Floodlight / Arena / Day)
    const envSelect = document.getElementById('envSelect');
    if (envSelect) {
        envSelect.addEventListener('change', (e) => {
            document.body.className = `env-${e.target.value}`;
        });
    }

    // 9. 3D Perspective Tilt Control
    const tiltRange = document.getElementById('tiltRange');
    const boardContainer = document.getElementById('board3DContainer');
    if (tiltRange && boardContainer) {
        tiltRange.addEventListener('input', (e) => {
            const val = parseFloat(e.target.value);
            boardContainer.style.transform = `perspective(1200px) rotateX(${val}deg) rotateY(${val * 0.4}deg)`;
        });
    }

    // 10. Sound Toggle
    const btnSound = document.getElementById('btnSound');
    if (btnSound) {
        btnSound.addEventListener('click', () => {
            const isMuted = !window.soundEngine.muted;
            window.soundEngine.setMuted(isMuted);
            btnSound.innerHTML = isMuted 
                ? '<span class="icon">🔇</span> Sound Off' 
                : '<span class="icon">🔊</span> Sound On';
            btnSound.classList.toggle('muted', isMuted);
        });
    }

    // 11. Full-Screen Presentation Mode (F11 / Button)
    const btnFullscreen = document.getElementById('btnFullscreen');
    if (btnFullscreen) {
        btnFullscreen.addEventListener('click', () => {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen().catch(err => alert(err.message));
            } else {
                document.exitFullscreen();
            }
        });
    }

    // 12. Wear OS Galaxy Watch Simulator Interactions
    const watchBtnT1 = document.getElementById('watchBtnT1');
    const watchBtnT2 = document.getElementById('watchBtnT2');
    const watchBtnUndo = document.getElementById('watchBtnUndo');
    const watchBtnSwap = document.getElementById('watchBtnSwap');

    if (watchBtnT1) {
        watchBtnT1.addEventListener('click', () => {
            if (window.soundEngine) window.soundEngine.playButtonClick();
            window.matchEngine.addPoint(1);
        });
    }
    if (watchBtnT2) {
        watchBtnT2.addEventListener('click', () => {
            if (window.soundEngine) window.soundEngine.playButtonClick();
            window.matchEngine.addPoint(2);
        });
    }
    if (watchBtnUndo) {
        watchBtnUndo.addEventListener('click', () => {
            if (window.soundEngine) window.soundEngine.playButtonClick();
            window.matchEngine.undo();
        });
    }
    if (watchBtnSwap) {
        watchBtnSwap.addEventListener('click', () => {
            if (window.soundEngine) window.soundEngine.playButtonClick();
            window.matchEngine.toggleSideSwap();
        });
    }

    // 13. Padel Racket BLE Clicker Button Simulator
    // (Single Click = +1 Point Team 1 / Serve, Long Press > 1.2s = Swap/Undo, exactly matching padel_button_ble.ino!)
    const racketButton = document.getElementById('racketTactileButton');
    const racketLedFeedback = document.getElementById('racketLedFeedback');
    let pressTimer = null;
    let pressStartTime = 0;

    const flashRacketLed = (count = 1) => {
        if (!racketLedFeedback) return;
        racketLedFeedback.classList.add('flash');
        setTimeout(() => racketLedFeedback.classList.remove('flash'), 120 * count);
    };

    if (racketButton) {
        const handlePressDown = (e) => {
            e.preventDefault();
            pressStartTime = Date.now();
            racketButton.classList.add('pressed');
            flashRacketLed(1);
            if (window.soundEngine) window.soundEngine.playButtonClick();

            pressTimer = setTimeout(() => {
                // Long press triggered
                racketButton.classList.add('long-active');
                flashRacketLed(2);
            }, 1200);
        };

        const handlePressUp = (e) => {
            e.preventDefault();
            racketButton.classList.remove('pressed');
            racketButton.classList.remove('long-active');

            if (pressTimer) clearTimeout(pressTimer);
            const duration = Date.now() - pressStartTime;

            if (duration >= 1200) {
                // Long press -> Side Swap
                window.matchEngine.toggleSideSwap();
                window.matchEngine.logEvent("🔘 Racket Clicker: Long Press (1.2s) -> Side Swap");
            } else if (duration >= 50) {
                // Short press -> +1 Point
                window.matchEngine.addPoint(1);
                window.matchEngine.logEvent("🔘 Racket Clicker: Short Click -> +1 Point");
            }
        };

        racketButton.addEventListener('mousedown', handlePressDown);
        racketButton.addEventListener('mouseup', handlePressUp);
        racketButton.addEventListener('touchstart', handlePressDown, { passive: false });
        racketButton.addEventListener('touchend', handlePressUp, { passive: false });
    }

    // 14. Keyboard Shortcuts for Presentations & Demos
    window.addEventListener('keydown', (e) => {
        // Prevent shortcuts if typing in an input
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return;

        switch (e.key) {
            case '1': // Point Team 1
                window.matchEngine.addPoint(1);
                break;
            case '2': // Point Team 2
                window.matchEngine.addPoint(2);
                break;
            case 'u':
            case 'U':
            case 'z': // Undo
                window.matchEngine.undo();
                break;
            case 's':
            case 'S': // Side Swap
                window.matchEngine.toggleSideSwap();
                break;
            case ' ': // Space = Toggle Auto Demo
                e.preventDefault();
                window.matchEngine.toggleAutoPlay();
                break;
            case 'r':
            case 'R': // Reset
                window.matchEngine.resetMatch();
                break;
            case 'b':
            case 'B': // BLE Connect flash
                window.matchEngine.loadScenario('ble-flash');
                break;
            case 'f':
            case 'F': // Fullscreen
                if (!document.fullscreenElement) {
                    document.documentElement.requestFullscreen().catch(() => {});
                } else {
                    document.exitFullscreen();
                }
                break;
        }
    });

    // Dismiss Victory Overlay
    const btnDismissVictory = document.getElementById('btnDismissVictory');
    if (btnDismissVictory) {
        btnDismissVictory.addEventListener('click', () => {
            const overlay = document.getElementById('victoryOverlay');
            if (overlay) overlay.classList.remove('active');
        });
    }

    // Initial log
    window.matchEngine.logEvent("Scoreboard Initialized & Ready (4 Digits + Games/Sets Snap Carrier)");
    window.matchEngine.logEvent("Hardware: ESP32 BLE Service 4fafc201-1fb5-459e-8fcc-c5c9c331914b");
});
