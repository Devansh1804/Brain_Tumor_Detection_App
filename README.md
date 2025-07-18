# 🧠 Brain Tumor Detection App

An AI-powered mobile application built using **Flutter**, designed to detect brain tumors from MRI images using a **TensorFlow Lite** model. The app features a clean UI, local inference, and intuitive image upload and detection functionality.

---

## 📱 Features

- 📤 Upload brain MRI images
- 🧠 Local tumor detection using TensorFlow Lite model
- 🔍 Displays confidence level of prediction
- 🎯 Simple, mobile-friendly interface
- 🧾 Scrollable interface with results preview and visual indicators

---

## ⚙️ Technology Stack

- **Android Studio**
- **Flutter**
- **Dart**
- **TensorFlow Lite** (for on-device model inference)

---

## 🚧 Disclaimer

> ⚠️ **Note:** This repository does **not include** the trained machine learning model file (`.tflite`).  
> To download or view the model, please visit my other repository:

🔗 [Tumor_Model_Repository](https://github.com/your-username/tumor-model-repo)

---

## 🔧 Installation & Setup

1. **Clone this repository**
   ```bash
   git clone -b master https://github.com/your-username/Brain_Tumor_Detection_App.git
   cd Brain_Tumor_Detection_App
Open in Android Studio or VS Code

Open the project using Android Studio with Flutter plugin installed

Install dependencies

bash
Copy
Edit
flutter pub get
Add the TensorFlow Lite model

Place your .tflite model file in:

bash
Copy
Edit
assets/tumor_model.tflite
Ensure your pubspec.yaml includes:

yaml
Copy
Edit
assets:
  - assets/tumor_model.tflite
Run the App

Connect your Android device or emulator

Run:

bash
flutter run
