# Crossplatform_Project

Prepare wit:h *flutter pub get*
and start with: *flutter run*


File format:

lib/
├── main.dart                 # Main entry point, MaterialApp setup
│
├── data/                     # Data sources (Dummy, later DB repositories)
│   └── dummy_data.dart       # Contains the dummy groups and users
│
├── models/                   # Data models (remains as is)
│   └── models.dart           # User, Expense, PaymentGroup classes
│
├── screens/                  # Individual screen widgets
│   ├── group_list_screen.dart  # The screen with the group list
│   ├── main_screen.dart        # The screen with BottomNav (Dashboard, History, Settings)
│   ├── dashboard_screen.dart   # The Dashboard tab
│   ├── history_screen.dart     # The History tab
│   ├── settings_screen.dart    # The Settings tab
│   ├── add_expense_screen.dart # The screen for adding expenses
│
├── widgets/                  # Reusable UI components
│   ├── common/               # General widgets (e.g., Custom Buttons, if needed)
│   │   └── ...
│   ├── group_list/           # Widgets specifically for the group list
│   │   └── group_list_item.dart # Could be the ListTile from GroupListScreen
│   ├── dashboard/            # Widgets for the Dashboard
│   │   ├── user_balance_card.dart # The user balance card
│   │   └── ...
│   ├── history/              # Widgets for the history
│   │   └── expense_card.dart     # The expense card (also used in the Dashboard)
│   └── ...                   # Others as needed
│
└── utils/                    # Helper functions and constants
    ├── constants.dart          # Global constants (e.g., portionCostPerUser)
    ├── formatters.dart         # Formatting functions (e.g., currencyFormatter, formatDate)
    └── helpers.dart            # General helper functions (if needed)