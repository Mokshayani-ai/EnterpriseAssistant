from flask import Flask, request, jsonify
from PIL import Image
import os
import subprocess

app = Flask(__name__)

# Path to save uploaded images
UPLOAD_FOLDER = 'D:/projects/SIH/uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/ocr', methods=['POST'])
def ocr():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Save the image with a full path
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)
        file.save(file_path)

        # Load the image using PIL to ensure it's an image
        img = Image.open(file_path)

        # Build the complete path and run the Ollama LLaVA model
        llava_command = ['ollama', 'run', 'llava', 'what is written in image', file_path]

        # Using Popen to avoid console interaction issues and suppress output
        with subprocess.Popen(
            llava_command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True,  # This ensures the command runs in a shell
            creationflags=subprocess.CREATE_NO_WINDOW  # This prevents the console window from being created (Windows-specific)
        ) as process:

            # Capture stdout and stderr
            stdout, stderr = process.communicate()

            # Handle the output from LLaVA model
            if process.returncode == 0:
                # Decode and filter unwanted lines
                llava_response = stdout.decode('utf-8')
                filtered_response = '\n'.join(
                    line for line in llava_response.splitlines() 
                    if 'failed to get console mode for' not in line
                ).strip()
                
                print("Filtered LLaVA model response:", filtered_response)
                return jsonify({'text': filtered_response}), 200
            else:
                # Print error for debugging
                print("LLaVA model error:", stderr.decode('utf-8'))
                return jsonify({'error': 'Failed to process image'}), 500

    except Exception as e:
        print("Exception:", str(e))  # Print exception details for debugging
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
