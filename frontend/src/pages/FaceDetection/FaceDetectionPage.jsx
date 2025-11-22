import { useState } from 'react'
import { Link } from 'react-router-dom'
import ImageUpload from '../../components/ImageUpload'
import ResultsDisplay from '../../components/ResultsDisplay'
import '../TextDetection/TextDetectionPage.css'

function FaceDetectionPage() {
  const [uploadedImageId, setUploadedImageId] = useState(null)

  const handleUploadSuccess = (imageId) => {
    setUploadedImageId(imageId)
  }

  return (
    <div className="service-page">
      <div className="service-header">
        <Link to="/" className="back-link">← Back to Services</Link>
        <h2>👤 Face Detection</h2>
        <p>Analyze faces and detect attributes</p>
      </div>

      <div className="service-content">
        <div className="upload-section">
          <ImageUpload
            onUploadSuccess={handleUploadSuccess}
            service="face-detection"
          />
        </div>

        <div className="results-section">
          <ResultsDisplay
            imageId={uploadedImageId}
            service="face-detection"
          />
        </div>
      </div>
    </div>
  )
}

export default FaceDetectionPage
