import { useNavigate } from 'react-router-dom'
import ServiceCard from '../components/ServiceCard'
import './Home.css'

function Home() {
  const navigate = useNavigate()

  const services = [
    {
      id: 'text-detection',
      title: 'Text Detection',
      icon: '📄',
      description: 'Extract text from images and documents using OCR',
      features: [
        'Extract printed and handwritten text',
        'Detect text in multiple languages',
        'Get text with confidence scores'
      ],
      path: '/text-detection'
    },
    {
      id: 'face-detection',
      title: 'Face Detection',
      icon: '👤',
      description: 'Analyze faces and detect attributes',
      features: [
        'Detect faces in images',
        'Estimate age range and gender',
        'Identify emotions and expressions'
      ],
      path: '/face-detection'
    },
    {
      id: 'object-detection',
      title: 'Object Detection',
      icon: '🏷️',
      description: 'Identify objects and labels in images',
      features: [
        'Detect objects and scenes',
        'Get confidence scores',
        'Categorize detected items'
      ],
      path: '/object-detection'
    }
  ]

  return (
    <div className="home-container">
      <div className="home-content">
        <h2>Select a Service</h2>
        <p className="home-description">
          Choose an AI-powered image analysis service to get started
        </p>

        <div className="services-grid">
          {services.map(service => (
            <ServiceCard
              key={service.id}
              service={service}
              onSelect={() => navigate(service.path)}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

export default Home
