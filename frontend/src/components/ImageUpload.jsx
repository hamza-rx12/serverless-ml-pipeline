import { useState } from 'react';
import { api } from '../services/api';
import './ImageUpload.css';

function ImageUpload({ onUploadSuccess, service = 'object-detection' }) {
  const [selectedFile, setSelectedFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');
  const [error, setError] = useState('');
  const [isDragging, setIsDragging] = useState(false);

  const validateAndSetFile = (file) => {
    // Validate file type
    const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      setError('Please select a valid image file (JPEG, PNG, GIF, BMP, WEBP)');
      return false;
    }

    // Validate file size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      setError('File size must be less than 10MB');
      return false;
    }

    setSelectedFile(file);
    setError('');

    // Create preview
    const reader = new FileReader();
    reader.onloadend = () => {
      setPreview(reader.result);
    };
    reader.readAsDataURL(file);
    return true;
  };

  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      validateAndSetFile(file);
    }
  };

  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      validateAndSetFile(files[0]);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setError('Please select a file first');
      return;
    }

    setUploading(true);
    setUploadStatus('Getting upload URL...');
    setError('');

    try {
      // Step 1: Get presigned URL with service parameter
      const { uploadUrl, imageId } = await api.getPresignedUrl(
        selectedFile.name,
        selectedFile.type,
        service  // Pass service to API
      );

      // Step 2: Upload to S3
      setUploadStatus('Uploading image...');
      await api.uploadToS3(uploadUrl, selectedFile);

      // Step 3: Success
      setUploadStatus('Upload successful! Analysis in progress...');

      // Reset form
      setTimeout(() => {
        setSelectedFile(null);
        setPreview(null);
        setUploadStatus('');
        if (onUploadSuccess) {
          onUploadSuccess(imageId);
        }
      }, 2000);

    } catch (err) {
      setError('Upload failed: ' + (err.response?.data?.error || err.message));
      setUploadStatus('');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="upload-container">
      <h2>Upload Image for Analysis</h2>

      <div
        className={`upload-area ${isDragging ? 'dragging' : ''} ${selectedFile ? 'has-file' : ''}`}
        onDragEnter={handleDragEnter}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <input
          type="file"
          id="file-input"
          accept="image/jpeg,image/jpg,image/png,image/gif,image/bmp,image/webp"
          onChange={handleFileSelect}
          disabled={uploading}
          className="file-input"
        />

        {!preview ? (
          <label htmlFor="file-input" className="file-label">
            <div className="upload-icon">📁</div>
            <div className="upload-text">
              <span className="upload-primary">Drag & Drop your image here</span>
              <span className="upload-secondary">or click to browse</span>
            </div>
            <div className="upload-hint">Supports: JPEG, PNG, GIF, BMP, WEBP (Max 10MB)</div>
          </label>
        ) : (
          <div className="preview-container">
            <img src={preview} alt="Preview" className="preview-image" />
            <div className="file-name">{selectedFile.name}</div>
            <button
              onClick={() => {
                setSelectedFile(null);
                setPreview(null);
                setError('');
              }}
              className="remove-button"
              disabled={uploading}
            >
              ✕ Remove
            </button>
          </div>
        )}
      </div>

      {selectedFile && (
        <button
          onClick={handleUpload}
          disabled={!selectedFile || uploading}
          className="upload-button"
        >
          {uploading ? (
            <>
              <span className="spinner"></span>
              Uploading...
            </>
          ) : (
            <>🚀 Upload & Analyze</>
          )}
        </button>
      )}

      {uploadStatus && (
        <div className="status-message success">
          ✓ {uploadStatus}
        </div>
      )}

      {error && (
        <div className="status-message error">
          ✗ {error}
        </div>
      )}
    </div>
  );
}

export default ImageUpload;
