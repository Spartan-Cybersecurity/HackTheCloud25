package com.medicloudx.healthmanager.utils

import android.util.Log

/**
 * Utility class for logging in MediCloudX Health Manager
 * Provides centralized logging with proper tagging
 */
object LogUtils {
    
    private const val TAG = "MediCloudX"
    private const val DEBUG = true // Enable debug logging
    
    /**
     * Debug log
     */
    fun d(message: String) {
        if (DEBUG) {
            Log.d(TAG, message)
        }
    }
    
    /**
     * Info log
     */
    fun i(message: String) {
        Log.i(TAG, message)
    }
    
    /**
     * Warning log
     */
    fun w(message: String) {
        Log.w(TAG, message)
    }
    
    /**
     * Error log
     */
    fun e(message: String) {
        Log.e(TAG, message)
    }
    
    /**
     * Error log with exception
     */
    fun e(message: String, throwable: Throwable) {
        Log.e(TAG, message, throwable)
    }
    
    /**
     * Log Firebase Remote Config values for debugging
     * This method logs configuration data for development purposes
     */
    fun logRemoteConfigData(configMap: Map<String, Any>) {
        if (DEBUG) {
            d("=== FIREBASE REMOTE CONFIG DATA ===")
            for ((key, value) in configMap) {
                d("Remote Config [$key] = $value")
            }
            d("=== END REMOTE CONFIG DATA ===")
        }
    }
    
    /**
     * Log Firebase Authentication data
     */
    fun logAuthData(userId: String?, email: String?) {
        if (DEBUG) {
            d("Firebase Auth - User ID: $userId")
            d("Firebase Auth - Email: $email")
        }
    }
    
    /**
     * Log Firestore operations
     */
    fun logFirestoreOperation(operation: String, collection: String, documentId: String?) {
        if (DEBUG) {
            d("Firestore $operation - Collection: $collection, Document: $documentId")
        }
    }
    
    /**
     * Log network operations
     */
    fun logNetworkOperation(method: String, url: String, responseCode: Int? = null) {
        if (DEBUG) {
            if (responseCode != null) {
                d("Network $method $url - Response: $responseCode")
            } else {
                d("Network $method $url")
            }
        }
    }
    
    /**
     * Log patient data operations (with privacy considerations)
     */
    fun logPatientOperation(operation: String, patientId: String) {
        if (DEBUG) {
            // Only log patient ID for privacy
            d("Patient $operation - ID: $patientId")
        }
    }
    
    /**
     * Log application lifecycle events
     */
    fun logLifecycleEvent(component: String, event: String) {
        if (DEBUG) {
            d("$component - $event")
        }
    }
}
