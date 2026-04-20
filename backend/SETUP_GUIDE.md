# 🍱 MisoCash Backend Infrastructure Plan

This plan outlines the steps to activate the **Miso Production Environment** using Docker and n8n.

## 1. 🏗️ Docker Deployment
To spin up the entire backend server (MySQL, n8n, and Admin Dashboard), run the following command in your `backend/` directory:

```powershell
docker-compose up -d
```

### 🏮 Containers to be created:
*   **`spending_tracker_db`**: MySQL 8.0 instance (User: `n8n_user`, Pass: `n8n_password`)
*   **`n8n_server`**: The automation engine running on port `5678`.
*   **`php_admin`**: Web UI for managing your database on port `8081`.
*   **`admin_links`**: A simple dashboard on port `80` to access everything.

---

## 2. ⚡ n8n Workflow Configuration
Once n8n is running (at `http://localhost:5678`), you need to import the **Miso Master Workflow**. 

### 🧬 Master Workflow Functions:
1.  **`user-sync` Webhook**: Automatically detects if a user exists by mobile.
    *   **New Member?** Creates a record with Full Name, Email, and initial Balance.
    *   **Existing Member?** Updates their live balance in real-time.
2.  **`spending-input` Webhook**: 
    *   Takes raw text (e.g., "Spent 250 for Starbucks at SM North").
    *   Uses **OpenAI** to parse it into structured JSON (Amount, Category, Description).
    *   Inserts the formatted record into the `transactions` table.
3.  **`login-log` Webhook**: Records high-security login events for audit trails.

---

## 3. 🛡️ Database Verification
Open **phpMyAdmin** at `http://localhost:8081` to verify your tables:

*   **`users`**: This is your Member Matrix. It stores the name, mobile, email, and live balance.
*   **`transactions`**: This is your Financial Ledger. It links every expense to a mobile number.

---

## 4. 🔗 Connectivity Check
Ensure your Flutter app's `baseUrl` in `n8n_service.dart` matches your PC's IP address (currently set to `192.168.254.159`).

> [!IMPORTANT]
> Make sure your Windows Firewall allows inbound connections on ports **5678** and **3306** if you are testing on a real physical smartphone.
