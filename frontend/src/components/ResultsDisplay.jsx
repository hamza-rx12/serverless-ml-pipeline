import { useState, useEffect } from 'react';
import { api } from '../services/api';
import './ResultsDisplay.css';

function ResultsDisplay({ imageId, service }) {
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [recentUploads, setRecentUploads] = useState([]);
  const [selectedImage, setSelectedImage] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(false);

  useEffect(() => {
    loadRecentUploads();
  }, [service]);

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
      const data = await api.listRecentUploads(10, service);
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

  const extractFilename = (imageId) => {
    // Extract original filename from format: service/YYYYMMDD-HHMMSS-randomid-filename
    // Example: object-detection/20251121-192944-0b7a8505-images_1.jpg -> images_1.jpg
    if (!imageId) return '';

    const parts = imageId.split('/');
    if (parts.length < 2) return imageId;

    const pathPart = parts[1]; // Get the part after service/
    const segments = pathPart.split('-');

    // Skip date (YYYYMMDD), time (HHMMSS), and random ID, join the rest (original filename)
    if (segments.length > 3) {
      return segments.slice(3).join('-');
    }

    return imageId;
  };

  const renderObjects = () => {
    if (!results?.detection_results?.objects?.length) return null;

    return (
      <div className="results-section">
        <div className="section-header">
          <span className="section-icon">🏷️</span>
          <h3>Objects Detected</h3>
          <span className="section-count">{results.analysis_summary?.objects_detected || 0}</span>
        </div>
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
        <div className="section-header">
          <span className="section-icon">👤</span>
          <h3>Faces Detected</h3>
          <span className="section-count">{results.analysis_summary?.faces_detected || 0}</span>
        </div>
        <div className="faces-grid">
          {results.detection_results.faces.map((face, idx) => (
            <div key={idx} className="face-card">
              <h4>👤 Face {idx + 1}</h4>
              <div className="face-details">
                <div className="face-attribute">
                  <span className="attribute-label">Age Range</span>
                  <span className="attribute-value">
                    {face.age_range?.low} - {face.age_range?.high} years
                  </span>
                </div>
                <div className="face-attribute">
                  <span className="attribute-label">Gender</span>
                  <span className="attribute-value">
                    {face.gender?.value} ({face.gender?.confidence.toFixed(1)}%)
                  </span>
                </div>
                {face.emotions && face.emotions.length > 0 && (
                  <div className="face-attribute">
                    <span className="attribute-label">Top Emotions</span>
                    <div className="emotions-list">
                      {face.emotions.slice(0, 3).map((emotion, i) => (
                        <div key={i} className="emotion">
                          <span>{emotion.type}</span>
                          <span>{emotion.confidence.toFixed(1)}%</span>
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

  const renderText = () => {
    const textData = results?.detection_results?.text;
    if (!textData || !textData.lines?.length) return null;

    return (
      <div className="results-section">
        <div className="section-header">
          <span className="section-icon">📄</span>
          <h3>Text Detected</h3>
          <span className="section-count">{textData.line_count || 0} lines, {textData.word_count || 0} words</span>
        </div>
        <div className="text-results">
          <div className="full-text">
            <h4>📝 Full Text</h4>
            <p className="detected-text">{textData.full_text || 'No text detected'}</p>
          </div>
          <div className="text-lines">
            <h4>📋 Detected Lines</h4>
            {textData.lines.map((line, idx) => (
              <div key={idx} className="text-line">
                <span className="line-text">{line.text}</span>
                <span className="line-confidence">{line.confidence.toFixed(1)}%</span>
              </div>
            ))}
          </div>
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

  const getServiceIcon = () => {
    if (!service) return '📊';
    switch (service) {
      case 'text-detection': return '📄';
      case 'face-detection': return '👤';
      case 'object-detection': return '🏷️';
      default: return '📊';
    }
  };

  return (
    <div className="results-container">
      {/* History Sidebar */}
      <div className="history-sidebar">
        <div className="history-header">
          <h3>
            {getServiceIcon()} History
            <span className="history-count">({recentUploads.length})</span>
          </h3>
        </div>

        {recentUploads.length > 0 ? (
          <div className="uploads-list">
            {recentUploads.map((upload) => (
              <button
                key={upload.image_id}
                className={`upload-item ${selectedImage === upload.image_id ? 'active' : ''}`}
                onClick={() => handleSelectImage(upload.image_id)}
              >
                <div className="upload-content">
                  {upload.thumbnail_url ? (
                    <div className="upload-thumbnail">
                      <img src={upload.thumbnail_url} alt={extractFilename(upload.image_id)} />
                      <div className="thumbnail-overlay">
                        <span className="upload-icon">
                          {upload.status === 'completed' ? '✓' : upload.status === 'processing' ? '⟳' : '✗'}
                        </span>
                      </div>
                    </div>
                  ) : (
                    <div className="upload-placeholder">
                      <span className="placeholder-icon">
                        {upload.status === 'completed' ? '📷' : upload.status === 'processing' ? '⟳' : '❌'}
                      </span>
                    </div>
                  )}
                  <div className="upload-info">
                    <div className="upload-name" title={extractFilename(upload.image_id)}>
                      {extractFilename(upload.image_id)}
                    </div>
                    <div className="upload-time">
                      {new Date(upload.timestamp).toLocaleString()}
                    </div>
                    <div className={`upload-status ${upload.status}`}>
                      {upload.status}
                    </div>
                  </div>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="empty-history">
            <div className="empty-history-icon">📭</div>
            <p>No uploads yet</p>
          </div>
        )}
      </div>

      {/* Results Main Area */}
      <div className="results-main">
        {loading && (
          <div className="loading">
            <div className="loading-spinner"></div>
            <div className="loading-text">Loading results...</div>
          </div>
        )}

        {error && !loading && (
          <div className="error-message">
            ⚠️ {error}
          </div>
        )}

        {results && !loading && (
          <div className="results-content">
            <div className="results-header">
              <h3>
                {getServiceIcon()} {extractFilename(results.image_id)}
              </h3>
              <div className="results-meta">
                <div className="meta-item">
                  <span>Status:</span>
                  <strong>{results.status}</strong>
                </div>
                {autoRefresh && (
                  <div className="meta-item refreshing">
                    ⟳ Auto-refreshing...
                  </div>
                )}
              </div>
            </div>

            <div className="results-body">
              {results.status === 'processing' && (
                <div className="processing-message">
                  ⏳ Analysis in progress. Results will appear shortly...
                </div>
              )}

              {results.status === 'completed' && (
                <>
                  {/* Render service-specific results */}
                  {results.service === 'text-detection' && renderText()}
                  {results.service === 'face-detection' && renderFaces()}
                  {results.service === 'object-detection' && renderObjects()}

                  {/* For backward compatibility - show all if no service specified */}
                  {!results.service && (
                    <>
                      {renderModeration()}
                      {renderObjects()}
                      {renderFaces()}
                      {renderText()}
                    </>
                  )}
                </>
              )}

              {results.status === 'failed' && (
                <div className="error-message">
                  ❌ Analysis failed. Please try uploading the image again.
                </div>
              )}
            </div>
          </div>
        )}

        {!results && !loading && !error && (
          <div className="results-placeholder">
            <div className="placeholder-icon">{getServiceIcon()}</div>
            <div className="placeholder-text">No image selected</div>
            <div className="placeholder-subtext">
              Upload a new image or select from history to view results
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default ResultsDisplay;
