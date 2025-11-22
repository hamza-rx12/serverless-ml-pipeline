import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'
import TextDetectionPage from './pages/TextDetection/TextDetectionPage'
import FaceDetectionPage from './pages/FaceDetection/FaceDetectionPage'
import ObjectDetectionPage from './pages/ObjectDetection/ObjectDetectionPage'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <div className="app">
        <header className="app-header">
          <h1>AWS Image Analysis Platform</h1>
          <p className="subtitle">Choose a service to analyze your images</p>
        </header>

        <main className="app-main">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/text-detection" element={<TextDetectionPage />} />
            <Route path="/face-detection" element={<FaceDetectionPage />} />
            <Route path="/object-detection" element={<ObjectDetectionPage />} />
          </Routes>
        </main>

        <footer className="app-footer">
          <p>Powered by AWS Lambda, Step Functions, Rekognition & DynamoDB</p>
        </footer>
      </div>
    </BrowserRouter>
  )
}

export default App
