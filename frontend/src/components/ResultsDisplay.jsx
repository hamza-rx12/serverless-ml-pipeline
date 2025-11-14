import { useState, useEffect } from 'react';
import { api } from '../services/api';
import './ResultsDisplay.css';

function ResultsDisplay({ imageId }) {
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [recentUploads, setRecentUploads] = useState([]);
  const [selectedImage, setSelectedImage] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(false);

  useEffect(() => {
    loadRecentUploads();
  }, []);

  useEffect(() => {
    if (imageId) {
      setSelectedImage(imageId);
      loadResults(imageId);
      setAutoRefresh(true);
    }
  }, [imageId]);

  useEffect(() => {
    if (autoRefresh && selectedImage) {
      const interval = setInterval(() => {
        loadResults(selectedImage, true);
      }, 3000); // Poll every 3 seconds

      return () => clearInterval(interval);
    }
  }, [autoRefresh, selectedImage]);

  const loadRecentUploads = async () => {
    try {
      const data = await api.listRecentUploads(10);
      setRecentUploads(data.items || []);
    } catch (err) {
      console.error('Error loading recent uploads:', err);
    }
  };

  const loadResults = async (imgId, silent = false) => {
    if (!silent) {
      setLoading(true);
      setError('');
    }

    try {
      const data = await api.getAnalysisResults(imgId);
      setResults(data);

      // Stop auto-refresh if analysis is complete
      if (data.status === 'completed' || data.status === 'failed') {
        setAutoRefresh(false);
        loadRecentUploads(); // Refresh the list
      }
    } catch (err) {
      if (!silent) {
        setError('Failed to load results: ' + (err.response?.data?.error || err.message));
      }
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const handleSelectImage = (imgId) => {
    setSelectedImage(imgId);
    loadResults(imgId);
    setAutoRefresh(false);
  };

  const renderObjects = () => {
    if (!results?.detection_results?.objects?.length) return null;

    return (
      <div className="results-section">
        <h3>Objects Detected ({results.analysis_summary?.objects_detected || 0})</h3>
        <div className="labels-grid">
          {results.detection_results.objects.map((obj, idx) => (
            <div key={idx} className="label-card">
              <div className="label-name">{obj.name}</div>
              <div className="label-confidence">{obj.confidence.toFixed(1)}%</div>
              {obj.categories && (
                <div className="label-categories">
                  {obj.categories.join(', ')}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderFaces = () => {
    if (!results?.detection_results?.faces?.length) return null;

    return (
      <div className="results-section">
        <h3>Faces Detected ({results.analysis_summary?.faces_detected || 0})</h3>
        <div className="faces-grid">
          {results.detection_results.faces.map((face, idx) => (
            <div key={idx} className="face-card">
              <h4>Face {idx + 1}</h4>
              <div className="face-details">
                <div className="face-attribute">
                  <span className="attribute-label">Age Range:</span>
                  <span className="attribute-value">
                    {face.age_range?.low} - {face.age_range?.high}
                  </span>
                </div>
                <div className="face-attribute">
                  <span className="attribute-label">Gender:</span>
                  <span className="attribute-value">
                    {face.gender?.value} ({face.gender?.confidence.toFixed(1)}%)
                  </span>
                </div>
                {face.emotions && face.emotions.length > 0 && (
                  <div className="face-attribute">
                    <span className="attribute-label">Emotions:</span>
                    <div className="emotions-list">
                      {face.emotions.slice(0, 3).map((emotion, i) => (
                        <div key={i} className="emotion">
                          {emotion.type}: {emotion.confidence.toFixed(1)}%
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderModeration = () => {
    const isSafe = results?.analysis_summary?.is_safe;
    const moderationLabels = results?.detection_results?.moderation || [];

    return (
      <div className="results-section">
        <h3>Content Moderation</h3>
        <div className={`safety-badge ${isSafe ? 'safe' : 'unsafe'}`}>
          {isSafe ? 'Content is Safe' : 'Content Flagged'}
        </div>
        {moderationLabels.length > 0 && (
          <div className="moderation-labels">
            {moderationLabels.map((label, idx) => (
              <div key={idx} className="moderation-label">
                <span className="label-name">{label.name}</span>
                <span className="label-confidence">{label.confidence.toFixed(1)}%</span>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="results-container">
      <h2>Analysis Results</h2>

      <div className="recent-uploads">
        <h3>Recent Uploads</h3>
        <div className="uploads-list">
          {recentUploads.map((upload) => (
            <button
              key={upload.image_id}
              className={`upload-item ${selectedImage === upload.image_id ? 'active' : ''}`}
              onClick={() => handleSelectImage(upload.image_id)}
            >
              <div className="upload-name">{upload.image_id}</div>
              <div className="upload-time">
                {new Date(upload.timestamp).toLocaleString()}
              </div>
              <div className={`upload-status ${upload.status}`}>
                {upload.status}
              </div>
            </button>
          ))}
        </div>
      </div>

      {loading && (
        <div className="loading">Loading results...</div>
      )}

      {error && (
        <div className="error-message">{error}</div>
      )}

      {results && !loading && (
        <div className="results-content">
          <div className="results-header">
            <h3>{results.image_id}</h3>
            <div className="results-meta">
              <span>Status: <strong>{results.status}</strong></span>
              {autoRefresh && <span className="refreshing">Refreshing...</span>}
            </div>
          </div>

          {results.status === 'processing' && (
            <div className="processing-message">
              Analysis in progress. Results will appear shortly...
            </div>
          )}

          {results.status === 'completed' && (
            <>
              {renderModeration()}
              {renderObjects()}
              {renderFaces()}
            </>
          )}

          {results.status === 'failed' && (
            <div className="error-message">
              Analysis failed. Please try uploading the image again.
            </div>
          )}
        </div>
      )}

      {!results && !loading && !error && (
        <div className="no-results">
          Upload an image or select one from recent uploads to view results.
        </div>
      )}
    </div>
  );
}

export default ResultsDisplay;
