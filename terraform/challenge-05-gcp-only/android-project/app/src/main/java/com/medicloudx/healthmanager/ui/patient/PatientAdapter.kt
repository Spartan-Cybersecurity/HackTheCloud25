package com.medicloudx.healthmanager.ui.patient

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.recyclerview.widget.RecyclerView
import com.medicloudx.healthmanager.R
import com.medicloudx.healthmanager.models.Patient
import com.medicloudx.healthmanager.models.RiskLevel

/**
 * RecyclerView adapter for displaying patient list
 */
class PatientAdapter(
    private val patients: List<Patient>,
    private val onPatientClick: (Patient) -> Unit
) : RecyclerView.Adapter<PatientAdapter.PatientViewHolder>() {
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PatientViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_patient, parent, false)
        return PatientViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: PatientViewHolder, position: Int) {
        val patient = patients[position]
        holder.bind(patient)
    }
    
    override fun getItemCount(): Int = patients.size
    
    inner class PatientViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val cardView: CardView = itemView.findViewById(R.id.cardView)
        private val nameTextView: TextView = itemView.findViewById(R.id.textViewPatientName)
        private val ageTextView: TextView = itemView.findViewById(R.id.textViewPatientAge)
        private val conditionTextView: TextView = itemView.findViewById(R.id.textViewPatientCondition)
        private val lastVisitTextView: TextView = itemView.findViewById(R.id.textViewLastVisit)
        private val medicationTextView: TextView = itemView.findViewById(R.id.textViewMedication)
        private val riskIndicator: View = itemView.findViewById(R.id.riskIndicator)
        private val emergencyIcon: View = itemView.findViewById(R.id.emergencyIcon)
        
        fun bind(patient: Patient) {
            nameTextView.text = patient.name
            ageTextView.text = "${patient.age} años"
            conditionTextView.text = patient.getConditionDisplay()
            lastVisitTextView.text = patient.getLastVisitDisplay()
            medicationTextView.text = patient.getMedicationDisplay()
            
            // Set risk level indicator
            val riskLevel = patient.getRiskLevel()
            riskIndicator.setBackgroundColor(Color.parseColor(riskLevel.color))
            
            // Show emergency contact icon if available
            emergencyIcon.visibility = if (patient.hasEmergencyContact()) {
                View.VISIBLE
            } else {
                View.GONE
            }
            
            // Special styling for system patients
            if (patient.isSystemPatient()) {
                cardView.setCardBackgroundColor(Color.parseColor("#FFF3E0"))
                nameTextView.setTextColor(Color.parseColor("#E65100"))
            } else {
                cardView.setCardBackgroundColor(Color.parseColor("#FFFFFF"))
                nameTextView.setTextColor(Color.parseColor("#212121"))
            }
            
            // Set click listener
            itemView.setOnClickListener {
                onPatientClick(patient)
            }
        }
    }
}
