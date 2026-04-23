-- New Member Directory
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    mobile VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    balance DECIMAL(15, 2) DEFAULT 0.00,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Transaction Ledger mapped to Members
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mobile VARCHAR(20),
    amount DECIMAL(15, 2) NOT NULL,
    type VARCHAR(50), 
    category VARCHAR(100),
    description TEXT,
    location_context VARCHAR(255),
    date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Notification Center
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mobile VARCHAR(20),
    title VARCHAR(255),
    message TEXT,
    category VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    date DATETIME DEFAULT CURRENT_TIMESTAMP
);
