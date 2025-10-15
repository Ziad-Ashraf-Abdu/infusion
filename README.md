# Infusion Pump Monitor 🩺✨

Welcome to the Infusion Pump Monitor, a modern Flutter application designed to bring real-time patient monitoring into the 21st century. This isn't just another boring medical app; it's a beautifully designed, intuitive interface that connects directly to hardware, providing critical data in a calm, clear, and tactile way.

This project bridges the gap between physical medical devices (like an Arduino-controlled infusion pump) and a high-quality user experience for healthcare professionals.

## See It In Action\!

Our UI is built with a "Soft UI" (Neumorphic) philosophy, focusing on a tactile and approachable feel. Plus, with a seamless toggle between light and dark modes, it's easy on the eyes, day or night.

| Light Mode ☀️                                               | Dark Mode 🌙                                              |
| ----------------------------------------------------------- | --------------------------------------------------------- |
|  |  |
*(Note: Replace these with actual screenshots of your app\!)*

-----

## Features at a Glance 📋

  * **Real-Time Monitoring:** Patient data is streamed from a local server, through a cloud hub, and displayed in the app with live updates.
  * **Soft & Tactile UI:** A beautiful Neumorphic-inspired design that makes UI elements feel physical and easy to interact with.
  * **Light & Dark Themes:** A user-selectable theme toggle to switch between a bright, clean interface and a sleek, eye-friendly dark mode.
  * **QR Code Onboarding:** Quickly add new patients by scanning a QR code containing their initial setup information (Patient ID, Drug Name, Ideal Dose Rate).
  * **Critical Visual Alerts:** An unmissable **Air Bubble Warning** takes over the patient card with a pulsing shadow and clear text, ensuring critical events get immediate attention.
  * **Animated Indicators:** The liquid level indicator is not just a static bar; it animates smoothly between states, providing a more organic feel.
  * **Inspired by Healthcare Professionals:** The layout is designed for clarity and quick glances, emphasizing the most critical data (like the current dose rate) without clutter.

-----

## The Tech Stack 🛠️

This project is more than just a Flutter app; it's a full-stack solution involving a few key components working in harmony.

  * **Frontend (Mobile App):**

      * **Flutter & Dart:** For creating a beautiful, cross-platform mobile experience from a single codebase.
      * `google_fonts`: For clean and professional typography.
      * `http`: For polling the server to get patient data.
      * `web_socket_channel`: For real-time, two-way communication of commands and flags.
      * `mobile_scanner`: For the QR code scanning functionality.

  * **Backend (Cloud Hub):**

      * **Python & FastAPI:** A high-performance Python framework for building our robust API and WebSocket hub.
      * **Hugging Face Spaces:** For easy and free hosting of our FastAPI backend.

  * **Bridge (Local Server):**

      * **Python:** A simple script that acts as the bridge.
      * `pyserial`: To communicate with the Arduino/hardware via a COM port.
      * `requests` & `websockets`: To talk to our cloud backend.

-----

## System Architecture 🏗️

The system is designed to be decoupled and scalable. Each part has a very specific job.

`[Flutter App] 📲 <==> [Hugging Face Server ☁️] <==> [Local Python Server 💻] <==> [Arduino/Pump 🔌]`

1.  **The Arduino/Pump:** The physical hardware that measures the data and sends it over a serial connection.
2.  **The Local Server:** Runs on a computer connected to the Arduino. It reads the raw serial data, formats it into JSON, and sends it to the cloud. It also listens for commands from the cloud to send back to the Arduino.
3.  **The Hugging Face Server:** The central hub. It stores the latest patient data and acts as a WebSocket relay, passing messages between the app and the local server. It ensures the app and hardware don't need to know about each other's IP addresses.
4.  **The Flutter App:** The user's interface. It fetches data from the cloud hub and sends commands back through it.

-----

## Getting Started 🚀

Ready to run the project yourself? Here’s how to get everything set up.

### Prerequisites

  * Flutter SDK installed.
  * Python 3.7+ installed.
  * An IDE like VS Code.
  * An Arduino or a serial port simulator for testing the local server.

### 1\. Set Up the Hugging Face Server

  * Create a new **Docker** Space on [Hugging Face](https://huggingface.co/spaces).
  * Upload the `app.py`, `requirements.txt`, and `Dockerfile` from our project.
  * Once it's built, copy your Space URL (e.g., `yourname-yourspace.hf.space`).

### 2\. Set Up the Local Server

  * Open a terminal and install the required Python libraries:
    ```bash
    pip install pyserial requests websockets
    ```
  * Open `local_server.py` and update the `HF_SERVER_URL` with your Hugging Face Space URL.
  * Make sure the `SERIAL_PORT` is set to the correct COM port your Arduino is on.

### 3\. Set Up the Flutter App

  * Open `services/server_service.dart`.
  * Update the `_huggingFaceSpaceUrl` variable with your Hugging Face Space URL.
  * Run `flutter pub get` to install the app's dependencies.

### 4\. Run Everything\!

1.  Start the **Local Server** from your terminal: `python local_server.py`
2.  Ensure your **Hugging Face Space** is running.
3.  Launch the **Flutter App**: `flutter run`

You're all set\! Now you can scan a (simulated) QR code and see the real-time data flow through the entire system.

-----

## License 📜

This project is licensed under the MIT License.

\<details\>
\<summary\>Click to view license\</summary\>

```text
Copyright (c) 2025 [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

\</details\>
