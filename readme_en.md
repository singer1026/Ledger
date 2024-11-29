# Ledger - iOS Personal Finance App

A clean and beautiful personal finance app developed with SwiftUI, fully compliant with Apple's design guidelines and human interface guidelines.

## Features

### 1. Transaction Management
- Add, edit, and delete transactions
- Transactions grouped by date
- Support for notes and date selection
- Swipe actions for quick operations (edit/delete)

### 2. Category Management
- Pre-set common categories (Dining, Transportation, Shopping, etc.)
- Custom categories and icons
- Drag and drop sorting
- Consistent category order across all views

### 3. Statistics
- Pie chart and bar chart visualization
- View statistics by week, month, or year
- Category and date range filtering
- Animated charts with interactive features

### 4. Data Management
- Local storage using Core Data
- Data backup and restore functionality
- No internet connection required, ensuring privacy

### 5. User Interface
- Dark mode support
- iOS design guidelines compliance
- Smooth animations and transitions
- Automatic keyboard handling

## Technical Features

- **Framework**: SwiftUI
- **Data Storage**: Core Data
- **Minimum iOS Version**: 15.0
- **Development Tools**: Xcode 15.0+

## Project Structure

```
Ledger/
├── Models/
│   ├── LedgerModel.xcdatamodeld    // Core Data model
│   ├── DataManager.swift           // Data manager
│   ├── RefreshTrigger.swift        // Data refresh trigger
│   └── EnvironmentValues+Extension.swift
├── Views/
│   ├── ContentView.swift           // Main view
│   ├── TransactionListView.swift   // Transaction list
│   ├── AddTransactionView.swift    // Add transaction
│   ├── TransactionDetailView.swift // Transaction detail
│   ├── CategoryManageView.swift    // Category management
│   ├── StatisticsView.swift        // Statistics charts
│   └── SettingsView.swift          // Settings
└── Utils/
    └── KeyboardDismissModifier.swift // Keyboard handling utility
```

## Security

- All data stored locally, no internet connection needed
- No user data collection
- System-level data backup support

## Usage Guide

1. **Adding Transactions**
   - Tap the "+" button in the top right corner
   - Enter amount and select category
   - Optionally add notes and modify date

2. **Managing Categories**
   - Add, edit, and delete categories in the category management page
   - Long press and drag to reorder categories
   - Customize category icons

3. **Viewing Statistics**
   - Switch between pie and bar charts for expense distribution
   - Select different time ranges for statistics
   - Tap categories to filter display

4. **Data Backup**
   - Export data from the settings page
   - Import previously backed up data

## Important Notes

- Default categories are created on first launch
- Confirmation required for deleting categories or transactions
- Regular data backup recommended

## Key Features

- Clean and intuitive user interface
- Efficient transaction management
- Flexible category organization
- Comprehensive statistical analysis
- Secure local data storage
- Dark mode support
- Gesture-based interactions
- Real-time data updates 