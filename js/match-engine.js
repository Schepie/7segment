// ==============================================================================
// Padel Match Scoring & Simulation Engine
// Implements official Padel rules, Tie-Breaks, Golden Point, Side-Swaps & Auto-Demo
// ==============================================================================

class PadelMatchEngine {
    constructor() {
        this.resetMatch();

        this.goldenPointMode = false; // false = Advantage (Ad-40), true = Punto de Oro (Deciding point at 40-40)
        this.autoPlayActive = false;
        this.autoPlaySpeed = 1.0; // 1x, 2x, 4x
        this.autoPlayTimer = null;

        this.history = [];
    }

    resetMatch() {
        this.stopAutoPlay();

        this.points1 = 0; // 0=00, 1=15, 2=30, 3=40, 4=Ad
        this.points2 = 0;
        
        this.games1 = 0;
        this.games2 = 0;

        this.sets1 = 0;
        this.sets2 = 0;

        this.isTieBreak = false;
        this.tieBreakPoints1 = 0;
        this.tieBreakPoints2 = 0;

        this.isSwitched = false; // true = Team 2 on Left, Team 1 on Right
        this.matchOver = false;
        this.winningTeam = null;

        this.history = [];
        this.saveState();
        this.updateDisplay();
    }

    saveState() {
        this.history.push({
            points1: this.points1,
            points2: this.points2,
            games1: this.games1,
            games2: this.games2,
            sets1: this.sets1,
            sets2: this.sets2,
            isTieBreak: this.isTieBreak,
            tieBreakPoints1: this.tieBreakPoints1,
            tieBreakPoints2: this.tieBreakPoints2,
            isSwitched: this.isSwitched,
            matchOver: this.matchOver,
            winningTeam: this.winningTeam
        });
        if (this.history.length > 50) this.history.shift();
    }

    undo() {
        if (this.history.length <= 1) return;
        this.history.pop(); // Remove current
        const prev = this.history[this.history.length - 1];

        this.points1 = prev.points1;
        this.points2 = prev.points2;
        this.games1 = prev.games1;
        this.games2 = prev.games2;
        this.sets1 = prev.sets1;
        this.sets2 = prev.sets2;
        this.isTieBreak = prev.isTieBreak;
        this.tieBreakPoints1 = prev.tieBreakPoints1;
        this.tieBreakPoints2 = prev.tieBreakPoints2;
        this.isSwitched = prev.isSwitched;
        this.matchOver = prev.matchOver;
        this.winningTeam = prev.winningTeam;

        this.updateDisplay();
        this.logEvent("Score Undone");
    }

    toggleGoldenPoint(enabled) {
        this.goldenPointMode = enabled;
        this.logEvent(`Scoring Mode: ${this.goldenPointMode ? 'Golden Point (Punto de Oro)' : 'Advantage (Ad-40)'}`);
    }

    toggleSideSwap() {
        const prevSwapped = this.isSwitched;
        this.isSwitched = !this.isSwitched;
        this.saveState();

        const scoreStr = this.getFormattedScoreString();
        window.scoreboardRenderer.animateSideSwap(
            scoreStr,
            scoreStr,
            prevSwapped,
            this.isSwitched,
            this.games1,
            this.games2,
            this.sets1,
            this.sets2,
            () => this.updateUI()
        );
        this.logEvent(`Sides Manually Swapped (Switched: ${this.isSwitched})`);
    }

    // Convert internal points to 4-character string matching ESP32 firmware
    getFormattedScoreString() {
        if (this.matchOver) {
            return "----";
        }

        if (this.isTieBreak) {
            // Tie break numbers (e.g. " 4 3", " 7 5", "10 8")
            const p1 = this.tieBreakPoints1;
            const p2 = this.tieBreakPoints2;

            const str1 = p1 < 10 ? ` ${p1}` : `${p1}`;
            const str2 = p2 < 10 ? ` ${p2}` : `${p2}`;

            return this.isSwitched ? `${str2}${str1}` : `${str1}${str2}`;
        }

        const pointMap = ['00', '15', '30', '40', 'Ad'];
        let leftStr = pointMap[this.points1] || '00';
        let rightStr = pointMap[this.points2] || '00';

        // When advantage is active
        if (this.points1 === 4) {
            leftStr = 'Ad';
            rightStr = '40';
        } else if (this.points2 === 4) {
            leftStr = '40';
            rightStr = 'Ad';
        }

        return this.isSwitched ? `${rightStr}${leftStr}` : `${leftStr}${rightStr}`;
    }

    // Add Point to Team (1 or 2)
    addPoint(team) {
        if (this.matchOver) return;

        if (window.soundEngine) {
            window.soundEngine.playPointScore(team === 1);
        }

        if (this.isTieBreak) {
            this.handleTieBreakPoint(team);
        } else {
            this.handleStandardPoint(team);
        }

        this.saveState();
        this.updateDisplay();
    }

    handleStandardPoint(team) {
        const isT1 = team === 1;

        if (this.goldenPointMode) {
            // Punto de Oro: At 40-40, next point wins game immediately
            if (this.points1 === 3 && this.points2 === 3) {
                this.winGame(team);
                return;
            }
        }

        if (isT1) {
            if (this.points1 === 3) { // At 40
                if (this.points2 === 3) { // 40-40 Deuce
                    this.points1 = 4; // Team 1 Advantage
                    this.logEvent("Advantage Team 1");
                } else if (this.points2 === 4) { // Team 2 has Ad
                    this.points2 = 3; // Back to Deuce
                    this.logEvent("Deuce (40-40)");
                } else {
                    this.winGame(1);
                }
            } else if (this.points1 === 4) { // At Ad
                this.winGame(1);
            } else {
                this.points1++;
                this.logEvent(`Team 1 Point -> ${this.getFormattedScoreString()}`);
            }
        } else {
            // Team 2
            if (this.points2 === 3) { // At 40
                if (this.points1 === 3) { // 40-40 Deuce
                    this.points2 = 4; // Team 2 Advantage
                    this.logEvent("Advantage Team 2");
                } else if (this.points1 === 4) { // Team 1 has Ad
                    this.points1 = 3; // Back to Deuce
                    this.logEvent("Deuce (40-40)");
                } else {
                    this.winGame(2);
                }
            } else if (this.points2 === 4) { // At Ad
                this.winGame(2);
            } else {
                this.points2++;
                this.logEvent(`Team 2 Point -> ${this.getFormattedScoreString()}`);
            }
        }
    }

    handleTieBreakPoint(team) {
        if (team === 1) {
            this.tieBreakPoints1++;
        } else {
            this.tieBreakPoints2++;
        }

        this.logEvent(`Tie-Break Point: ${this.tieBreakPoints1} - ${this.tieBreakPoints2}`);

        const p1 = this.tieBreakPoints1;
        const p2 = this.tieBreakPoints2;
        const total = p1 + p2;

        // Side swap every 6 points in tie-break
        if (total > 0 && total % 6 === 0) {
            this.triggerAutomaticSideSwap();
        }

        // Check tie-break win (first to 7 with >= 2 margin)
        if (p1 >= 7 && p1 - p2 >= 2) {
            this.winTieBreak(1);
        } else if (p2 >= 7 && p2 - p1 >= 2) {
            this.winTieBreak(2);
        }
    }

    winGame(team) {
        this.points1 = 0;
        this.points2 = 0;

        if (team === 1) this.games1++;
        else this.games2++;

        this.logEvent(`★ GAME WON by Team ${team}! (Current Games: ${this.games1} - ${this.games2})`);

        // Check for side swap according to official padel rules:
        // After 1st game, and thereafter every 2 games (sum of games is 1, 3, 5, 7, 9...)
        const totalGames = this.games1 + this.games2;
        const shouldSwapSides = (totalGames % 2 === 1);

        // Check if game won clinched a set
        const g1 = this.games1;
        const g2 = this.games2;

        let setWonBy = null;
        if ((g1 >= 6 && g1 - g2 >= 2) || g1 === 7) {
            setWonBy = 1;
        } else if ((g2 >= 6 && g2 - g1 >= 2) || g2 === 7) {
            setWonBy = 2;
        } else if (g1 === 6 && g2 === 6) {
            // Trigger Tie-Break!
            this.isTieBreak = true;
            this.tieBreakPoints1 = 0;
            this.tieBreakPoints2 = 0;
            this.logEvent("🔥 TIE-BREAK ACTIVATED (6 - 6)!");
        }

        if (setWonBy !== null) {
            this.winSet(setWonBy);
        } else {
            // Standard game won celebration + potential side swap
            const scoreStr = this.getFormattedScoreString();
            window.scoreboardRenderer.animateGameWon(
                team,
                scoreStr,
                this.isSwitched,
                this.games1,
                this.games2,
                this.sets1,
                this.sets2,
                () => {
                    if (shouldSwapSides) {
                        this.triggerAutomaticSideSwap();
                    } else {
                        this.updateUI();
                    }
                }
            );
        }
    }

    winTieBreak(team) {
        this.isTieBreak = false;
        if (team === 1) this.games1 = 7;
        else this.games2 = 7;
        this.logEvent(`★ TIE-BREAK WON by Team ${team}!`);
        this.winSet(team);
    }

    winSet(team) {
        if (team === 1) this.sets1++;
        else this.sets2++;

        this.logEvent(`🏆 SET WON by Team ${team}! Sets score: ${this.sets1} - ${this.sets2}`);

        // Check if match won (Best of 3 sets = first to 2 sets)
        if (this.sets1 === 2 || this.sets2 === 2) {
            this.matchOver = true;
            this.winningTeam = team;
            this.logEvent(`🎉 CHAMPIONSHIP VICTORY: TEAM ${team} WINS THE MATCH! 🎉`);
            window.scoreboardRenderer.animateMatchWon(team, this.isSwitched, this.sets1, this.sets2);
            this.stopAutoPlay();
            this.updateUI();
            return;
        }

        // Reset games for next set
        const completedGames1 = this.games1;
        const completedGames2 = this.games2;
        this.games1 = 0;
        this.games2 = 0;
        this.points1 = 0;
        this.points2 = 0;

        const scoreStr = this.getFormattedScoreString();
        window.scoreboardRenderer.animateSetWon(
            team,
            scoreStr,
            this.isSwitched,
            completedGames1,
            completedGames2,
            this.sets1,
            this.sets2,
            () => {
                this.triggerAutomaticSideSwap();
            }
        );
    }

    triggerAutomaticSideSwap() {
        const prevSwapped = this.isSwitched;
        this.isSwitched = !this.isSwitched;
        this.logEvent(`↔ SIDE SWAP (Court end change): Team ${this.isSwitched ? '2 on Left' : '1 on Left'}`);

        const scoreStr = this.getFormattedScoreString();
        window.scoreboardRenderer.animateSideSwap(
            scoreStr,
            scoreStr,
            prevSwapped,
            this.isSwitched,
            this.games1,
            this.games2,
            this.sets1,
            this.sets2,
            () => this.updateUI()
        );
    }

    updateDisplay() {
        const scoreStr = this.getFormattedScoreString();
        window.scoreboardRenderer.displayScore(
            scoreStr,
            this.isSwitched,
            this.games1,
            this.games2,
            this.sets1,
            this.sets2
        );
        this.updateUI();
    }

    updateUI() {
        // Sync Watch simulator
        const watchScoreT1 = document.getElementById('watchScoreT1');
        const watchScoreT2 = document.getElementById('watchScoreT2');
        const watchGames = document.getElementById('watchGames');
        const watchSets = document.getElementById('watchSets');
        const watchSwapBadge = document.getElementById('watchSwapBadge');

        const pMap = ['0', '15', '30', '40', 'Ad'];
        const score1 = this.isTieBreak ? `${this.tieBreakPoints1}` : (pMap[this.points1] || '0');
        const score2 = this.isTieBreak ? `${this.tieBreakPoints2}` : (pMap[this.points2] || '0');

        if (watchScoreT1) watchScoreT1.textContent = score1;
        if (watchScoreT2) watchScoreT2.textContent = score2;
        if (watchGames) watchGames.textContent = `${this.games1} - ${this.games2}`;
        if (watchSets) watchSets.textContent = `Set ${this.sets1 + this.sets2 + 1} (${this.sets1}-${this.sets2})`;
        if (watchSwapBadge) {
            watchSwapBadge.textContent = this.isSwitched ? 'SWAPPED' : 'NORMAL';
            watchSwapBadge.className = this.isSwitched ? 'watch-badge swapped' : 'watch-badge';
        }

        // Sync HUD
        const hudT1Score = document.getElementById('hudT1Score');
        const hudT2Score = document.getElementById('hudT2Score');
        const hudGames = document.getElementById('hudGames');
        const hudSets = document.getElementById('hudSets');

        if (hudT1Score) hudT1Score.textContent = score1;
        if (hudT2Score) hudT2Score.textContent = score2;
        if (hudGames) hudGames.textContent = `${this.games1} - ${this.games2}`;
        if (hudSets) hudSets.textContent = `${this.sets1} - ${this.sets2}`;
    }

    logEvent(text) {
        const logContainer = document.getElementById('eventLogStream');
        if (!logContainer) return;

        const time = new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
        const entry = document.createElement('div');
        entry.className = 'log-entry';
        entry.innerHTML = `<span class="log-time">${time}</span> <span class="log-text">${text}</span>`;
        logContainer.prepend(entry);

        // Keep last 40 entries
        while (logContainer.children.length > 40) {
            logContainer.removeChild(logContainer.lastChild);
        }
    }

    // =========================================================================
    // Automated Match Demo Engine
    // =========================================================================
    startAutoPlay() {
        if (this.autoPlayActive) return;
        this.autoPlayActive = true;
        this.logEvent("▶ Auto-Play Match Demo Started");

        const stepMatch = () => {
            if (!this.autoPlayActive || this.matchOver) {
                this.stopAutoPlay();
                return;
            }

            // Probability weighted point distribution (Team 1 54%, Team 2 46% for exciting match)
            const winner = Math.random() < 0.54 ? 1 : 2;
            this.addPoint(winner);

            const baseDelay = (1400 + Math.random() * 800) / this.autoPlaySpeed;
            this.autoPlayTimer = setTimeout(stepMatch, baseDelay);
        };

        this.autoPlayTimer = setTimeout(stepMatch, 800 / this.autoPlaySpeed);
    }

    stopAutoPlay() {
        this.autoPlayActive = false;
        if (this.autoPlayTimer) {
            clearTimeout(this.autoPlayTimer);
            this.autoPlayTimer = null;
        }
        const btn = document.getElementById('btnAutoPlay');
        if (btn) btn.innerHTML = '<i class="icon-play"></i> Auto Demo Match';
    }

    toggleAutoPlay() {
        if (this.autoPlayActive) {
            this.stopAutoPlay();
            this.logEvent("⏸ Auto-Play Match Demo Paused");
        } else {
            const btn = document.getElementById('btnAutoPlay');
            if (btn) btn.innerHTML = '<i class="icon-pause"></i> Pause Demo';
            this.startAutoPlay();
        }
    }

    setSpeed(speed) {
        this.autoPlaySpeed = speed;
        this.logEvent(`Simulation Speed: ${speed}x`);
    }

    // =========================================================================
    // 1-Click Scenario Loaders for Demos & Presentations
    // =========================================================================
    loadScenario(scenarioName) {
        this.stopAutoPlay();
        const prevSwapped = this.isSwitched;

        switch (scenarioName) {
            case 'side-swap':
                // Set up 1st game win -> triggers immediate side swap wipe
                this.games1 = 0;
                this.games2 = 0;
                this.sets1 = 0;
                this.sets2 = 0;
                this.points1 = 3; // 40
                this.points2 = 2; // 30
                this.isTieBreak = false;
                this.isSwitched = false;
                this.logEvent("🎬 Scenario Loaded: Side Swap Wipe (Game 1 Clinch)");
                this.updateDisplay();
                setTimeout(() => this.addPoint(1), 700);
                break;

            case 'deuce-ad':
                // Deuce battle: 40-40 -> Ad -> Game
                this.games1 = 3;
                this.games2 = 2;
                this.sets1 = 0;
                this.sets2 = 0;
                this.points1 = 3;
                this.points2 = 3;
                this.goldenPointMode = false;
                this.isTieBreak = false;
                this.logEvent("🎬 Scenario Loaded: Deuce & Advantage Thriller (40-40)");
                this.updateDisplay();
                break;

            case 'golden-point':
                // Sudden death golden point
                this.games1 = 4;
                this.games2 = 4;
                this.sets1 = 0;
                this.sets2 = 0;
                this.points1 = 3;
                this.points2 = 3;
                this.goldenPointMode = true;
                this.isTieBreak = false;
                this.logEvent("🎬 Scenario Loaded: Golden Point (Punto de Oro Decider)");
                this.updateDisplay();
                break;

            case 'tie-break':
                // Tie-break at 6-6
                this.games1 = 6;
                this.games2 = 6;
                this.sets1 = 0;
                this.sets2 = 0;
                this.isTieBreak = true;
                this.tieBreakPoints1 = 5;
                this.tieBreakPoints2 = 5;
                this.logEvent("🎬 Scenario Loaded: Tie-Break Climax (5 - 5)");
                this.updateDisplay();
                break;

            case 'set-point':
                // Set point for Team 1 (Games 5-4, 40-15)
                this.games1 = 5;
                this.games2 = 4;
                this.sets1 = 0;
                this.sets2 = 0;
                this.points1 = 3;
                this.points2 = 1;
                this.isTieBreak = false;
                this.logEvent("🎬 Scenario Loaded: Set Point Clinch");
                this.updateDisplay();
                break;

            case 'match-point':
                // Championship match point (Team 1 leads 1 Set to 0, Games 5-3, 40-30)
                this.sets1 = 1;
                this.sets2 = 0;
                this.games1 = 5;
                this.games2 = 3;
                this.points1 = 3;
                this.points2 = 2;
                this.isTieBreak = false;
                this.matchOver = false;
                this.logEvent("🎬 Scenario Loaded: Championship Match Point!");
                this.updateDisplay();
                break;

            case 'ble-flash':
                this.logEvent("🎬 Scenario Loaded: BLE Connect 3x Flash Sequence");
                window.scoreboardRenderer.animateBLEConnect(
                    this.getFormattedScoreString(),
                    this.isSwitched,
                    this.games1,
                    this.games2,
                    this.sets1,
                    this.sets2
                );
                break;

            case 'rainbow-attract':
                this.logEvent("🎬 Scenario Loaded: Rainbow Showroom Attract Mode");
                window.scoreboardRenderer.startAttractMode();
                break;
        }
    }
}

window.matchEngine = new PadelMatchEngine();
