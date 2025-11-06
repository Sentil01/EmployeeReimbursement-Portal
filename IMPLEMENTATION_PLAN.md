# Employee Reimbursement Portal - Implementation Plan

## Overview
Build a Rails application for employee reimbursement management with role-based access control (admin and employee).

---

## 1. Database Schema & Models

### 1.1 Models to Create

#### **Department Model**
- Fields: `name` (string, required)
- Associations: `has_many :employees`

#### **Employee Model**
- Fields:
  - `first_name` (string, required)
  - `last_name` (string, required)
  - `email` (string, required, unique)
  - `designation` (string, required)
  - `department_id` (foreign key, required)
  - `user_id` (foreign key, optional - links to User model)
- Associations:
  - `belongs_to :department`
  - `belongs_to :user` (optional)
  - `has_many :bills`

#### **Bill Model**
- Fields:
  - `amount` (decimal, required)
  - `bill_type` (string, enum: 'food', 'travel', 'others')
  - `status` (string, enum: 'pending', 'approved', 'rejected', default: 'pending')
  - `employee_id` (foreign key, required)
  - `submitted_by` (string, optional - can store employee name or reference)
- Associations:
  - `belongs_to :employee`

#### **User Model** (Already exists)
- Fields: `name`, `email`, `password`, `role` (enum: 'admin', 'employee')
- Associations:
  - `has_one :employee` (optional)

---

## 2. Migrations to Create

1. **CreateDepartments**
   ```ruby
   create_table :departments do |t|
     t.string :name, null: false
     t.timestamps
   end
   ```

2. **CreateEmployees**
   ```ruby
   create_table :employees do |t|
     t.string :first_name, null: false
     t.string :last_name, null: false
     t.string :email, null: false
     t.string :designation, null: false
     t.references :department, null: false, foreign_key: true
     t.references :user, null: true, foreign_key: true
     t.timestamps
   end
   add_index :employees, :email, unique: true
   ```

3. **CreateBills**
   ```ruby
   create_table :bills do |t|
     t.decimal :amount, null: false, precision: 10, scale: 2
     t.string :bill_type, null: false
     t.string :status, default: 'pending', null: false
     t.references :employee, null: false, foreign_key: true
     t.string :submitted_by
     t.timestamps
   end
   ```

---

## 3. Controllers Structure

### 3.1 ApplicationController
- Add authentication check: `before_action :authenticate_user!`
- Add authorization helpers:
  - `admin?` - checks if `current_user.role == 'admin'`
  - `employee?` - checks if `current_user.role == 'employee'`
  - `ensure_admin` - redirect if not admin
  - `ensure_employee` - redirect if not employee

### 3.2 HomeController
- `index` - Dashboard/landing page
  - Redirect admin to employees list
  - Redirect employee to their bills

### 3.3 EmployeesController (Admin only)
- `index` - List all employees in table format
- `show` - View employee details
- `new` - Create new employee form
- `create` - Create employee
- `edit` - Edit employee form
- `update` - Update employee
- `destroy` - Delete employee
- Authorization: `before_action :ensure_admin` on all actions

### 3.4 BillsController
- `index` - List bills (admin: all bills, employee: own bills)
- `show` - View bill details
- `new` - Submit bill form (employee only)
- `create` - Create bill (employee only)
- `approve` - Approve bill (admin only, PATCH)
- `reject` - Reject bill (admin only, PATCH)
- Authorization:
  - `before_action :ensure_employee` for new/create
  - `before_action :ensure_admin` for approve/reject
  - Filter bills by employee in index for employees

### 3.5 DepartmentsController (Optional - if needed for employee form)
- `index` - List departments (for dropdowns)
- Or handle via AJAX/JSON endpoint

---

## 4. Routes Configuration

```ruby
Rails.application.routes.draw do
  devise_for :users
  
  root 'home#index'
  
  # Admin routes
  resources :employees, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  
  # Bill routes
  resources :bills, only: [:index, :show, :new, :create] do
    member do
      patch :approve
      patch :reject
    end
  end
  
  # Optional: Departments API for dropdowns
  resources :departments, only: [:index]
end
```

---

## 5. Views Structure

### 5.1 Layout (application.html.erb)
- Add navigation bar with:
  - Sign in/Sign out links
  - User name and role display
  - Navigation links based on role:
    - Admin: Employees, All Bills
    - Employee: Submit Bill, My Bills

### 5.2 Sign In Page
- File: `app/views/devise/sessions/new.html.erb`
- Already exists, ensure email and password validation
- Add styling for rich UI

### 5.3 Home/Dashboard
- File: `app/views/home/index.html.erb`
- Redirect logic or welcome message

### 5.4 Employees Index (Admin)
- File: `app/views/employees/index.html.erb`
- Table with columns:
  - Full Name (First Name + Last Name)
  - Designation
  - Department
  - Actions (View, Edit, Delete)
- Add "New Employee" button

### 5.5 Employee Details (Admin)
- Files:
  - `app/views/employees/new.html.erb` - Create form
  - `app/views/employees/edit.html.erb` - Edit form
  - `app/views/employees/show.html.erb` - View details
- Form fields:
  - First Name
  - Last Name
  - Email
  - Designation
  - Department (dropdown)
- Include validation error messages

### 5.6 Submit Bill (Employee)
- File: `app/views/bills/new.html.erb`
- Form fields:
  - Type (dropdown: Food, Travel, Others)
  - Amount (number input)
- Submit button
- Include validation error messages

### 5.7 View Submitted Bills (Employee)
- File: `app/views/bills/index.html.erb` (employee view)
- Table with columns:
  - Amount
  - Type
  - Status (with color coding: pending=yellow, approved=green, rejected=red)
  - Submitted Date
  - Actions (View)

### 5.8 View All Bills (Admin)
- File: `app/views/bills/index.html.erb` (admin view)
- Table with columns:
  - Employee Name
  - Amount
  - Type
  - Status
  - Submitted Date
  - Actions (Approve, Reject buttons)
- Show Approve/Reject buttons for pending bills only

### 5.9 Bill Show
- File: `app/views/bills/show.html.erb`
- Display all bill details
- For admin: Show Approve/Reject buttons if pending

---

## 6. Model Validations & Business Logic

### 6.1 Department Model
```ruby
validates :name, presence: true, uniqueness: true
```

### 6.2 Employee Model
```ruby
validates :first_name, :last_name, :email, :designation, presence: true
validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :department_id, presence: true
```

### 6.3 Bill Model
```ruby
validates :amount, presence: true, numericality: { greater_than: 0 }
validates :bill_type, presence: true, inclusion: { in: %w[food travel others] }
validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
validates :employee_id, presence: true
```

---

## 7. Authorization & Security

### 7.1 ApplicationController Helpers
```ruby
def admin?
  current_user&.role == 'admin'
end

def employee?
  current_user&.role == 'employee'
end

def ensure_admin
  redirect_to root_path, alert: 'Access denied' unless admin?
end

def ensure_employee
  redirect_to root_path, alert: 'Access denied' unless employee?
end
```

### 7.2 Controller Authorization
- EmployeesController: All actions require admin
- BillsController:
  - `new`, `create`: Require employee
  - `approve`, `reject`: Require admin
  - `index`: Filter by employee if not admin

### 7.3 View Authorization
- Use `if admin?` and `if employee?` in views to conditionally show content

---

## 8. UI/UX Enhancements

### 8.1 Styling Approach
- Use modern CSS (CSS Grid/Flexbox)
- Add Bootstrap or Tailwind CSS (if using a framework)
- Or use custom CSS with:
  - Clean, modern design
  - Consistent color scheme
  - Responsive layout
  - Status badges with colors

### 8.2 Color Scheme Suggestions
- Primary: Blue (#007bff)
- Success: Green (#28a745) for approved
- Warning: Yellow (#ffc107) for pending
- Danger: Red (#dc3545) for rejected
- Background: Light gray (#f8f9fa)

### 8.3 Components
- Navigation bar with role-based links
- Status badges (pending, approved, rejected)
- Responsive tables
- Form styling with proper spacing
- Flash messages styling (notice, alert)
- Button styling (primary, success, danger)

---

## 9. Implementation Steps (Order)

1. **Database Setup**
   - Create Department migration and model
   - Create Employee migration and model
   - Create Bill migration and model
   - Run migrations
   - Add associations and validations to models

2. **Authentication Setup**
   - Verify Devise is working
   - Update User model if needed
   - Test sign-in/sign-out

3. **Authorization**
   - Add authorization helpers to ApplicationController
   - Test admin/employee role checks

4. **Controllers**
   - Create HomeController
   - Create EmployeesController with CRUD
   - Create BillsController with actions
   - Add authorization to all actions

5. **Routes**
   - Set up all routes
   - Test route accessibility

6. **Views - Layout**
   - Update application layout with navigation
   - Add styling framework/base styles

7. **Views - Employees (Admin)**
   - Create index view (table)
   - Create new/edit forms
   - Create show view
   - Add styling

8. **Views - Bills**
   - Create new bill form (employee)
   - Create index view (separate for admin/employee)
   - Create show view
   - Add styling and status colors

9. **Testing**
   - Test admin flows
   - Test employee flows
   - Test authorization (try accessing unauthorized pages)
   - Test form validations

10. **Polish**
    - Add flash messages
    - Improve UI/UX
    - Add error handling
    - Test responsive design

---

## 10. Seed Data (Optional)

Create seed file for initial data:
- Create departments (Sales, Engineering, HR, etc.)
- Create admin user
- Create sample employees
- Create sample bills

---

## 11. Additional Considerations

### 11.1 Search & Filtering (Future Enhancement)
- Search employees by name/email
- Filter bills by status/type
- Filter bills by employee (admin)

### 11.2 Pagination (Future Enhancement)
- Add pagination for employees list
- Add pagination for bills list

### 11.3 File Uploads (Future Enhancement)
- Allow bill attachments/receipts

### 11.4 Email Notifications (Future Enhancement)
- Notify employee when bill is approved/rejected
- Notify admin when new bill is submitted

---

## 12. File Structure Summary

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── home_controller.rb
│   ├── employees_controller.rb
│   └── bills_controller.rb
├── models/
│   ├── user.rb
│   ├── employee.rb
│   ├── department.rb
│   └── bill.rb
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── home/
│   │   └── index.html.erb
│   ├── employees/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   ├── new.html.erb
│   │   └── edit.html.erb
│   └── bills/
│       ├── index.html.erb
│       ├── show.html.erb
│       └── new.html.erb
└── assets/
    └── stylesheets/
        └── application.css

db/
└── migrate/
    ├── 20251105134833_devise_create_users.rb
    ├── YYYYMMDDHHMMSS_create_departments.rb
    ├── YYYYMMDDHHMMSS_create_employees.rb
    └── YYYYMMDDHHMMSS_create_bills.rb
```

---

## 13. Testing Checklist

- [ ] Admin can sign in
- [ ] Employee can sign in
- [ ] Admin can view employees list
- [ ] Admin can create employee
- [ ] Admin can edit employee
- [ ] Admin can delete employee
- [ ] Employee cannot access employee CRUD
- [ ] Employee can submit bill
- [ ] Employee can view own bills
- [ ] Admin can view all bills
- [ ] Admin can approve bill
- [ ] Admin can reject bill
- [ ] Employee cannot approve/reject bills
- [ ] Status updates correctly
- [ ] Validations work on all forms
- [ ] Authorization redirects work

---

This plan provides a complete roadmap for implementing the employee reimbursement portal. Follow the steps in order, and test each component as you build it.

