# 🎓 AI-Driven Academic Project Monitoring System

[![Flask](https://img.shields.io/badge/Flask-3.0.0-000000?style=for-the-badge&logo=flask)](https://flask.palletsprojects.com/)
[![SQLite](https://img.shields.io/badge/SQLite-Zero--Config-003B57?style=for-the-badge&logo=sqlite)](https://www.sqlite.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

A state-of-the-art academic management platform designed to automate project tracking, evaluate student contributions using AI, and ensure academic integrity through GitHub synchronization.

---

## ✨ Features that "WOW"

### 🏦 4-Tier Governance Architecture
Robust Role-Based Access Control (RBAC) ensuring precise workflow management:
- **Head of Department (HOD)**: Strategic oversight and final project finalization.
- **Project Coordinator**: Proposal vetting and mentor-team matching.
- **Faculty Guide**: Weekly progress monitoring and code-review feedback.
- **Student Team**: Collaborative development and automated performance tracking.

### 🤖 AI Contribution Intelligence
Moves beyond "manual marks" to data-driven evaluation:
- **Real-time Scoring**: Analyzes GitHub commits, code volume, and submission consistency.
- **Risk Identification**: Automatically flags "Free Riders" or inactive members for early intervention.
- **Integrity Reports**: Generates professional, signature-ready PDF reports with full contribution breakdowns.

### 📊 Modern Tech Suite
- **Glassmorphism Interface**: A premium UI/UX inspired by modern design trends.
- **Dynamic Visuals**: High-fidelity activity charts powered by **Chart.js**.
- **Edge Analytics**: Background monitoring agent for departmental health checks.

---

## 🚀 Quick Start (Deployment Ready)

### 1. Zero-Install Configuration
The system uses **SQLite**, so no external database setup is required. 

```bash
# 1. Install professional dependencies
pip install -r requirements.txt

# 2. Initialize the departmental ecosystem (Demo Data)
python seed.py

# 3. Launch the platform
python main.py
```

### 🔑 Default Credentials (Seed Data)
| Role | Identity | Access Key |
| :--- | :--- | :--- |
| **HOD** | `hod@cs.university.edu` | `password123` |
| **Coordinator** | `coordinator@cs.university.edu` | `password123` |
| **Faculty** | `smith@university.edu` | `password123` |
| **Student** | `alice@student.com` | `password123` |

---

## 📂 Project Structure
```text
├── app/
│   ├── services/    # AI Engine, GitHub Sync, Professional Reports
│   ├── routes/      # RBAC Business Logic
│   ├── models/      # Data Architecture
│   └── templates/   # Premium Dashboards (Glassmorphism)
├── seed.py          # System Initializer
└── main.py          # Application Entry Point
```

---
> [!TIP]
> **To generate the Final Report**: Navigate to the project details on any dashboard and click **"Download / Print PDF"**. The system is optimized for high-quality browser-to-PDF output.

---
**Developed for Academic Excellence & Transparency**
