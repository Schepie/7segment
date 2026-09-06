// ==============================================================================
// Padel Scoreboard Display Engine (7-Segment & Games/Sets Matrix)
// Exact match with hardware WS2812B LED chain and SCAD CAD parameters
// ==============================================================================

class ScoreboardRenderer {
    constructor() {
        // 7-segment font mapping: [BL, B, BR, M, TL, T, TR]
        this.numbers = [
            [1, 1, 1, 0, 1, 1, 1], // 0
            [0, 0, 1, 0, 0, 0, 1], // 1
            [1, 1, 0, 1, 0, 1, 1], // 2
            [0, 1, 1, 1, 0, 1, 1], // 3
            [0, 0, 1, 1, 1, 0, 1], // 4
            [0, 1, 1, 1, 1, 1, 0], // 5
            [1, 1, 1, 1, 1, 1, 0], // 6
            [0, 0, 1, 0, 0, 1, 1], // 7
            [1, 1, 1, 1, 1, 1, 1], // 8
            [0, 1, 1, 1, 1, 1, 1], // 9
            [0, 0, 0, 0, 0, 0, 0], // 10 (Blank)
            [1, 0, 1, 1, 1, 1, 1], // 11 ('A' Advantage)
            [1, 1, 1, 1, 0, 0, 1], // 12 ('d' Advantage)
            [0, 0, 0, 1, 0, 0, 0]  // 13 ('-' Dash)
        ];

        // Segment names matching SVG IDs
        this.segmentKeys = ['bl', 'b', 'br', 'm', 'tl', 't', 'tr'];

        // Theme colors
        this.themes = {
            classic: {
                team1: { name: 'Neon Blue', main: '#00d2ff', glow: 'rgba(0, 210, 255, 0.75)', core: '#ffffff' },
                team2: { name: 'Crimson Red', main: '#ff2d55', glow: 'rgba(255, 45, 85, 0.75)', core: '#ffffff' }
            },
            electric: {
                team1: { name: 'Cyber Lime', main: '#00ff88', glow: 'rgba(0, 255, 136, 0.75)', core: '#ffffff' },
                team2: { name: 'Hot Magenta', main: '#ff00aa', glow: 'rgba(255, 0, 170, 0.75)', core: '#ffffff' }
            },
            wimbledon: {
                team1: { name: 'Championship Green', main: '#10b981', glow: 'rgba(16, 185, 129, 0.75)', core: '#ffffff' },
                team2: { name: 'Gold Amber', main: '#fbbf24', glow: 'rgba(251, 191, 36, 0.75)', core: '#ffffff' }
            },
            monochrome: {
                team1: { name: 'Ultra White', main: '#e0f2fe', glow: 'rgba(224, 242, 254, 0.85)', core: '#ffffff' },
                team2: { name: 'Warm Amber', main: '#f97316', glow: 'rgba(249, 115, 22, 0.85)', core: '#ffffff' }
            }
        };

        this.currentTheme = 'classic';
        this.brightness = 1.0; // 0.2 to 1.0
        this.ledDotMode = false; // smooth diffuser vs individual 4-LED dots

        // Animation state
        this.isAnimating = false;
        this.animationTimer = null;
        this.attractMode = false;
        this.attractHue = 0;
    }

    init() {
        this.renderBlankScoreboard();
    }

    setTheme(themeKey) {
        if (this.themes[themeKey]) {
            this.currentTheme = themeKey;
            if (window.matchEngine) {
                window.matchEngine.updateDisplay();
            }
        }
    }

    setBrightness(b) {
        this.brightness = Math.max(0.2, Math.min(1.0, b));
        document.documentElement.style.setProperty('--led-brightness', this.brightness);
    }

    setLedDotMode(active) {
        this.ledDotMode = active;
        const board = document.getElementById('padelScoreboard');
        if (board) {
            if (active) board.classList.add('led-dots-visible');
            else board.classList.remove('led-dots-visible');
        }
    }

    renderBlankScoreboard() {
        // Turn off all segments
        for (let d = 0; d < 4; d++) {
            this.drawDigit(d, 10, '#000000', false);
        }
        this.drawGamesAndSets(0, 0, 0, 0, false);
    }

    // Map char to font index
    charToFontIndex(c, d, rawScore) {
        if (c >= '0' && c <= '9') return parseInt(c, 10);
        if (c === 'A' || c === 'a') return 11;
        if (c === 'D' || c === 'd') return 12;
        if (c === '-') return 13;
        
        // Advantage autocompletion (e.g. "A " -> "Ad")
        if (d === 1 && (rawScore[0] === 'A' || rawScore[0] === 'a') && (c === ' ' || c === undefined)) {
            return 12; // 'd'
        }
        if (d === 3 && (rawScore[2] === 'A' || rawScore[2] === 'a') && (c === ' ' || c === undefined)) {
            return 12; // 'd'
        }

        return 10; // Blank
    }

    // Render 1 digit (0..3)
    drawDigit(digitIndex, numIndex, colorHex, glow = true, customGlowColor = null) {
        const digitEl = document.getElementById(`digit-${digitIndex}`);
        if (!digitEl) return;

        if (numIndex < 0 || numIndex > 13) numIndex = 10;
        const font = this.numbers[numIndex];

        this.segmentKeys.forEach((segKey, idx) => {
            const segEl = digitEl.querySelector(`.seg-${segKey}`);
            if (!segEl) return;

            const isLit = font[idx] === 1;
            if (isLit) {
                segEl.classList.add('lit');
                segEl.style.setProperty('--seg-color', colorHex);
                if (customGlowColor) {
                    segEl.style.setProperty('--seg-glow', customGlowColor);
                } else {
                    segEl.style.removeProperty('--seg-glow');
                }
            } else {
                segEl.classList.remove('lit');
                segEl.style.removeProperty('--seg-color');
                segEl.style.removeProperty('--seg-glow');
            }
        });
    }

    // Render Games & Sets center module dots
    drawGamesAndSets(games1, games2, sets1, sets2, swapped, customColor1 = null, customColor2 = null) {
        const theme = this.themes[this.currentTheme];
        
        // Colors follow sides (Swapped: Left is Team 2, Right is Team 1)
        const leftColor = customColor1 || (swapped ? theme.team2.main : theme.team1.main);
        const rightColor = customColor2 || (swapped ? theme.team1.main : theme.team2.main);

        const leftGlow = swapped ? theme.team2.glow : theme.team1.glow;
        const rightGlow = swapped ? theme.team1.glow : theme.team2.glow;

        const leftGames = swapped ? games2 : games1;
        const rightGames = swapped ? games1 : games2;

        const leftSets = swapped ? sets2 : sets1;
        const rightSets = swapped ? sets1 : sets2;

        // 1. Sets (2 dots per side at top)
        for (let s = 1; s <= 2; s++) {
            const dotL = document.getElementById(`set-dot-l-${s}`);
            const dotR = document.getElementById(`set-dot-r-${s}`);

            if (dotL) {
                if (s <= leftSets) {
                    dotL.classList.add('lit');
                    dotL.style.setProperty('--dot-color', leftColor);
                    dotL.style.setProperty('--dot-glow', leftGlow);
                } else {
                    dotL.classList.remove('lit');
                }
            }

            if (dotR) {
                if (s <= rightSets) {
                    dotR.classList.add('lit');
                    dotR.style.setProperty('--dot-color', rightColor);
                    dotR.style.setProperty('--dot-glow', rightGlow);
                } else {
                    dotR.classList.remove('lit');
                }
            }
        }

        // 2. Games (9 dots per side at bottom)
        for (let g = 1; g <= 9; g++) {
            const dotL = document.getElementById(`game-dot-l-${g}`);
            const dotR = document.getElementById(`game-dot-r-${g}`);

            if (dotL) {
                if (g <= leftGames) {
                    dotL.classList.add('lit');
                    dotL.style.setProperty('--dot-color', leftColor);
                    dotL.style.setProperty('--dot-glow', leftGlow);
                } else {
                    dotL.classList.remove('lit');
                }
            }

            if (dotR) {
                if (g <= rightGames) {
                    dotR.classList.add('lit');
                    dotR.style.setProperty('--dot-color', rightColor);
                    dotR.style.setProperty('--dot-glow', rightGlow);
                } else {
                    dotR.classList.remove('lit');
                }
            }
        }

        // 3. Center Labels ("SETS" & "GAMES")
        const setsLabel = document.getElementById('labelSets');
        const gamesLabel = document.getElementById('labelGames');
        if (setsLabel) setsLabel.classList.add('illuminated');
        if (gamesLabel) gamesLabel.classList.add('illuminated');
    }

    // Main display update matching ESP32 firmware
    displayScore(scoreStr, swapped, games1 = 0, games2 = 0, sets1 = 0, sets2 = 0) {
        if (this.isAnimating && !this.attractMode) return;

        const theme = this.themes[this.currentTheme];
        const leftColor = swapped ? theme.team2.main : theme.team1.main;
        const rightColor = swapped ? theme.team1.main : theme.team2.main;
        const leftGlow = swapped ? theme.team2.glow : theme.team1.glow;
        const rightGlow = swapped ? theme.team1.glow : theme.team2.glow;

        let formatted = scoreStr || "0000";
        while (formatted.length < 4) formatted += " ";

        // Team 1 / Left Digits (0 & 1)
        for (let d = 0; d < 2; d++) {
            const fontIdx = this.charToFontIndex(formatted[d], d, formatted);
            this.drawDigit(d, fontIdx, leftColor, true, leftGlow);
        }

        // Team 2 / Right Digits (2 & 3)
        for (let d = 2; d < 4; d++) {
            const fontIdx = this.charToFontIndex(formatted[d], d, formatted);
            this.drawDigit(d, fontIdx, rightColor, true, rightGlow);
        }

        // Center Colon
        const colonTop = document.getElementById('colonDotTop');
        const colonBot = document.getElementById('colonDotBot');
        const colonColor = '#e2e8f0';
        if (colonTop) colonTop.style.setProperty('--colon-color', colonColor);
        if (colonBot) colonBot.style.setProperty('--colon-color', colonColor);

        // Center Games & Sets Panel
        this.drawGamesAndSets(games1, games2, sets1, sets2, swapped);
    }

    // =========================================================================
    // SIGNATURE ANIMATION: Side Swap Wipe Animation
    // LED sweep wipe across all 5 docked panels when teams swap court ends!
    // =========================================================================
    animateSideSwap(oldScore, newScore, oldSwapped, newSwapped, games1, games2, sets1, sets2, onComplete) {
        this.isAnimating = true;
        if (window.soundEngine) window.soundEngine.playSideSwap();

        const board = document.getElementById('padelScoreboard');
        if (board) board.classList.add('swapping-effect');

        const totalSteps = 24;
        let step = 0;

        const theme = this.themes[this.currentTheme];

        // All active segments & dots in horizontal order (Left -> Right)
        const leftPanels = [0, 1];
        const rightPanels = [2, 3];

        const wipeInterval = setInterval(() => {
            step++;

            if (step <= 10) {
                // Phase 1: Wipe Out from left to right with a glowing electric white curtain
                const wipePos = step / 10.0;
                
                // Dim left digits
                if (wipePos > 0.2) this.drawDigit(0, 10, '#000', false);
                if (wipePos > 0.4) this.drawDigit(1, 10, '#000', false);
                
                // Dim center dots
                if (wipePos > 0.5) {
                    this.drawGamesAndSets(0, 0, 0, 0, oldSwapped, '#ffffff', '#ffffff');
                }

                // Dim right digits
                if (wipePos > 0.7) this.drawDigit(2, 10, '#000', false);
                if (wipePos > 0.9) this.drawDigit(3, 10, '#000', false);

            } else if (step <= 14) {
                // Phase 2: Brief pause & energy flash in center
                this.drawGamesAndSets(0, 0, 0, 0, newSwapped);

            } else if (step <= 24) {
                // Phase 3: Wipe In with swapped colors & new scores
                const revealPos = (step - 14) / 10.0;
                const leftColor = newSwapped ? theme.team2.main : theme.team1.main;
                const rightColor = newSwapped ? theme.team1.main : theme.team2.main;

                let scoreStr = newScore || "0000";
                while (scoreStr.length < 4) scoreStr += " ";

                if (revealPos >= 0.2) {
                    const f0 = this.charToFontIndex(scoreStr[0], 0, scoreStr);
                    this.drawDigit(0, f0, leftColor, true);
                }
                if (revealPos >= 0.4) {
                    const f1 = this.charToFontIndex(scoreStr[1], 1, scoreStr);
                    this.drawDigit(1, f1, leftColor, true);
                }
                if (revealPos >= 0.6) {
                    this.drawGamesAndSets(games1, games2, sets1, sets2, newSwapped);
                }
                if (revealPos >= 0.8) {
                    const f2 = this.charToFontIndex(scoreStr[2], 2, scoreStr);
                    this.drawDigit(2, f2, rightColor, true);
                }
                if (revealPos >= 1.0) {
                    const f3 = this.charToFontIndex(scoreStr[3], 3, scoreStr);
                    this.drawDigit(3, f3, rightColor, true);
                }
            }

            if (step >= totalSteps) {
                clearInterval(wipeInterval);
                this.isAnimating = false;
                if (board) board.classList.remove('swapping-effect');
                this.displayScore(newScore, newSwapped, games1, games2, sets1, sets2);
                if (onComplete) onComplete();
            }
        }, 35);
    }

    // =========================================================================
    // BLE Connect 3x Flash Animation (matches ESP32 firmware triggerConnectAnimation)
    // =========================================================================
    animateBLEConnect(currentScore, swapped, games1, games2, sets1, sets2, onComplete) {
        this.isAnimating = true;
        if (window.soundEngine) window.soundEngine.playBLEConnect();

        let flashCount = 0;
        const bleColor = '#00e5ff';
        const bleGlow = 'rgba(0, 229, 255, 0.95)';

        const flashInterval = setInterval(() => {
            flashCount++;
            const isOn = flashCount % 2 === 1;

            if (isOn) {
                // All 4 digits show 8888 in bright BLE Cyan
                for (let d = 0; d < 4; d++) {
                    this.drawDigit(d, 8, bleColor, true, bleGlow);
                }
                // All Games & Sets dots lit in bright Cyan
                this.drawGamesAndSets(9, 9, 2, 2, swapped, bleColor, bleColor);
            } else {
                this.renderBlankScoreboard();
            }

            if (flashCount >= 6) { // 3 full on-off flashes
                clearInterval(flashInterval);
                this.isAnimating = false;
                this.displayScore(currentScore, swapped, games1, games2, sets1, sets2);
                if (onComplete) onComplete();
            }
        }, 150);
    }

    // =========================================================================
    // Game Won Celebration Pulse
    // =========================================================================
    animateGameWon(winningTeam, currentScore, swapped, games1, games2, sets1, sets2, onComplete) {
        this.isAnimating = true;
        if (window.soundEngine) window.soundEngine.playGameWon(winningTeam === 1 ? 'Team 1' : 'Team 2');

        const theme = this.themes[this.currentTheme];
        const isLeftWinner = (!swapped && winningTeam === 1) || (swapped && winningTeam === 2);
        const winColor = winningTeam === 1 ? theme.team1.main : theme.team2.main;
        const winGlow = winningTeam === 1 ? theme.team1.glow : theme.team2.glow;

        const targetDigits = isLeftWinner ? [0, 1] : [2, 3];

        let pulse = 0;
        const pulseTimer = setInterval(() => {
            pulse++;
            const high = pulse % 2 === 1;

            targetDigits.forEach(d => {
                this.drawDigit(d, high ? 8 : 10, winColor, high, high ? winGlow : null);
            });

            // Center game dots cascade
            this.drawGamesAndSets(games1, games2, sets1, sets2, swapped);

            if (pulse >= 6) {
                clearInterval(pulseTimer);
                this.isAnimating = false;
                this.displayScore(currentScore, swapped, games1, games2, sets1, sets2);
                if (onComplete) onComplete();
            }
        }, 120);
    }

    // =========================================================================
    // Set Won Celebration Animation (Waterfall Ladder Cascade)
    // =========================================================================
    animateSetWon(winningTeam, currentScore, swapped, games1, games2, sets1, sets2, onComplete) {
        this.isAnimating = true;
        if (window.soundEngine) window.soundEngine.playSetWon();

        const theme = this.themes[this.currentTheme];
        const winColor = winningTeam === 1 ? theme.team1.main : theme.team2.main;

        let frame = 0;
        const waterfallTimer = setInterval(() => {
            frame++;

            // Waterfall down the ladder dots
            const activeDot = frame % 10;
            for (let g = 1; g <= 9; g++) {
                const dotL = document.getElementById(`game-dot-l-${g}`);
                const dotR = document.getElementById(`game-dot-r-${g}`);
                const isWave = Math.abs(g - activeDot) <= 1;

                if (dotL) {
                    if (isWave) {
                        dotL.classList.add('lit');
                        dotL.style.setProperty('--dot-color', winColor);
                    } else {
                        dotL.classList.remove('lit');
                    }
                }
                if (dotR) {
                    if (isWave) {
                        dotR.classList.add('lit');
                        dotR.style.setProperty('--dot-color', winColor);
                    } else {
                        dotR.classList.remove('lit');
                    }
                }
            }

            if (frame >= 20) {
                clearInterval(waterfallTimer);
                this.isAnimating = false;
                this.displayScore(currentScore, swapped, games1, games2, sets1, sets2);
                if (onComplete) onComplete();
            }
        }, 70);
    }

    // =========================================================================
    // Championship Match Victory Light Show
    // =========================================================================
    animateMatchWon(winningTeam, swapped, sets1, sets2) {
        this.isAnimating = true;
        if (window.soundEngine) window.soundEngine.playMatchWon();

        const banner = document.getElementById('victoryOverlay');
        const winnerNameEl = document.getElementById('victoryWinnerName');
        if (banner && winnerNameEl) {
            winnerNameEl.textContent = winningTeam === 1 ? 'TEAM 1 (BLUE) WINS!' : 'TEAM 2 (RED) WINS!';
            banner.classList.add('active');
        }

        let hue = 0;
        let count = 0;

        if (this.animationTimer) clearInterval(this.animationTimer);

        this.animationTimer = setInterval(() => {
            hue = (hue + 15) % 360;
            count++;

            const rainbowHex = `hsl(${hue}, 100%, 55%)`;
            const rainbowGlow = `hsla(${hue}, 100%, 55%, 0.8)`;

            for (let d = 0; d < 4; d++) {
                this.drawDigit(d, 8, rainbowHex, true, rainbowGlow);
            }
            this.drawGamesAndSets(9, 9, 2, 2, swapped, rainbowHex, rainbowHex);

            if (count > 60) { // 6 seconds of victory lightshow
                clearInterval(this.animationTimer);
                this.isAnimating = false;
                this.displayScore("    ", swapped, 0, 0, sets1, sets2);
            }
        }, 100);
    }

    // =========================================================================
    // Attract / Showroom Rainbow Color Wave
    // =========================================================================
    startAttractMode() {
        this.attractMode = true;
        if (this.animationTimer) clearInterval(this.animationTimer);

        this.animationTimer = setInterval(() => {
            this.attractHue = (this.attractHue + 4) % 360;

            for (let d = 0; d < 4; d++) {
                const digitHue = (this.attractHue + d * 45) % 360;
                const col = `hsl(${digitHue}, 100%, 55%)`;
                this.drawDigit(d, 8, col, true);
            }

            const ladderHue1 = (this.attractHue + 90) % 360;
            const ladderHue2 = (this.attractHue + 270) % 360;
            this.drawGamesAndSets(9, 9, 2, 2, false, `hsl(${ladderHue1}, 100%, 55%)`, `hsl(${ladderHue2}, 100%, 55%)`);
        }, 50);
    }

    stopAttractMode() {
        this.attractMode = false;
        if (this.animationTimer) {
            clearInterval(this.animationTimer);
            this.animationTimer = null;
        }
    }
}

window.scoreboardRenderer = new ScoreboardRenderer();
