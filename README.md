# ISL Translator 

A real-time iOS application that translates **Indian Sign Language (ISL)** gestures into text and speech using computer vision and machine learning.

## Overview

ISL Translator is an innovative accessibility tool designed to bridge communication gaps by converting Indian Sign Language gestures captured via device camera into English text and audio. The app uses advanced hand landmark detection and gesture classification to recognize and translate a wide range of ISL gestures in real-time.

## Features

✨ **Real-Time Gesture Recognition**
- Live camera feed with continuous hand gesture detection
- Instant gesture-to-text translation
- Confidence scoring for each recognized gesture

🎯 **Comprehensive Gesture Support**
- All 22 ISL letters (A-Z, excluding J and Q)
- Numeric gestures (0-9)
- Common words (Hello, Thank You, Yes, No, Help, Water, Food, Sorry, I Love You)
- Organized by gesture category (letters, numbers, words)

🔊 **Audio Output**
- Text-to-speech conversion for translated gestures
- Support for audio playback of recognized text

📋 **Translation History**
- View all recognized gestures with timestamps
- Track confidence levels for each translation
- Organized history panel for easy reference

👁️ **Visual Feedback**
- Hand pose overlay showing detected hand landmarks
- Confidence meter displaying recognition accuracy
- Real-time visual indicators for gesture detection

🎨 **User-Friendly Interface**
- Split-view layout with sidebar and main camera view
- Intuitive gesture selection and history browsing
- Clean SwiftUI-based modern design

## Technical Architecture

### Core Components

**Services:**
- **CameraService**: Manages camera input and frame capture
- **HandTrackingService**: Detects hand landmarks from video frames using Vision framework
- **GestureClassifier**: Classifies hand poses into ISL gestures based on feature vectors
- **SentenceBuilder**: Constructs coherent sentences from individual gesture translations
- **SpeechService**: Handles text-to-speech conversion

**Models:**
- **GestureResult**: Represents a recognized gesture with confidence score
- **HandLandmarks**: Stores 21 hand keypoints for pose analysis
- **TranslationEntry**: Records gesture translation with timestamp and confidence

**Views:**
- **MainCameraView**: Primary view with live camera feed
- **HandOverlayView**: Visualizes detected hand landmarks
- **ConfidenceMeterView**: Displays recognition confidence level
- **HistoryPanel**: Shows translation history
- **TranslationPanel**: Displays current translation
- **SidebarView**: Navigation and controls

### Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Vision Framework**: Hand pose estimation and landmark detection
- **AVFoundation**: Camera access and audio playback
- **Foundation**: Core data handling and utilities

## Requirements

- iOS 16.0 or later
- Camera access permission
- Swift 5.9+
- Xcode 15.0+

## Installation

### Prerequisites
- Xcode 15.0 or later installed on your Mac
- An iOS device with camera access

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Aryan-en/ISL_translator.git
   cd ISL_translator
   ```

2. **Open the project**
   ```bash
   open ISL_translator.xcodeproj
   ```

3. **Select your development team**
   - In Xcode, select the project in the navigator
   - Under "Signing & Capabilities", select your team from the dropdown

4. **Build and run**
   - Select your target device (physical device recommended for best performance)
   - Press `Cmd + R` or click the Play button to build and run

## Usage

1. **Launch the App**
   - Open ISL Translator on your iOS device
   - Grant camera permission when prompted

2. **Perform Gestures**
   - Position your hand in front of the camera
   - The app will automatically detect and recognize ISL gestures
   - View the confidence level in the confidence meter

3. **View Translations**
   - Recognized gestures appear in the Translation Panel
   - Tap to hear the audio pronunciation (if available)
   - View full history in the History Panel from the sidebar

4. **Manage History**
   - Access the sidebar to view translation history
   - Clear or export translations as needed

## Project Structure

```
ISL_translator/
├── ISL_translator/
│   ├── ContentView.swift              # Main app container
│   ├── ISL_translatorApp.swift        # App entry point
│   ├── Info.plist                     # App configuration
│   ├── Models/
│   │   ├── GestureResult.swift        # Gesture recognition data
│   │   ├── HandLandmarks.swift        # Hand pose keypoints
│   │   └── TranslationEntry.swift     # Translation history entry
│   ├── Services/
│   │   ├── CameraService.swift        # Camera frame capture
│   │   ├── HandTrackingService.swift  # Hand landmark detection
│   │   ├── GestureClassifier.swift    # Gesture recognition logic
│   │   ├── SentenceBuilder.swift      # Sentence construction
│   │   └── SpeechService.swift        # Text-to-speech
│   ├── ViewModels/
│   │   └── CameraViewModel.swift      # Main view model
│   └── Views/
│       ├── MainCameraView.swift       # Primary camera view
│       ├── CameraPreviewView.swift    # Camera frame display
│       ├── HandOverlayView.swift      # Hand landmarks overlay
│       ├── ConfidenceMeterView.swift  # Confidence indicator
│       ├── HistoryPanel.swift         # Translation history
│       ├── TranslationPanel.swift     # Current translation display
│       └── SidebarView.swift          # Navigation sidebar
├── ISL_translatorTests/               # Unit tests
├── ISL_translatorUITests/             # UI tests
└── ISL_translator.xcodeproj/          # Xcode project configuration
```

## How It Works

### Gesture Recognition Pipeline

1. **Hand Detection**: The Vision framework detects hands in the camera frame
2. **Landmark Extraction**: 21 hand keypoints are extracted from the detected hand
3. **Feature Extraction**: Hand features (finger extension, position, angles) are computed
4. **Classification**: The GestureClassifier matches features to known ISL gestures
5. **Translation**: Recognized gestures are converted to text and optionally audio

### Supported Gestures

**Letters**: A, B, C, D, E, F, G, H, I, K, L, M, N, O, R, S, T, U, V, W, X, Y

**Numbers**: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

**Common Words**:
- Hello
- Thank You
- Yes
- No
- Help
- Water
- Food
- Sorry
- I Love You

## Future Enhancements

- [ ] Expand gesture vocabulary with more words and phrases
- [ ] Add machine learning model for improved accuracy
- [ ] Support for two-handed gestures
- [ ] Customizable gesture library
- [ ] Export translations to text/PDF
- [ ] Offline mode support
- [ ] Multi-language output support
- [ ] Gesture recording and playback
- [ ] Community gesture sharing

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request to improve the app.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple Vision Framework documentation
- ISL gesture database and linguistic resources
- SwiftUI community and examples

## Contact & Support

For issues, feature requests, or questions, please open an issue on the GitHub repository.

---

**Made with ❤️ to make communication more accessible**
