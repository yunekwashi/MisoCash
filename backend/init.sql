CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(10, 2) NOT NULL,
    type VARCHAR(50) NOT NULL, -- e.g., 'income', 'expense'
    category VARCHAR(100) NOT NULL,
    description TEXT,
    date DATETIME DEFAULT CURRENT_TIMESTAMP
);
