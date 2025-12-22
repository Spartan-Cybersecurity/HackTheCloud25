package com.medicloudx.healthmanager.ui.patient

import android.app.DatePickerDialog
import android.os.Bundle
import android.view.MenuItem
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.firestore.FirebaseFirestore
import com.medicloudx.healthmanager.R
import com.medicloudx.healthmanager.databinding.ActivityAddPatientBinding
import com.medicloudx.healthmanager.models.Patient
import com.medicloudx.healthmanager.utils.LogUtils
import java.text.SimpleDateFormat
import java.util.*

class AddPatientActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityAddPatientBinding
    private lateinit var firestore: FirebaseFirestore
    private val dateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAddPatientBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupToolbar()
        initializeFirebase()
        setupForm()
        setupClickListeners()
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.apply {
            title = "Agregar Paciente"
            setDisplayHomeAsUpEnabled(true)
            setDisplayShowHomeEnabled(true)
        }
    }
    
    private fun initializeFirebase() {
        firestore = FirebaseFirestore.getInstance()
    }
    
    private fun setupForm() {
        // Setup blood type spinner
        val bloodTypes = arrayOf(
            "Seleccionar tipo de sangre",
            "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Desconocido"
        )
        val bloodTypeAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, bloodTypes)
        bloodTypeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.spinnerBloodType.adapter = bloodTypeAdapter
        
        // Setup insurance provider spinner
        val insuranceProviders = arrayOf(
            "Seleccionar seguro médico",
            "Seguro Social",
            "IMSS",
            "ISSSTE", 
            "Seguro Popular",
            "Axa Seguros",
            "GNP Seguros",
            "Metlife",
            "Allianz",
            "Particular/Sin seguro"
        )
        val insuranceAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, insuranceProviders)
        insuranceAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.spinnerInsurance.adapter = insuranceAdapter
    }
    
    private fun setupClickListeners() {
        // Date picker for last visit
        binding.etLastVisit.setOnClickListener {
            showDatePicker { date ->
                binding.etLastVisit.setText(date)
            }
        }
        
        // Save patient button
        binding.btnSavePatient.setOnClickListener {
            if (validateForm()) {
                savePatient()
            }
        }
        
        // Cancel button
        binding.btnCancel.setOnClickListener {
            finish()
        }
    }
    
    private fun showDatePicker(onDateSelected: (String) -> Unit) {
        val calendar = Calendar.getInstance()
        val datePickerDialog = DatePickerDialog(
            this,
            { _, year, month, dayOfMonth ->
                calendar.set(year, month, dayOfMonth)
                onDateSelected(dateFormat.format(calendar.time))
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        )
        
        // Set max date to today
        datePickerDialog.datePicker.maxDate = System.currentTimeMillis()
        datePickerDialog.show()
    }
    
    private fun validateForm(): Boolean {
        var isValid = true
        
        // Validate name
        if (binding.etName.text.toString().trim().isEmpty()) {
            binding.tilName.error = "El nombre es requerido"
            isValid = false
        } else {
            binding.tilName.error = null
        }
        
        // Validate age
        val ageText = binding.etAge.text.toString().trim()
        if (ageText.isEmpty()) {
            binding.tilAge.error = "La edad es requerida"
            isValid = false
        } else {
            val age = ageText.toIntOrNull()
            if (age == null || age < 0 || age > 150) {
                binding.tilAge.error = "Ingrese una edad válida (0-150)"
                isValid = false
            } else {
                binding.tilAge.error = null
            }
        }
        
        // Validate emergency contact
        if (binding.etEmergencyContact.text.toString().trim().isEmpty()) {
            binding.tilEmergencyContact.error = "El contacto de emergencia es requerido"
            isValid = false
        } else {
            binding.tilEmergencyContact.error = null
        }
        
        // Validate blood type selection
        if (binding.spinnerBloodType.selectedItemPosition == 0) {
            Toast.makeText(this, "Por favor seleccione el tipo de sangre", Toast.LENGTH_SHORT).show()
            isValid = false
        }
        
        // Validate insurance selection
        if (binding.spinnerInsurance.selectedItemPosition == 0) {
            Toast.makeText(this, "Por favor seleccione el seguro médico", Toast.LENGTH_SHORT).show()
            isValid = false
        }
        
        return isValid
    }
    
    private fun savePatient() {
        // Show loading state
        binding.btnSavePatient.isEnabled = false
        binding.btnSavePatient.text = "Guardando..."
        
        // Create patient ID
        val patientId = "PAT_${System.currentTimeMillis()}_${(1000..9999).random()}"
        
        // Create patient object
        val patient = Patient(
            id = patientId,
            name = binding.etName.text.toString().trim(),
            age = binding.etAge.text.toString().trim().toInt(),
            condition = binding.etCondition.text.toString().trim().ifEmpty { "Sin condición específica" },
            lastVisit = binding.etLastVisit.text.toString().trim().ifEmpty { "Sin visitas previas" },
            medication = binding.etMedication.text.toString().trim().ifEmpty { "Sin medicación actual" },
            emergencyContact = binding.etEmergencyContact.text.toString().trim(),
            bloodType = binding.spinnerBloodType.selectedItem.toString(),
            allergies = binding.etAllergies.text.toString().trim().ifEmpty { "Sin alergias conocidas" },
            insuranceProvider = binding.spinnerInsurance.selectedItem.toString(),
            doctorNotes = binding.etDoctorNotes.text.toString().trim().ifEmpty { "Sin notas médicas" },
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis()
        )
        
        // Save to Firestore
        LogUtils.logFirestoreOperation("CREATE", "patients", patientId)
        
        firestore.collection("patients")
            .document(patientId)
            .set(patient)
            .addOnSuccessListener {
                LogUtils.logPatientOperation("CREATED", patientId)
                LogUtils.d("Patient created successfully: ${patient.name}")
                
                Toast.makeText(this, "Paciente registrado exitosamente", Toast.LENGTH_SHORT).show()
                
                // Return to main activity with success result
                setResult(RESULT_OK)
                finish()
            }
            .addOnFailureListener { exception ->
                LogUtils.e("Error creating patient: ${exception.message}")
                
                // Reset button state
                binding.btnSavePatient.isEnabled = true
                binding.btnSavePatient.text = "Guardar Paciente"
                
                Toast.makeText(this, "Error al registrar paciente: ${exception.message}", Toast.LENGTH_LONG).show()
            }
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finish()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}
