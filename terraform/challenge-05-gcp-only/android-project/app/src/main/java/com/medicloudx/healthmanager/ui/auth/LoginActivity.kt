package com.medicloudx.healthmanager.ui.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import com.medicloudx.healthmanager.R
import com.medicloudx.healthmanager.databinding.ActivityLoginBinding
import com.medicloudx.healthmanager.ui.main.MainActivity
import com.medicloudx.healthmanager.utils.LogUtils

class LoginActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityLoginBinding
    private lateinit var firebaseAuth: FirebaseAuth
    private lateinit var remoteConfig: FirebaseRemoteConfig
    
    // Predefined doctor credentials for the challenge
    private val doctorCredentials = mapOf(
        "dr.martinez@medicloudx.com" to "MediCloud2024!",
        "dr.rodriguez@medicloudx.com" to "HealthCare123",
        "admin@medicloudx.com" to "Admin2024!"
    )
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // Initialize Firebase
        initializeFirebase()
        
        // Setup UI
        setupUI()
        
        // Check if user is already logged in
        checkCurrentUser()
    }
    
    private fun initializeFirebase() {
        try {
            firebaseAuth = FirebaseAuth.getInstance()
            
            // Initialize Remote Config
            remoteConfig = FirebaseRemoteConfig.getInstance()
            val configSettings = FirebaseRemoteConfigSettings.Builder()
                .setMinimumFetchIntervalInSeconds(3600) // 1 hour
                .build()
            remoteConfig.setConfigSettingsAsync(configSettings)
            
            // Fetch remote config on startup
            fetchRemoteConfig()
            
            LogUtils.d("Firebase initialized successfully")
        } catch (e: Exception) {
            LogUtils.e("Firebase initialization failed: ${e.message}")
            Toast.makeText(this, "Error de configuración de Firebase", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun fetchRemoteConfig() {
        // Fetch application configuration settings
        remoteConfig.fetchAndActivate()
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    val updated = task.result
                    LogUtils.d("Config params updated: $updated")
                    
                    // Log all remote config values for debugging
                    logRemoteConfigValues()
                } else {
                    LogUtils.e("Fetch failed")
                }
            }
    }
    
    private fun logRemoteConfigValues() {
        // Log all remote config values for debugging purposes
        try {
            val allKeys = remoteConfig.all
            LogUtils.d("=== REMOTE CONFIG VALUES ===")
            for ((key, value) in allKeys) {
                LogUtils.d("$key: ${value.asString()}")
            }
            LogUtils.d("=== END REMOTE CONFIG ===")
        } catch (e: Exception) {
            LogUtils.e("Error logging remote config: ${e.message}")
        }
    }
    
    private fun setupUI() {
        binding.loginButton.setOnClickListener {
            attemptLogin()
        }
        
        binding.forgotPasswordText.setOnClickListener {
            Toast.makeText(this, "Contacte al administrador del sistema", Toast.LENGTH_LONG).show()
        }
    }
    
    private fun checkCurrentUser() {
        // Check Firebase Auth first
        val currentUser = firebaseAuth.currentUser
        if (currentUser != null) {
            navigateToMain()
            return
        }
        
        // Check local authentication
        val sharedPref = getSharedPreferences("medicloudx_auth", MODE_PRIVATE)
        val loggedInUser = sharedPref.getString("logged_in_user", null)
        val loginTime = sharedPref.getLong("login_time", 0)
        
        // Check if logged in within last 24 hours
        val twentyFourHours = 24 * 60 * 60 * 1000L
        if (loggedInUser != null && (System.currentTimeMillis() - loginTime) < twentyFourHours) {
            LogUtils.d("User already logged in locally: $loggedInUser")
            navigateToMain()
        }
    }
    
    private fun attemptLogin() {
        val email = binding.emailEditText.text.toString().trim()
        val password = binding.passwordEditText.text.toString().trim()
        
        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Por favor complete todos los campos", Toast.LENGTH_SHORT).show()
            return
        }
        
        showLoading(true)
        
        // Check against predefined credentials first
        if (doctorCredentials.containsKey(email) && doctorCredentials[email] == password) {
            // Use local authentication fallback if Firebase Auth fails
            try {
                firebaseAuth.signInWithEmailAndPassword(email, password)
                    .addOnCompleteListener { signInTask ->
                        if (signInTask.isSuccessful) {
                            LogUtils.d("Firebase auth successful")
                            onLoginSuccess()
                        } else {
                            // If Firebase auth fails, use local authentication
                            LogUtils.d("Firebase auth failed, using local auth: ${signInTask.exception?.message}")
                            simulateLocalLogin(email)
                        }
                    }
                    .addOnFailureListener { 
                        // Firebase completely unavailable, use local auth
                        LogUtils.d("Firebase unavailable, using local auth")
                        simulateLocalLogin(email)
                    }
            } catch (e: Exception) {
                // Firebase SDK error, use local auth
                LogUtils.d("Firebase SDK error, using local auth: ${e.message}")
                simulateLocalLogin(email)
            }
        } else {
            showLoading(false)
            onLoginFailure("Credenciales inválidas")
        }
    }
    
    private fun simulateLocalLogin(email: String) {
        // Simulate a successful local login for offline mode
        LogUtils.d("Local authentication successful for: $email")
        
        // Store login state locally
        val sharedPref = getSharedPreferences("medicloudx_auth", MODE_PRIVATE)
        with(sharedPref.edit()) {
            putString("logged_in_user", email)
            putLong("login_time", System.currentTimeMillis())
            apply()
        }
        
        onLoginSuccess()
    }
    
    private fun onLoginSuccess() {
        showLoading(false)
        Toast.makeText(this, "Inicio de sesión exitoso", Toast.LENGTH_SHORT).show()
        LogUtils.d("Login successful for user: ${firebaseAuth.currentUser?.email}")
        navigateToMain()
    }
    
    private fun onLoginFailure(message: String) {
        showLoading(false)
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        LogUtils.e("Login failed: $message")
    }
    
    private fun showLoading(show: Boolean) {
        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
        binding.loginButton.isEnabled = !show
        binding.emailEditText.isEnabled = !show
        binding.passwordEditText.isEnabled = !show
    }
    
    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
