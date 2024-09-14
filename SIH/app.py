from flask import Flask, request, jsonify
from flask_cors import CORS
# Define the Flask app
app = Flask(__name__)
CORS(app)

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json()
    question = data.get('question', '')

    # Respond with a simple message
    response_message = "hello user"

    return jsonify({'response': response_message})

if __name__ == '__main__':
    app.run(debug=True)
