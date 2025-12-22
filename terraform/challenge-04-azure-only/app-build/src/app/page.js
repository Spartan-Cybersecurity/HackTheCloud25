'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [userInfo, setUserInfo] = useState(null)
  const router = useRouter()

  useEffect(() => {
    const token = document.cookie.includes('auth-token=')
    if (!token) {
      router.push('/login')
    } else {
      setIsAuthenticated(true)
      // In a real app, you'd decode the JWT to get user info
      setUserInfo({ name: 'HR Administrator', role: 'admin' })
    }
  }, [router])

  const handleCreateUser = async () => {
    try {
      const response = await fetch('/api/create-user', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      })

      if (response.ok) {
        const userData = await response.json()
        alert('User created successfully!\\n\\nUser Principal Name: ' + userData.userPrincipalName + '\\nDisplay Name: ' + userData.displayName + '\\nTemporary Password: ' + userData.tempPassword)
      } else {
        const error = await response.text()
        alert('Error creating user: ' + error)
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error creating user')
    }
  }

  if (!isAuthenticated) {
    return <div>Loading...</div>
  }

  return (
    <div style={{ padding: '40px', fontFamily: 'system-ui, sans-serif', backgroundColor: '#f8fafc', minHeight: '100vh' }}>
      <div style={{ maxWidth: '800px', margin: '0 auto', backgroundColor: 'white', padding: '32px', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }}>
        <header style={{ borderBottom: '1px solid #e2e8f0', paddingBottom: '24px', marginBottom: '32px' }}>
          <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1e293b', marginBottom: '8px' }}>
            🏥 MediCloudX Workforce Onboarding
          </h1>
          <p style={{ color: '#64748b', fontSize: '18px' }}>
            Automated Clinical & Administrative Staff Registration System
          </p>
        </header>

        {userInfo && (
          <div style={{ backgroundColor: '#f1f5f9', padding: '16px', borderRadius: '8px', marginBottom: '32px' }}>
            <p style={{ margin: '0', color: '#334155' }}>
              Welcome, <strong>{userInfo.name}</strong> ({userInfo.role})
            </p>
          </div>
        )}

        <div style={{ backgroundColor: '#fef3c7', border: '1px solid #f59e0b', padding: '16px', borderRadius: '8px', marginBottom: '32px' }}>
          <h3 style={{ margin: '0 0 8px 0', color: '#92400e' }}>⚠️ System Notice</h3>
          <p style={{ margin: '0', color: '#92400e', fontSize: '14px' }}>
            This onboarding system automatically provisions Azure AD accounts for new healthcare staff. 
            Only authorized HR personnel should have access to this functionality.
          </p>
        </div>

        <div style={{ textAlign: 'center' }}>
          <button
            onClick={handleCreateUser}
            style={{
              backgroundColor: '#2563eb',
              color: 'white',
              padding: '12px 32px',
              fontSize: '18px',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: '600',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#1d4ed8'}
            onMouseOut={(e) => e.target.style.backgroundColor = '#2563eb'}
          >
            Create New Staff Account
          </button>
        </div>

        <div style={{ marginTop: '32px', padding: '16px', backgroundColor: '#f8fafc', borderRadius: '8px', fontSize: '14px', color: '#64748b' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#374151' }}>System Features:</h4>
          <ul style={{ margin: '0', paddingLeft: '20px' }}>
            <li>Automated Azure AD user provisioning</li>
            <li>Temporary password generation</li>
            <li>Compliance with MediCloudX security policies</li>
            <li>Integration with Microsoft Graph API</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
