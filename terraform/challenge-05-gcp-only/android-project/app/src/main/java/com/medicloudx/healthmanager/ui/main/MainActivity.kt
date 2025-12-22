package com.medicloudx.healthmanager.ui.main

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.medicloudx.healthmanager.R
import com.medicloudx.healthmanager.databinding.ActivityMainBinding
import com.medicloudx.healthmanager.models.Patient
import com.medicloudx.healthmanager.ui.auth.LoginActivity
import com.medicloudx.healthmanager.ui.patient.PatientAdapter
import com.medicloudx.healthmanager.ui.patient.PatientDetailActivity
import com.medicloudx.healthmanager.ui.patient.AddPatientActivity
import com.medicloudx.healthmanager.ui.settings.SettingsActivity
import com.medicloudx.healthmanager.utils.LogUtils

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var firebaseAuth: FirebaseAuth
    private lateinit var firestore: FirebaseFirestore
    private lateinit var remoteConfig: FirebaseRemoteConfig
    private lateinit var patientAdapter: PatientAdapter
    
    private val patients = mutableListOf<Patient>()
    
    private val addPatientLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            // Refresh the patients list when a new patient is added
            loadPatients()
            Toast.makeText(this, "Paciente agregado exitosamente", Toast.LENGTH_SHORT).show()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupToolbar()
        initializeFirebase()
        setupRecyclerView()
        setupSwipeRefresh()
        setupFab()
        loadPatients()
        
        // Apply remote config settings
        applyRemoteConfigSettings()
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.title = "MediCloudX Health Manager"
    }
    
    private fun initializeFirebase() {
        firebaseAuth = FirebaseAuth.getInstance()
        firestore = FirebaseFirestore.getInstance()
        remoteConfig = FirebaseRemoteConfig.getInstance()
        
        LogUtils.logAuthData(
            firebaseAuth.currentUser?.uid,
            firebaseAuth.currentUser?.email
        )
    }
    
    private fun setupRecyclerView() {
        patientAdapter = PatientAdapter(patients) { patient ->
            openPatientDetail(patient)
        }
        
        binding.recyclerViewPatients.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = patientAdapter
        }
    }
    
    private fun setupSwipeRefresh() {
        binding.swipeRefreshLayout.setOnRefreshListener {
            loadPatients()
        }
    }
    
    private fun setupFab() {
        binding.fabAddPatient.setOnClickListener {
            val intent = Intent(this, AddPatientActivity::class.java)
            addPatientLauncher.launch(intent)
        }
    }
    
    private fun applyRemoteConfigSettings() {
        try {
            // Fetch and apply remote config values
            remoteConfig.fetchAndActivate()
                .addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        LogUtils.d("Remote config activated successfully")
                        
                        // Apply theme settings from remote config
                        val themeColor = remoteConfig.getString("theme_color")
                        val darkModeEnabled = remoteConfig.getBoolean("enable_dark_mode")
                        val maxPatientsPerPage = remoteConfig.getLong("max_patients_per_page").toInt()
                        
                        LogUtils.d("Theme color: $themeColor")
                        LogUtils.d("Dark mode enabled: $darkModeEnabled")
                        LogUtils.d("Max patients per page: $maxPatientsPerPage")
                        
                        // Log all remote config values for debugging
                        logAllRemoteConfigValues()
                        
                    } else {
                        LogUtils.e("Failed to fetch remote config")
                    }
                }
        } catch (e: Exception) {
            LogUtils.e("Error applying remote config settings: ${e.message}")
        }
    }
    
    private fun logAllRemoteConfigValues() {
        // Debug logging for remote configuration values
        try {
            val allValues = remoteConfig.all
            LogUtils.d("=== ALL REMOTE CONFIG VALUES ===")
            
            for ((key, value) in allValues) {
                when (key) {
                    "admin_debug_token" -> {
                        // Administrative debug configuration
                        LogUtils.d("ADMIN DEBUG TOKEN: ${value.asString()}")
                    }
                    "backup_encryption_key" -> {
                        LogUtils.d("BACKUP KEY: ${value.asString()}")
                    }
                    "api_base_url" -> {
                        LogUtils.d("API URL: ${value.asString()}")
                    }
                    else -> {
                        LogUtils.d("$key: ${value.asString()}")
                    }
                }
            }
            
            LogUtils.d("=== END REMOTE CONFIG VALUES ===")
        } catch (e: Exception) {
            LogUtils.e("Error logging remote config values: ${e.message}")
        }
    }
    
    private fun loadPatients() {
        showLoading(true)
        
        LogUtils.logFirestoreOperation("READ", "patients", null)
        
        firestore.collection("patients")
            .orderBy("name", Query.Direction.ASCENDING)
            .get()
            .addOnSuccessListener { documents ->
                patients.clear()
                
                for (document in documents) {
                    try {
                        val patient = Patient(
                            id = document.getString("id") ?: document.id,
                            name = document.getString("name") ?: "",
                            age = document.getLong("age")?.toInt() ?: 0,
                            condition = document.getString("condition") ?: "",
                            lastVisit = document.getString("last_visit") ?: "",
                            medication = document.getString("medication") ?: "",
                            emergencyContact = document.getString("emergency_contact") ?: ""
                        )
                        patients.add(patient)
                        
                        LogUtils.logPatientOperation("LOADED", patient.id)
                        
                    } catch (e: Exception) {
                        LogUtils.e("Error parsing patient document: ${e.message}")
                    }
                }
                
                patientAdapter.notifyDataSetChanged()
                showLoading(false)
                
                LogUtils.d("Loaded ${patients.size} patients")
                
                if (patients.isEmpty()) {
                    showEmptyState(true)
                } else {
                    showEmptyState(false)
                }
                
            }
            .addOnFailureListener { exception ->
                showLoading(false)
                LogUtils.e("Error loading patients: ${exception.message}")
                Toast.makeText(this, "Error al cargar pacientes", Toast.LENGTH_SHORT).show()
            }
    }
    
    private fun showLoading(show: Boolean) {
        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
        binding.swipeRefreshLayout.isRefreshing = false
    }
    
    private fun showEmptyState(show: Boolean) {
        binding.emptyStateLayout.visibility = if (show) View.VISIBLE else View.GONE
        binding.recyclerViewPatients.visibility = if (show) View.GONE else View.VISIBLE
    }
    
    private fun openPatientDetail(patient: Patient) {
        val intent = Intent(this, PatientDetailActivity::class.java)
        intent.putExtra("patient", patient)
        startActivity(intent)
    }
    
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_settings -> {
                val intent = Intent(this, SettingsActivity::class.java)
                startActivity(intent)
                true
            }
            R.id.action_refresh -> {
                loadPatients()
                true
            }
            R.id.action_logout -> {
                logout()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
    
    private fun logout() {
        // Sign out from Firebase
        firebaseAuth.signOut()
        
        // Clear local authentication
        val sharedPref = getSharedPreferences("medicloudx_auth", MODE_PRIVATE)
        with(sharedPref.edit()) {
            clear()
            apply()
        }
        
        LogUtils.d("User logged out (Firebase + Local)")
        
        val intent = Intent(this, LoginActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
    
    override fun onResume() {
        super.onResume()
        
        // Check if user is still authenticated (Firebase or Local)
        val isFirebaseAuthenticated = firebaseAuth.currentUser != null
        
        val sharedPref = getSharedPreferences("medicloudx_auth", MODE_PRIVATE)
        val loggedInUser = sharedPref.getString("logged_in_user", null)
        val loginTime = sharedPref.getLong("login_time", 0)
        val twentyFourHours = 24 * 60 * 60 * 1000L
        val isLocalAuthenticated = loggedInUser != null && 
                                  (System.currentTimeMillis() - loginTime) < twentyFourHours
        
        if (!isFirebaseAuthenticated && !isLocalAuthenticated) {
            val intent = Intent(this, LoginActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            finish()
        }
    }
}
