import logging
from flask import Flask, render_template

app = Flask(__name__)

# Logging to file
logging.basicConfig(
    filename='/var/log/flask_app.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)

@app.route("/")
def home():
    app.logger.info("Home page visited")
    return render_template("index.html")

@app.route("/health")
def health():
    app.logger.info("Health check accessed")
    return {"status": "ok"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)