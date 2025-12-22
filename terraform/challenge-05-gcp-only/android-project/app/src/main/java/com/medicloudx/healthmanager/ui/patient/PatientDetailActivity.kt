package com.medicloudx.healthmanager.ui.patient
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.medicloudx.healthmanager.R
import com.medicloudx.healthmanager.databinding.ActivityPatientDetailBinding
import com.medicloudx.healthmanager.models.Patient
import com.medicloudx.healthmanager.utils.LogUtils

class PatientDetailActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityPatientDetailBinding
    private lateinit var patient: Patient
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityPatientDetailBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // Get patient from intent
        patient = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra("patient", Patient::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra("patient")
        } ?: run {
            finish()
            return
        }
        
        setupToolbar()
        setupPatientDetails()
        setupClickListeners()
        
        LogUtils.logPatientOperation("VIEW_DETAIL", patient.id)
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Detalles del Paciente"
        }
    }
    
    private fun setupPatientDetails() {
        binding.apply {
            // Basic information
            textViewPatientName.text = patient.name
            textViewPatientAge.text = "${patient.age} años"
            textViewPatientId.text = "ID: ${patient.id}"
            
            // Medical information
            textViewCondition.text = patient.condition
            textViewLastVisit.text = patient.lastVisit
            textViewMedication.text = patient.medication
            textViewEmergencyContact.text = patient.emergencyContact
            
            // Risk level indicator
            val riskLevel = patient.getRiskLevel()
            textViewRiskLevel.text = riskLevel.displayName
            textViewRiskLevel.setTextColor(Color.parseColor(riskLevel.color))
            riskIndicatorView.setBackgroundColor(Color.parseColor(riskLevel.color))
            
            // Special handling for system patients
            if (patient.isSystemPatient()) {
                // Highlight important system information
                cardViewSystemInfo.setCardBackgroundColor(Color.parseColor("#FFEBEE"))
                textViewSystemInfo.text = "⚠️ REGISTRO DEL SISTEMA"
                textViewSystemInfo.setTextColor(Color.parseColor("#C62828"))
                
                // Make medication field more prominent for system records
                if (patient.medication.isNotEmpty()) {
                    textViewMedication.setTextColor(Color.parseColor("#1976D2"))
                    textViewMedication.setTextSize(14f)
                    textViewMedication.setTypeface(null, android.graphics.Typeface.BOLD)
                    
                    // Log system patient medication data
                    LogUtils.d("System patient medication data: ${patient.medication}")
                }
            } else {
                cardViewSystemInfo.setCardBackgroundColor(Color.parseColor("#E8F5E8"))
                textViewSystemInfo.text = "✅ Paciente Registrado"
                textViewSystemInfo.setTextColor(Color.parseColor("#2E7D32"))
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.apply {
            // Emergency contact click to call
            buttonEmergencyCall.setOnClickListener {
                if (patient.hasEmergencyContact()) {
                    callEmergencyContact()
                } else {
                    Toast.makeText(this@PatientDetailActivity, 
                        "No hay contacto de emergencia disponible", 
                        Toast.LENGTH_SHORT).show()
                }
            }
            
            // Copy patient ID
            textViewPatientId.setOnLongClickListener {
                copyToClipboard("ID del Paciente", patient.id)
                true
            }
            
            // Copy medication info
            textViewMedication.setOnLongClickListener {
                copyToClipboard("Medicación", patient.medication)
                if (patient.isSystemPatient()) {
                    Toast.makeText(this@PatientDetailActivity,
                        "Información del sistema copiada", 
                        Toast.LENGTH_SHORT).show()
                }
                true
            }
            
            // Share patient information
            buttonSharePatient.setOnClickListener {
                sharePatientInfo()
            }
        }
    }
    
    private fun callEmergencyContact() {
        try {
            val phoneNumber = patient.emergencyContact
            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$phoneNumber")
            }
            startActivity(intent)
            LogUtils.d("Emergency call initiated for patient: ${patient.id}")
        } catch (e: Exception) {
            LogUtils.e("Error initiating emergency call: ${e.message}")
            Toast.makeText(this, "Error al iniciar llamada", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun copyToClipboard(label: String, text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(label, text)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(this, "$label copiado al portapapeles", Toast.LENGTH_SHORT).show()
        
        LogUtils.d("Data copied to clipboard: $label")
    }
    
    private fun sharePatientInfo() {
        val shareText = buildString {
            appendLine("📋 MediCloudX - Información del Paciente")
            appendLine("=====================================")
            appendLine("Nombre: ${patient.name}")
            appendLine("Edad: ${patient.age} años")
            appendLine("ID: ${patient.id}")
            appendLine("Condición: ${patient.condition}")
            appendLine("Última visita: ${patient.lastVisit}")
            appendLine("Medicación: ${patient.medication}")
            appendLine("Contacto de emergencia: ${patient.emergencyContact}")
            appendLine("Nivel de riesgo: ${patient.getRiskLevel().displayName}")
            appendLine("=====================================")
            appendLine("Generado por MediCloudX Health Manager")
        }
        
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, shareText)
            type = "text/plain"
        }
        
        startActivity(Intent.createChooser(shareIntent, "Compartir información del paciente"))
        LogUtils.logPatientOperation("SHARE", patient.id)
    }
    
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.patient_detail_menu, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finish()
                true
            }
            R.id.action_edit -> {
                // TODO: Implement edit functionality
                Toast.makeText(this, "Función de edición no implementada", Toast.LENGTH_SHORT).show()
                true
            }
            R.id.action_delete -> {
                // TODO: Implement delete functionality
                Toast.makeText(this, "Función de eliminación no implementada", Toast.LENGTH_SHORT).show()
                true
            }
            R.id.action_share -> {
                sharePatientInfo()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}
