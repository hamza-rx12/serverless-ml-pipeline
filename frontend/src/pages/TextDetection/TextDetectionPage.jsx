import { useState } from 'react'
import { Link } from 'react-router-dom'
import ImageUpload from '../../components/ImageUpload'
import ResultsDisplay from '../../components/ResultsDisplay'
import './TextDetectionPage.css'

function TextDetectionPage() {
  const [uploadedImageId, setUploadedImageId] = useState(null)

  const handleUploadSuccess = (imageId) => {
    setUploadedImageId(imageId)
  }

  return (
    <div className="service-page">
      <div className="service-header">
        <Link to="/" className="back-link">← Back to Services</Link>
        <h2>📄 Text Detection (OCR)</h2>
        <p>Extract text from images and documents</p>
      </div>

      <div className="service-content">
        <div className="upload-section">
          <ImageUpload
            onUploadSuccess={handleUploadSuccess}
            service="text-detection"
          />
        </div>

        <div className="results-section">
          <ResultsDisplay
            imageId={uploadedImageId}
            service="text-detection"
          />
        </div>
      </div>
    </div>
  )
}

export default TextDetectionPage
