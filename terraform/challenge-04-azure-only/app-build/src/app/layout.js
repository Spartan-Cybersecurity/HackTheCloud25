import './globals.css'

export const metadata = {
  title: 'MediCloudX Workforce Onboarding',
  description: 'Automated Clinical & Administrative Staff Registration System',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
