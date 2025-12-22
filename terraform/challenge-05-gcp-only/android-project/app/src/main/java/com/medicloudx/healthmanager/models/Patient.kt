package com.medicloudx.healthmanager.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Data model representing a patient in the MediCloudX Health Manager system
 */
@Parcelize
data class Patient(
    val id: String = "",
    val name: String = "",
    val age: Int = 0,
    val condition: String = "",
    val lastVisit: String = "",
    val medication: String = "",
    val emergencyContact: String = "",
    val bloodType: String = "",
    val allergies: String = "",
    val insuranceProvider: String = "",
    val doctorNotes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) : Parcelable {
    
    /**
     * Returns a formatted display name with age
     */
    fun getDisplayName(): String {
        return "$name ($age años)"
    }
    
    /**
     * Returns a formatted condition description
     */
    fun getConditionDisplay(): String {
        return if (condition.isNotEmpty()) {
            condition
        } else {
            "Sin condición específica"
        }
    }
    
    /**
     * Returns formatted last visit date
     */
    fun getLastVisitDisplay(): String {
        return if (lastVisit.isNotEmpty()) {
            "Última visita: $lastVisit"
        } else {
            "Sin visitas registradas"
        }
    }
    
    /**
     * Returns formatted medication information
     */
    fun getMedicationDisplay(): String {
        return if (medication.isNotEmpty()) {
            medication
        } else {
            "Sin medicación actual"
        }
    }
    
    /**
     * Checks if this is a system/admin patient record
     */
    fun isSystemPatient(): Boolean {
        return id.startsWith("ADMIN_") || 
               id.startsWith("SYSTEM_") || 
               name.contains("Sistema") ||
               name.contains("Administrador")
    }
    
    /**
     * Gets risk level based on condition and age
     */
    fun getRiskLevel(): RiskLevel {
        return when {
            age >= 65 -> RiskLevel.HIGH
            condition.contains("cardíaca", ignoreCase = true) ||
            condition.contains("diabetes", ignoreCase = true) ||
            condition.contains("hipertensión", ignoreCase = true) -> RiskLevel.MEDIUM
            age >= 50 -> RiskLevel.MEDIUM
            else -> RiskLevel.LOW
        }
    }
    
    /**
     * Gets priority for emergency contact
     */
    fun hasEmergencyContact(): Boolean {
        return emergencyContact.isNotEmpty() && 
               !emergencyContact.contains("admin@", ignoreCase = true)
    }
}

/**
 * Enum representing patient risk levels
 */
enum class RiskLevel(val displayName: String, val color: String) {
    LOW("Bajo", "#4CAF50"),
    MEDIUM("Medio", "#FF9800"), 
    HIGH("Alto", "#F44336")
}
