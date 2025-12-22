'use client'

export default function SupportHub() {
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center',
      backgroundColor: '#f8f9fa',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '3rem',
        borderRadius: '12px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        textAlign: 'center',
        maxWidth: '500px'
      }}>
        <div style={{ marginBottom: '2rem' }}>
          <h1 style={{ 
            color: '#2563eb', 
            fontSize: '2.5rem', 
            marginBottom: '0.5rem',
            fontWeight: 'bold'
          }}>
            🔧 MediCloudX Support Hub
          </h1>
          <p style={{ 
            color: '#6b7280', 
            fontSize: '1.1rem',
            lineHeight: '1.6'
          }}>
            Secure access portal for Support Department staff
          </p>
        </div>

        <div style={{
          backgroundColor: '#fef3c7',
          border: '1px solid #f59e0b',
          borderRadius: '8px',
          padding: '1rem',
          marginBottom: '2rem'
        }}>
          <p style={{ 
            color: '#92400e', 
            fontSize: '0.9rem',
            margin: '0',
            fontWeight: '500'
          }}>
            ⚠️ Access restricted to Support Department personnel only
          </p>
        </div>

        <button 
          onClick={() => window.location.href = '/support/login'}
          style={{
            backgroundColor: '#2563eb',
            color: 'white',
            padding: '12px 24px',
            fontSize: '1.1rem',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
            fontWeight: '600',
            transition: 'background-color 0.3s'
          }}
          onMouseOver={(e) => e.target.style.backgroundColor = '#1d4ed8'}
          onMouseOut={(e) => e.target.style.backgroundColor = '#2563eb'}
        >
          🔑 Sign in with Microsoft Account
        </button>

        <div style={{ marginTop: '2rem', paddingTop: '1rem', borderTop: '1px solid #e5e7eb' }}>
          <p style={{ 
            color: '#9ca3af', 
            fontSize: '0.8rem',
            margin: '0'
          }}>
            © 2025 MediCloudX Healthcare Solutions
          </p>
        </div>
      </div>
    </div>
  )
}
