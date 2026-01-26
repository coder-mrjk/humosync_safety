const char index_html[] PROGMEM = R"rawliteral(
<!DOCTYPE HTML>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ESP32-CAM TinyML Stream</title>
  <style>
    :root {
      --primary-color: #00f2fe;
      --secondary-color: #4facfe;
      --bg-color: #121212;
      --card-bg: #1e1e1e;
      --text-color: #ffffff;
      --accent-red: #ff4b1f;
      --accent-green: #11998e;
    }
    body {
      margin: 0;
      padding: 0;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg-color);
      color: var(--text-color);
      display: flex;
      flex-direction: column;
      align-items: center;
      min-height: 100vh;
    }
    h1 {
      margin-top: 20px;
      margin-bottom: 10px;
      background: linear-gradient(to right, var(--secondary-color), var(--primary-color));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      font-size: 2.5rem;
      text-align: center;
    }
    .container {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 20px;
      padding: 20px;
      width: 100%;
      max-width: 1200px;
      box-sizing: border-box;
    }
    .video-container {
      position: relative;
      background: #000;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      border: 1px solid #333;
      min-width: 320px;
      min-height: 240px;
    }
    img {
      display: block;
      width: 100%;
      height: auto;
      max-width: 640px;
    }
    .results-container {
      flex: 1;
      min-width: 300px;
      background: var(--card-bg);
      padding: 24px;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .prediction-card {
      text-align: center;
      padding: 20px;
      background: rgba(255,255,255,0.05);
      border-radius: 12px;
      margin-bottom: 10px;
    }
    .main-label {
      font-size: 2rem;
      font-weight: 800;
      letter-spacing: 1px;
      margin: 0;
      transition: color 0.3s ease;
    }
    .confidence-label {
      font-size: 0.9rem;
      color: #aaa;
      margin-top: 5px;
    }
    .bar-container {
      margin-top: 10px;
    }
    .bar-row {
      display: flex;
      align-items: center;
      margin-bottom: 12px;
    }
    .label-text {
      width: 80px;
      font-weight: 600;
      font-size: 0.9rem;
    }
    .progress-bg {
      flex: 1;
      height: 10px;
      background: #333;
      border-radius: 5px;
      overflow: hidden;
      margin-left: 10px;
      position: relative;
    }
    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, var(--secondary-color), var(--primary-color));
      width: 0%;
      transition: width 0.3s ease;
      border-radius: 5px;
    }
    .value-text {
      width: 40px;
      text-align: right;
      font-size: 0.85rem;
      color: #ccc;
      margin-left: 10px;
    }
    
    /* Dynamic colors for specific detections */
    .detected-human { color: var(--accent-green); }
    .detected-animal { color: var(--accent-red); }
    .detected-other { color: var(--text-color); }

    .status-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background-color: #555;
      display: inline-block;
      margin-right: 8px;
    }
    .status-active {
      background-color: var(--accent-green);
      box-shadow: 0 0 10px var(--accent-green);
    }

    footer {
      margin-top: auto;
      padding: 20px;
      font-size: 0.8rem;
      color: #666;
      text-align: center;
    }
  </style>
</head>
<body>
  <h1>HumoSync Safety AI</h1>
  
  <div class="container">
    <div class="video-container">
      <img src="/stream" id="stream" alt="Live Stream">
    </div>

    <div class="results-container">
      <div style="display: flex; align-items: center; margin-bottom: 10px;">
        <span class="status-dot status-active"></span>
        <span style="font-size: 0.9rem; font-weight: 600; color: #aaa;">LIVE INFERENCE</span>
      </div>

      <div class="prediction-card">
        <h2 class="main-label" id="mainLabel">DETECTING...</h2>
        <div class="confidence-label" id="mainConfidence">0% Confidence</div>
      </div>

      <div class="bar-container" id="bars">
        <!-- Bars will be injected here or updated via JS -->
        <div class="bar-row">
          <span class="label-text">Human</span>
          <div class="progress-bg"><div class="progress-fill" id="bar-human"></div></div>
          <span class="value-text" id="val-human">0%</span>
        </div>
        <div class="bar-row">
          <span class="label-text">Animal</span>
          <div class="progress-bg"><div class="progress-fill" id="bar-animal" style="background: linear-gradient(90deg, #ff9966, #ff5e62);"></div></div>
          <span class="value-text" id="val-animal">0%</span>
        </div>
        <div class="bar-row">
          <span class="label-text">Other</span>
          <div class="progress-bg"><div class="progress-fill" id="bar-other" style="background: linear-gradient(90deg, #757f9a, #d7dde8);"></div></div>
          <span class="value-text" id="val-other">0%</span>
        </div>
      </div>

      <div style="margin-top: 20px; font-size: 0.8rem; color: #666; text-align: center;">
        Inference Time: <span id="time">0</span> ms
      </div>
    </div>
  </div>

  <footer>
    Powered by TinyML & ESP32-CAM | HumoSync Safety Project
  </footer>

<script>
  setInterval(function() {
    fetch('/status')
      .then(response => response.json())
      .then(data => {
        // Update Main Label
        const mainLabel = document.getElementById('mainLabel');
        const mainConf = document.getElementById('mainConfidence');
        
        let highest = 0;
        let label = "UNKNOWN";
        let className = "detected-other";

        // Map server implementation to these keys
        // Assuming data = { "human": 90, "animal": 5, "other": 5, "time": 120 }
        
        const human = data.human || 0;
        const animal = data.animal || 0;
        const other = data.other || 0;

        // Update bars
        document.getElementById('bar-human').style.width = human + '%';
        document.getElementById('val-human').innerText = human + '%';
        
        document.getElementById('bar-animal').style.width = animal + '%';
        document.getElementById('val-animal').innerText = animal + '%';
        
        document.getElementById('bar-other').style.width = other + '%';
        document.getElementById('val-other').innerText = other + '%';

        document.getElementById('time').innerText = data.time || 0;

        // Determine winner
        if (human > animal && human > other) {
          label = "HUMAN DETECTED";
          className = "detected-human";
          highest = human;
        } else if (animal > human && animal > other) {
          label = "ANIMAL DETECTED";
          className = "detected-animal";
          highest = animal;
        } else {
          label = "OTHERS";
          className = "detected-other";
          highest = other;
        }

        mainLabel.innerText = label;
        mainLabel.className = "main-label " + className;
        mainConf.innerText = highest + "% Confidence";
      })
      .catch(console.error);
  }, 500); // Fetch every 500ms
</script>
</body>
</html>
)rawliteral";
