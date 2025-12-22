'use client'

import { useSearchParams } from 'next/navigation';
import { Suspense, useState } from 'react';

function DashboardContent() {
  const searchParams = useSearchParams();
  const user = searchParams.get('user');
  const userId = searchParams.get('userId');
  
  const [loading, setLoading] = useState(false);
  const [validationResult, setValidationResult] = useState(null);

  const validateSupportAccess = async () => {
    if (!userId) {
      alert('Missing user ID. Please login again.');
      return;
    }

    setLoading(true);
    setValidationResult(null);

    try {
      const response = await fetch('/api/validate/support', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: userId })
      });

      const result = await response.json();
      setValidationResult(result);
      
    } catch (error) {
      console.error('Validation error:', error);
      setValidationResult({
        success: false,
        message: 'Failed to validate access',
        error: error.message
      });
    }

    setLoading(false);
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      alignItems: 'center', 
      justifyContent: 'center',
      backgroundColor: '#f8f9fa',
      fontFamily: 'system-ui, sans-serif',
      padding: '2rem'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '3rem',
        borderRadius: '12px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        textAlign: 'center',
        maxWidth: '600px',
        width: '100%'
      }}>
        <h1 style={{ 
          color: '#2563eb', 
          fontSize: '2.5rem', 
          marginBottom: '1rem',
          fontWeight: 'bold'
        }}>
          🔧 Support Hub Dashboard
        </h1>
        
        <p style={{ 
          color: '#374151', 
          fontSize: '1.2rem',
          marginBottom: '2rem'
        }}>
          Welcome <strong>{user || 'User'}</strong>! 
        </p>

        <div style={{
          backgroundColor: '#f0f9ff',
          border: '1px solid #0ea5e9',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '2rem'
        }}>
          <p style={{ 
            color: '#0c4a6e', 
            fontSize: '1rem',
            margin: '0',
            lineHeight: '1.6'
          }}>
            You have successfully authenticated with Microsoft OAuth. 
            <br />
            Click the button below to verify your Support Department access.
          </p>
        </div>

        {!validationResult && (
          <button 
            onClick={validateSupportAccess}
            disabled={loading}
            style={{
              backgroundColor: loading ? '#9ca3af' : '#059669',
              color: 'white',
              padding: '16px 32px',
              fontSize: '1.1rem',
              border: 'none',
              borderRadius: '8px',
              cursor: loading ? 'not-allowed' : 'pointer',
              fontWeight: '600',
              marginBottom: '2rem',
              minWidth: '200px'
            }}
          >
            {loading ? '🔄 Validating...' : '🔐 Access Restricted Content'}
          </button>
        )}

        {validationResult && (
          <div style={{
            backgroundColor: validationResult.success ? '#dcfce7' : '#fef2f2',
            border: '2px solid ' + (validationResult.success ? '#16a34a' : '#dc2626'),
            borderRadius: '8px',
            padding: '2rem',
            marginBottom: '2rem'
          }}>
            {validationResult.success ? (
              <>
                <h2 style={{ 
                  color: '#15803d', 
                  fontSize: '1.5rem',
                  marginBottom: '1rem',
                  fontWeight: 'bold'
                }}>
                  🎉 Access Granted!
                </h2>
                <div style={{
                  backgroundColor: '#1f2937',
                  color: '#f9fafb',
                  padding: '1rem',
                  borderRadius: '6px',
                  fontFamily: 'monospace',
                  fontSize: '1.1rem',
                  fontWeight: 'bold',
                  letterSpacing: '1px',
                  marginBottom: '1rem'
                }}>
                  🚩 {validationResult.flag}
                </div>
                <div style={{
                  backgroundColor: '#f3f4f6',
                  borderRadius: '8px',
                  padding: '1rem'
                }}>
                  <h3 style={{ color: '#374151', marginBottom: '0.5rem' }}>🏆 Challenge Completed!</h3>
                  <p style={{ 
                    color: '#6b7280',
                    lineHeight: '1.6',
                    margin: '0',
                    textAlign: 'center'
                  }}>
                    Congratulations! You have successfully completed this security challenge.
                  </p>
                </div>
              </>
            ) : (
              <>
                <h2 style={{ 
                  color: '#dc2626', 
                  fontSize: '1.5rem',
                  marginBottom: '1rem',
                  fontWeight: 'bold'
                }}>
                  ❌ Access Denied
                </h2>
                <p style={{ 
                  color: '#7f1d1d',
                  marginBottom: '1rem'
                }}>
                  {validationResult.message}
                </p>
                {validationResult.user && (
                  <div style={{
                    backgroundColor: '#f3f4f6',
                    borderRadius: '6px',
                    padding: '1rem',
                    textAlign: 'left'
                  }}>
                    <strong>Your Profile:</strong>
                    <br />
                    Department: {validationResult.user.department}
                    <br />
                    Required: Support
                  </div>
                )}
              </>
            )}
          </div>
        )}

        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
          <button 
            onClick={() => window.location.href = '/support'}
            style={{
              backgroundColor: '#6b7280',
              color: 'white',
              padding: '10px 20px',
              fontSize: '0.9rem',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: '600'
            }}
          >
            🔧 Back to Support Hub
          </button>
          
          <button 
            onClick={() => window.location.href = '/'}
            style={{
              backgroundColor: '#2563eb',
              color: 'white',
              padding: '10px 20px',
              fontSize: '0.9rem',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: '600'
            }}
          >
            🏠 HR Onboarding
          </button>
        </div>
      </div>
    </div>
  );
}

export default function SupportDashboard() {
  return (
    <Suspense fallback={
      <div style={{ 
        minHeight: '100vh', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <p>Loading...</p>
      </div>
    }>
      <DashboardContent />
    </Suspense>
  );
}
