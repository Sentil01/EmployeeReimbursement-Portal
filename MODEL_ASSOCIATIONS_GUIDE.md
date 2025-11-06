# Model Associations - Step-by-Step Guide

## Overview
This guide provides step-by-step commands and code for setting up associations between User, Department, Employee, and Bill models.

---

## Step 1: Add Foreign Keys to Existing Tables (if needed)

### Check if employees table has foreign keys:
```bash
rails db:schema:dump
cat db/schema.rb
```

If `employees` table is missing `department_id` and `user_id`, create a migration:

```bash
rails generate migration AddForeignKeysToEmployees department:references user:references
```

**Edit the generated migration file** (`db/migrate/YYYYMMDDHHMMSS_add_foreign_keys_to_employees.rb`):
```ruby
class AddForeignKeysToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_reference :employees, :department, null: false, foreign_key: true
    add_reference :employees, :user, null: true, foreign_key: true
    add_index :employees, :email, unique: true
  end
end
```

Run the migration:
```bash
rails db:migrate
```

---

## Step 2: Create Bills Migration (if not created)

```bash
rails generate migration CreateBills amount:decimal bill_type:string status:string employee:references submitted_by:string
```

**Edit the generated migration file** (`db/migrate/YYYYMMDDHHMMSS_create_bills.rb`):
```ruby
class CreateBills < ActiveRecord::Migration[8.0]
  def change
    create_table :bills do |t|
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :bill_type, null: false
      t.string :status, default: 'pending', null: false
      t.references :employee, null: false, foreign_key: true
      t.string :submitted_by
      t.timestamps
    end
  end
end
```

Run the migration:
```bash
rails db:migrate
```

---

## Step 3: Set Up Model Associations

### 3.1 Update User Model

**File:** `app/models/user.rb`

```ruby
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_one :employee, dependent: :destroy

  # Helper methods
  def admin?
    role == 'admin'
  end

  def employee?
    role == 'employee'
  end
end
```

**Command to edit:**
```bash
# Open the file
code app/models/user.rb
# Or use your preferred editor
```

---

### 3.2 Update Department Model

**File:** `app/models/department.rb`

```ruby
class Department < ApplicationRecord
  has_many :employees, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
end
```

**Command to edit:**
```bash
code app/models/department.rb
```

---

### 3.3 Update Employee Model

**File:** `app/models/employee.rb`

```ruby
class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :user, optional: true
  has_many :bills, dependent: :destroy

  validates :first_name, :last_name, :email, :designation, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :department_id, presence: true

  # Helper method to get full name
  def full_name
    "#{first_name} #{last_name}"
  end
end
```

**Command to edit:**
```bash
code app/models/employee.rb
```

---

### 3.4 Create Bill Model

**File:** `app/models/bill.rb` (create if doesn't exist)

```bash
touch app/models/bill.rb
```

**Add content to** `app/models/bill.rb`:

```ruby
class Bill < ApplicationRecord
  belongs_to :employee

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bill_type, presence: true, inclusion: { in: %w[food travel others] }
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :employee_id, presence: true

  # Enums for better code readability (optional but recommended)
  enum bill_type: { food: 'food', travel: 'travel', others: 'others' }
  enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  # Scope for filtering
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
end
```

**Command to create and edit:**
```bash
touch app/models/bill.rb
code app/models/bill.rb
```

---

## Step 4: Verify Associations

### 4.1 Open Rails Console

```bash
rails console
# or
rails c
```

### 4.2 Test Associations in Console

```ruby
# Test Department -> Employees
department = Department.create(name: "Sales")
employee = department.employees.create(first_name: "John", last_name: "Doe", email: "john@example.com", designation: "SDR")
department.employees.count  # Should return 1

# Test Employee -> Department
employee.department.name  # Should return "Sales"

# Test Employee -> Bills
bill = employee.bills.create(amount: 100.50, bill_type: "food", status: "pending")
employee.bills.count  # Should return 1

# Test Bill -> Employee
bill.employee.full_name  # Should return "John Doe"

# Test User -> Employee (if user is created)
user = User.create(email: "admin@example.com", password: "password123", name: "Admin User", role: "admin")
employee.update(user_id: user.id)
user.employee  # Should return the employee record
```

**Exit console:**
```ruby
exit
```

---

## Step 5: Complete Association Summary

### Association Diagram

```
User (1) -----< (0..1) Employee
                          |
                          |
                          v
                    Department (1) -----< (many) Employee
                          |
                          |
                          v
                      Employee (1) -----< (many) Bill
```

### Complete Association Code Reference

**User Model:**
```ruby
has_one :employee
```

**Department Model:**
```ruby
has_many :employees
```

**Employee Model:**
```ruby
belongs_to :department
belongs_to :user, optional: true
has_many :bills
```

**Bill Model:**
```ruby
belongs_to :employee
```

---

## Step 6: Quick Setup Commands (All at Once)

If you want to set up everything quickly, run these commands in order:

```bash
# 1. Add foreign keys to employees (if needed)
rails generate migration AddForeignKeysToEmployees department:references user:references

# 2. Create bills migration
rails generate migration CreateBills amount:decimal bill_type:string status:string employee:references submitted_by:string

# 3. Edit the migrations (add null: false, indexes, etc. as shown above)
# Then run:
rails db:migrate

# 4. Create bill model file
touch app/models/bill.rb

# 5. Edit all model files with associations as shown above
```

---

## Step 7: Verify Schema

After migrations, verify the schema:

```bash
cat db/schema.rb
```

You should see:
- `employees` table with `department_id` and `user_id` columns
- `bills` table with `employee_id` column
- Proper foreign key constraints

---

## Common Issues & Solutions

### Issue 1: Foreign key constraint error
**Solution:** Make sure to add foreign keys before running migrations, or use `null: true` for optional relationships.

### Issue 2: Association not working
**Solution:** 
- Check if foreign keys exist in schema
- Verify model files have correct association syntax
- Restart Rails console/server

### Issue 3: `optional: true` needed
**Solution:** Use `belongs_to :user, optional: true` if user association is optional (not all employees may have a user account).

---

## Testing Associations

After setting up, test in Rails console:

```bash
rails console
```

```ruby
# Create test data
dept = Department.create(name: "Engineering")
user = User.create(email: "test@example.com", password: "password123", name: "Test User", role: "employee")
emp = Employee.create(first_name: "Jane", last_name: "Smith", email: "jane@example.com", designation: "Developer", department: dept, user: user)
bill = Bill.create(amount: 250.00, bill_type: "travel", status: "pending", employee: emp)

# Test associations
dept.employees.include?(emp)  # true
emp.department == dept  # true
emp.user == user  # true
emp.bills.include?(bill)  # true
bill.employee == emp  # true
```

---

## Next Steps

After associations are set up:
1. Add validations (shown in model examples above)
2. Create controllers with proper authorization
3. Set up views to display associated data
4. Test the relationships in your application

---

## Quick Reference Commands

```bash
# Generate migration
rails generate migration MigrationName field:type

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status

# Open Rails console
rails console

# View schema
cat db/schema.rb

# Create model file
touch app/models/model_name.rb
```

