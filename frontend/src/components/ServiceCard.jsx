import './ServiceCard.css'

function ServiceCard({ service, onSelect }) {
  return (
    <div className="service-card" onClick={onSelect}>
      <div className="service-icon">{service.icon}</div>
      <h3 className="service-title">{service.title}</h3>
      <p className="service-description">{service.description}</p>

      <ul className="service-features">
        {service.features.map((feature, index) => (
          <li key={index}>{feature}</li>
        ))}
      </ul>

      <button className="service-button">
        Get Started →
      </button>
    </div>
  )
}

export default ServiceCard
