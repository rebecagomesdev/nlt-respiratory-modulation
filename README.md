# MODULAÇÃO RESPIRATÓRIA DA FLEXIBILIDADE COGNITIVA SOB DEMANDA MOTIVACIONAL: UMA ABORDAGEM COMPUTACIONAL MULTIMODAL

> **English Title:** Respiratory Modulation of Cognitive Flexibility under Motivational Demand: A Multimodal Computational Approach

![Status](https://img.shields.io/badge/Status-In_Progress-yellow)
![License](https://img.shields.io/badge/License-MIT-green)
![Python](https://img.shields.io/badge/Python-3.10+-blue)

## ⚡ Quick Summary
This repository contains the analysis pipeline for my Master's Thesis in **Bioinformatics at USP**. 
We investigate how different breathing protocols modulate **Cognitive Flexibility** and **Psychophysiological States** under high motivational demand.

## 📊 Data & Methodology
The project employs a **Multimodal Data Fusion** approach, integrating four simultaneous data streams:

* **🧠 Neural (EEG):** High-density recording (ActiCHamp Plus) to analyze power spectral density (Alpha/Beta/Theta) and functional connectivity (dwPLI).
* **🫁 Physiological:** Synchronized **ECG (HRV)**, **Respiration** (rate/depth), and **Thermal Imaging** (facial temperature) to assess neurovisceral integration.
* **🧩 Cognitive (Task):** **Number-Letter Task** with punitive feedback. Key metric: **Switch Cost** (reaction time trade-off).
* **💬 Affective (NLP):** Post-task verbal reports processed via **BERTimbau** (Transformers) to extract semantic embeddings of emotional states.

## 🛠️ Tech Stack
* **Data Acquisition:** LabStreamingLayer (LSL)
* **Signal Processing:** Python (`NeuroKit2`, `MNE-Python`)
* **NLP:** Hugging Face Transformers (`BERTimbau`)
* **Statistics:** Linear Mixed-Effects Models (LMM) in Python/R.
* 
## 🤝 Usage & Collaboration
This code is open-source (MIT). However, if you plan to use this pipeline in your research, I'd love to hear about it! Please contact me at rebecadcgomes@gmail.com for potential collaboration.

📧 **Contact:** rebecadcgomes@gmail.com

---
*Developed at USP - University of São Paulo.* 🇧🇷
