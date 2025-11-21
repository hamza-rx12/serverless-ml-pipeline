import axios from 'axios';

// This will be set via environment variables
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api';

export const api = {
  // Get presigned URL for S3 upload
  async getPresignedUrl(fileName, fileType, service = 'object-detection') {
    try {
      const response = await axios.post(`${API_BASE_URL}/upload-url`, {
        fileName,
        fileType,
        service  // NEW: Service parameter for routing
      });
      return response.data;
    } catch (error) {
      console.error('Error getting presigned URL:', error);
      throw error;
    }
  },

  // Upload file directly to S3 using presigned URL
  async uploadToS3(presignedUrl, file) {
    try {
      await axios.put(presignedUrl, file, {
        headers: {
          'Content-Type': file.type
        }
      });
    } catch (error) {
      console.error('Error uploading to S3:', error);
      throw error;
    }
  },

  // Get analysis results for a specific image
  async getAnalysisResults(imageId) {
    try {
      const response = await axios.get(`${API_BASE_URL}/results/${encodeURIComponent(imageId)}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching results:', error);
      throw error;
    }
  },

  // List recent uploads
  async listRecentUploads(limit = 20, service = null) {
    try {
      const params = { limit };
      if (service) {
        params.service = service;  // Add service filter if provided
      }
      const response = await axios.get(`${API_BASE_URL}/results`, { params });
      return response.data;
    } catch (error) {
      console.error('Error fetching recent uploads:', error);
      throw error;
    }
  }
};
