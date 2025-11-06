# Employee Reimbursement Portal - Complete Implementation Guide

## Current State Analysis

### ✅ What's Already Done:
- Database schema with Users, Departments, Employees, Bills tables
- Devise authentication set up
- Basic models created (but need validations and associations fixed)
- EmployeesController exists (needs authorization)
- Basic routes configured

### ❌ What Needs to be Fixed/Built:
1. Fix model syntax errors (Employee model has `has_many: bills` - missing space)
2. Fix Bills migration - `type` column should be `bill_type` (type is reserved in Rails)
3. Add validations to all models
4. Add authorization helpers to ApplicationController
5. Create HomeController
6. Create BillsController
7. Update routes
8. Build all views with proper UI
9. Add styling

---

## PART 1: Fix Database & Models

### Step 1.1: Fix Bills Migration (CRITICAL - type is reserved word)

**Problem:** The bills table uses `type` which is reserved in Rails. Need to rename to `bill_type`.

**Solution:** Create a migration to rename the column:

```bash
rails generate migration RenameTypeToBillTypeInBills
```

**Edit the migration file** (`db/migrate/YYYYMMDDHHMMSS_rename_type_to_bill_type_in_bills.rb`):
```ruby
class RenameTypeToBillTypeInBills < ActiveRecord::Migration[8.0]
  def change
    rename_column :bills, :type, :bill_type
  end
end
```

**Run migration:**
```bash
rails db:migrate
```

### Step 1.2: Fix Employee Model Syntax Error

**File:** `app/models/employee.rb`

**Current (WRONG):**
```ruby
has_many: bills, dependent: :destroy
```

**Fix to:**
```ruby
has_many :bills, dependent: :destroy
```

### Step 1.3: Update All Models with Validations

**File:** `app/models/user.rb`
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :employee, dependent: :destroy

  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin employee] }

  def admin?
    role == 'admin'
  end

  def employee?
    role == 'employee'
  end
end
```

**File:** `app/models/department.rb`
```ruby
class Department < ApplicationRecord
  has_many :employees, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
end
```

**File:** `app/models/employee.rb`
```ruby
class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :user, optional: true
  has_many :bills, dependent: :destroy

  validates :first_name, :last_name, :email, :designation, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :department_id, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
```

**File:** `app/models/bill.rb`
```ruby
class Bill < ApplicationRecord
  belongs_to :employee

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bill_type, presence: true, inclusion: { in: %w[food travel others] }
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :employee_id, presence: true

  enum bill_type: { food: 'food', travel: 'travel', others: 'others' }
  enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
end
```

---

## PART 2: Authorization & Controllers

### Step 2.1: Update ApplicationController

**File:** `app/controllers/application_controller.rb`
```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  before_action :authenticate_user!

  # Authorization helpers
  def admin?
    current_user&.role == 'admin'
  end

  def employee?
    current_user&.role == 'employee'
  end

  def ensure_admin
    unless admin?
      redirect_to root_path, alert: 'Access denied. Admin only.'
    end
  end

  def ensure_employee
    unless employee?
      redirect_to root_path, alert: 'Access denied. Employee only.'
    end
  end

  helper_method :admin?, :employee?
end
```

### Step 2.2: Create HomeController

**Generate:**
```bash
rails generate controller Home index
```

**File:** `app/controllers/home_controller.rb`
```ruby
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      if admin?
        redirect_to employees_path
      else
        redirect_to bills_path
      end
    end
  end
end
```

### Step 2.3: Update EmployeesController with Authorization

**File:** `app/controllers/employees_controller.rb`
```ruby
class EmployeesController < ApplicationController
  before_action :ensure_admin
  before_action :set_employee, only: %i[show edit update destroy]

  def index
    @employees = Employee.includes(:department).all
  end

  def show
  end

  def new
    @employee = Employee.new
    @departments = Department.all
  end

  def edit
    @departments = Department.all
  end

  def create
    @employee = Employee.new(employee_params)
    @departments = Department.all

    if @employee.save
      redirect_to @employee, notice: "Employee was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @departments = Department.all
    if @employee.update(employee_params)
      redirect_to @employee, notice: "Employee was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "Employee was successfully deleted."
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :designation, :department_id, :user_id)
  end
end
```

### Step 2.4: Create BillsController

**Generate:**
```bash
rails generate controller Bills index show new create approve reject
```

**File:** `app/controllers/bills_controller.rb`
```ruby
class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :approve, :reject]
  before_action :ensure_employee, only: [:new, :create]
  before_action :ensure_admin, only: [:approve, :reject]

  def index
    if admin?
      @bills = Bill.includes(:employee).order(created_at: :desc)
    else
      # Find employee associated with current user
      employee = current_user.employee
      if employee
        @bills = employee.bills.order(created_at: :desc)
      else
        @bills = Bill.none
      end
    end
  end

  def show
  end

  def new
    @bill = Bill.new
    @employee = current_user.employee
  end

  def create
    @employee = current_user.employee
    @bill = @employee.bills.build(bill_params)
    @bill.status = 'pending'
    @bill.submitted_by = @employee.full_name

    if @bill.save
      redirect_to bills_path, notice: "Bill submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    if @bill.update(status: 'approved')
      redirect_to bills_path, notice: "Bill approved successfully."
    else
      redirect_to bills_path, alert: "Failed to approve bill."
    end
  end

  def reject
    if @bill.update(status: 'rejected')
      redirect_to bills_path, notice: "Bill rejected successfully."
    else
      redirect_to bills_path, alert: "Failed to reject bill."
    end
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end

  def bill_params
    params.require(:bill).permit(:amount, :bill_type)
  end
end
```

---

## PART 3: Routes Configuration

### Step 3.1: Update Routes

**File:** `config/routes.rb`
```ruby
Rails.application.routes.draw do
  devise_for :users
  
  root 'home#index'

  # Admin routes - Employee CRUD
  resources :employees, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # Bill routes
  resources :bills, only: [:index, :show, :new, :create] do
    member do
      patch :approve
      patch :reject
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## PART 4: Views - Layout & Navigation

### Step 4.1: Update Application Layout

**File:** `app/views/layouts/application.html.erb`
```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Employee Reimbursement Portal" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <nav class="navbar">
      <div class="nav-container">
        <div class="nav-brand">
          <%= link_to "Reimbursement Portal", root_path, class: "nav-link" %>
        </div>
        <div class="nav-links">
          <% if user_signed_in? %>
            <span class="user-info">Logged in as: <strong><%= current_user.name %></strong> (<%= current_user.role %>)</span>
            <% if admin? %>
              <%= link_to "Employees", employees_path, class: "nav-link" %>
              <%= link_to "All Bills", bills_path, class: "nav-link" %>
            <% else %>
              <%= link_to "Submit Bill", new_bill_path, class: "nav-link" %>
              <%= link_to "My Bills", bills_path, class: "nav-link" %>
            <% end %>
            <%= link_to "Sign Out", destroy_user_session_path, method: :delete, class: "nav-link" %>
          <% else %>
            <%= link_to "Sign In", new_user_session_path, class: "nav-link" %>
          <% end %>
        </div>
      </div>
    </nav>

    <main class="main-content">
      <% if notice %>
        <div class="alert alert-success"><%= notice %></div>
      <% end %>
      <% if alert %>
        <div class="alert alert-danger"><%= alert %></div>
      <% end %>

      <%= yield %>
    </main>
  </body>
</html>
```

---

## PART 5: Views - Employees (Admin)

### Step 5.1: Employees Index

**File:** `app/views/employees/index.html.erb`
```erb
<% content_for :title, "Employees" %>

<div class="page-header">
  <h1>Employees</h1>
  <%= link_to "New Employee", new_employee_path, class: "btn btn-primary" %>
</div>

<div class="table-container">
  <table class="data-table">
    <thead>
      <tr>
        <th>Full Name</th>
        <th>Designation</th>
        <th>Department</th>
        <th>Email</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @employees.each do |employee| %>
        <tr>
          <td><%= employee.full_name %></td>
          <td><%= employee.designation %></td>
          <td><%= employee.department.name %></td>
          <td><%= employee.email %></td>
          <td>
            <%= link_to "View", employee, class: "btn btn-sm btn-info" %>
            <%= link_to "Edit", edit_employee_path(employee), class: "btn btn-sm btn-warning" %>
            <%= link_to "Delete", employee, method: :delete, 
                data: { confirm: "Are you sure?" }, 
                class: "btn btn-sm btn-danger" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Step 5.2: Employee Form (New & Edit)

**File:** `app/views/employees/_form.html.erb`
```erb
<%= form_with(model: employee) do |form| %>
  <% if employee.errors.any? %>
    <div class="error-messages">
      <h3><%= pluralize(employee.errors.count, "error") %> prohibited this employee from being saved:</h3>
      <ul>
        <% employee.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :first_name, class: "form-label" %>
    <%= form.text_field :first_name, class: "form-control" %>
  </div>

  <div class="form-group">
    <%= form.label :last_name, class: "form-label" %>
    <%= form.text_field :last_name, class: "form-control" %>
  </div>

  <div class="form-group">
    <%= form.label :email, class: "form-label" %>
    <%= form.email_field :email, class: "form-control" %>
  </div>

  <div class="form-group">
    <%= form.label :designation, class: "form-label" %>
    <%= form.text_field :designation, class: "form-control" %>
  </div>

  <div class="form-group">
    <%= form.label :department_id, "Department", class: "form-label" %>
    <%= form.collection_select :department_id, @departments, :id, :name, 
        { prompt: "Select Department" }, { class: "form-control" } %>
  </div>

  <div class="form-actions">
    <%= form.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", employees_path, class: "btn btn-secondary" %>
  </div>
<% end %>
```

### Step 5.3: Employee New

**File:** `app/views/employees/new.html.erb`
```erb
<% content_for :title, "New Employee" %>

<h1>New Employee</h1>
<%= render "form", employee: @employee %>
```

### Step 5.4: Employee Edit

**File:** `app/views/employees/edit.html.erb`
```erb
<% content_for :title, "Edit Employee" %>

<h1>Edit Employee</h1>
<%= render "form", employee: @employee %>
```

### Step 5.5: Employee Show

**File:** `app/views/employees/show.html.erb`
```erb
<% content_for :title, @employee.full_name %>

<div class="detail-page">
  <div class="detail-header">
    <h1><%= @employee.full_name %></h1>
    <%= link_to "Edit", edit_employee_path(@employee), class: "btn btn-warning" %>
    <%= link_to "Back to Employees", employees_path, class: "btn btn-secondary" %>
  </div>

  <div class="detail-content">
    <div class="detail-item">
      <strong>First Name:</strong>
      <%= @employee.first_name %>
    </div>
    <div class="detail-item">
      <strong>Last Name:</strong>
      <%= @employee.last_name %>
    </div>
    <div class="detail-item">
      <strong>Email:</strong>
      <%= @employee.email %>
    </div>
    <div class="detail-item">
      <strong>Designation:</strong>
      <%= @employee.designation %>
    </div>
    <div class="detail-item">
      <strong>Department:</strong>
      <%= @employee.department.name %>
    </div>
  </div>
</div>
```

---

## PART 6: Views - Bills

### Step 6.1: Bills Index (Different for Admin/Employee)

**File:** `app/views/bills/index.html.erb`
```erb
<% content_for :title, admin? ? "All Bills" : "My Bills" %>

<div class="page-header">
  <h1><%= admin? ? "All Bills" : "My Bills" %></h1>
  <% unless admin? %>
    <%= link_to "Submit New Bill", new_bill_path, class: "btn btn-primary" %>
  <% end %>
</div>

<div class="table-container">
  <table class="data-table">
    <thead>
      <tr>
        <% if admin? %><th>Employee</th><% end %>
        <th>Amount</th>
        <th>Type</th>
        <th>Status</th>
        <th>Submitted Date</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% if @bills.any? %>
        <% @bills.each do |bill| %>
          <tr>
            <% if admin? %>
              <td><%= bill.employee.full_name %></td>
            <% end %>
            <td>$<%= number_with_precision(bill.amount, precision: 2) %></td>
            <td><%= bill.bill_type.humanize %></td>
            <td>
              <span class="status-badge status-<%= bill.status %>">
                <%= bill.status.humanize %>
              </span>
            </td>
            <td><%= bill.created_at.strftime("%B %d, %Y") %></td>
            <td>
              <%= link_to "View", bill, class: "btn btn-sm btn-info" %>
              <% if admin? && bill.pending? %>
                <%= link_to "Approve", approve_bill_path(bill), method: :patch, 
                    class: "btn btn-sm btn-success" %>
                <%= link_to "Reject", reject_bill_path(bill), method: :patch, 
                    class: "btn btn-sm btn-danger" %>
              <% end %>
            </td>
          </tr>
        <% end %>
      <% else %>
        <tr>
          <td colspan="<%= admin? ? 6 : 5 %>" class="text-center">No bills found</td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Step 6.2: New Bill Form

**File:** `app/views/bills/new.html.erb`
```erb
<% content_for :title, "Submit Bill" %>

<h1>Submit Reimbursement Bill</h1>

<%= form_with(model: @bill, url: bills_path) do |form| %>
  <% if @bill.errors.any? %>
    <div class="error-messages">
      <h3><%= pluralize(@bill.errors.count, "error") %> prohibited this bill from being saved:</h3>
      <ul>
        <% @bill.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :bill_type, "Type", class: "form-label" %>
    <%= form.select :bill_type, 
        options_for_select([['Food', 'food'], ['Travel', 'travel'], ['Others', 'others']]),
        { prompt: "Select Type" }, 
        { class: "form-control" } %>
  </div>

  <div class="form-group">
    <%= form.label :amount, class: "form-label" %>
    <%= form.number_field :amount, step: 0.01, min: 0.01, class: "form-control", placeholder: "0.00" %>
  </div>

  <div class="form-actions">
    <%= form.submit "Submit Bill", class: "btn btn-primary" %>
    <%= link_to "Cancel", bills_path, class: "btn btn-secondary" %>
  </div>
<% end %>
```

### Step 6.3: Bill Show

**File:** `app/views/bills/show.html.erb`
```erb
<% content_for :title, "Bill Details" %>

<div class="detail-page">
  <div class="detail-header">
    <h1>Bill Details</h1>
    <%= link_to "Back to Bills", bills_path, class: "btn btn-secondary" %>
  </div>

  <div class="detail-content">
    <% if admin? %>
      <div class="detail-item">
        <strong>Employee:</strong>
        <%= @bill.employee.full_name %>
      </div>
      <div class="detail-item">
        <strong>Email:</strong>
        <%= @bill.employee.email %>
      </div>
    <% end %>
    <div class="detail-item">
      <strong>Amount:</strong>
      $<%= number_with_precision(@bill.amount, precision: 2) %>
    </div>
    <div class="detail-item">
      <strong>Type:</strong>
      <%= @bill.bill_type.humanize %>
    </div>
    <div class="detail-item">
      <strong>Status:</strong>
      <span class="status-badge status-<%= @bill.status %>">
        <%= @bill.status.humanize %>
      </span>
    </div>
    <div class="detail-item">
      <strong>Submitted By:</strong>
      <%= @bill.submitted_by || @bill.employee.full_name %>
    </div>
    <div class="detail-item">
      <strong>Submitted Date:</strong>
      <%= @bill.created_at.strftime("%B %d, %Y at %I:%M %p") %>
    </div>
  </div>

  <% if admin? && @bill.pending? %>
    <div class="detail-actions">
      <%= link_to "Approve", approve_bill_path(@bill), method: :patch, 
          class: "btn btn-success" %>
      <%= link_to "Reject", reject_bill_path(@bill), method: :patch, 
          class: "btn btn-danger" %>
    </div>
  <% end %>
</div>
```

---

## PART 7: Styling (CSS)

### Step 7.1: Add Application Styles

**File:** `app/assets/stylesheets/application.css`
```css
/* Reset and Base Styles */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background-color: #f5f5f5;
  color: #333;
  line-height: 1.6;
}

/* Navigation */
.navbar {
  background-color: #2c3e50;
  color: white;
  padding: 1rem 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-brand .nav-link {
  font-size: 1.5rem;
  font-weight: bold;
  color: white;
  text-decoration: none;
}

.nav-links {
  display: flex;
  gap: 1.5rem;
  align-items: center;
}

.nav-link {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.nav-link:hover {
  background-color: rgba(255,255,255,0.1);
}

.user-info {
  color: #ecf0f1;
  font-size: 0.9rem;
}

/* Main Content */
.main-content {
  max-width: 1200px;
  margin: 2rem auto;
  padding: 0 2rem;
}

/* Alerts */
.alert {
  padding: 1rem;
  margin-bottom: 1.5rem;
  border-radius: 4px;
  border-left: 4px solid;
}

.alert-success {
  background-color: #d4edda;
  border-color: #28a745;
  color: #155724;
}

.alert-danger {
  background-color: #f8d7da;
  border-color: #dc3545;
  color: #721c24;
}

/* Page Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
}

/* Buttons */
.btn {
  display: inline-block;
  padding: 0.6rem 1.2rem;
  border: none;
  border-radius: 4px;
  text-decoration: none;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.3s;
  text-align: center;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover {
  background-color: #0056b3;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background-color: #545b62;
}

.btn-success {
  background-color: #28a745;
  color: white;
}

.btn-success:hover {
  background-color: #218838;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover {
  background-color: #c82333;
}

.btn-warning {
  background-color: #ffc107;
  color: #212529;
}

.btn-warning:hover {
  background-color: #e0a800;
}

.btn-info {
  background-color: #17a2b8;
  color: white;
}

.btn-info:hover {
  background-color: #138496;
}

.btn-sm {
  padding: 0.4rem 0.8rem;
  font-size: 0.85rem;
}

/* Tables */
.table-container {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table thead {
  background-color: #f8f9fa;
}

.data-table th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #495057;
  border-bottom: 2px solid #dee2e6;
}

.data-table td {
  padding: 1rem;
  border-bottom: 1px solid #dee2e6;
}

.data-table tbody tr:hover {
  background-color: #f8f9fa;
}

.text-center {
  text-align: center;
}

/* Status Badges */
.status-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 500;
}

.status-pending {
  background-color: #ffc107;
  color: #856404;
}

.status-approved {
  background-color: #28a745;
  color: white;
}

.status-rejected {
  background-color: #dc3545;
  color: white;
}

/* Forms */
.form-group {
  margin-bottom: 1.5rem;
}

.form-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #495057;
}

.form-control {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.form-control:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0,123,255,0.1);
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

/* Error Messages */
.error-messages {
  background-color: #f8d7da;
  color: #721c24;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1.5rem;
  border-left: 4px solid #dc3545;
}

.error-messages h3 {
  margin-bottom: 0.5rem;
}

.error-messages ul {
  margin-left: 1.5rem;
}

/* Detail Pages */
.detail-page {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #dee2e6;
}

.detail-content {
  margin-bottom: 2rem;
}

.detail-item {
  padding: 0.75rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.detail-item strong {
  display: inline-block;
  width: 150px;
  color: #495057;
}

.detail-actions {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 2px solid #dee2e6;
  display: flex;
  gap: 1rem;
}
```

---

## PART 8: Testing Checklist

### Quick Test Steps:

1. **Start Rails Server:**
   ```bash
   rails server
   ```

2. **Create Test Data (Rails Console):**
   ```bash
   rails console
   ```
   ```ruby
   # Create departments
   dept1 = Department.create(name: "Sales")
   dept2 = Department.create(name: "Engineering")
   
   # Create admin user
   admin = User.create(email: "admin@example.com", password: "password123", name: "Admin User", role: "admin")
   
   # Create employee user
   emp_user = User.create(email: "employee@example.com", password: "password123", name: "John Employee", role: "employee")
   
   # Create employees
   emp1 = Employee.create(first_name: "John", last_name: "Doe", email: "john@example.com", designation: "SDR", department: dept1)
   emp2 = Employee.create(first_name: "Andrew", last_name: "Smith", email: "andrew@example.com", designation: "Intern", department: dept2, user: emp_user)
   
   # Create bills
   Bill.create(amount: 50.00, bill_type: "food", status: "pending", employee: emp2)
   Bill.create(amount: 200.00, bill_type: "travel", status: "pending", employee: emp1)
   ```

3. **Test Flow:**
   - Sign in as admin → Should see Employees list
   - Create/Edit/Delete employee
   - View all bills
   - Approve/Reject bills
   - Sign out
   - Sign in as employee → Should see "My Bills"
   - Submit new bill
   - View own bills only

---

## PART 9: Quick Fix Commands

Run these in order:

```bash
# 1. Fix bills migration
rails generate migration RenameTypeToBillTypeInBills
# Then edit the migration file and add: rename_column :bills, :type, :bill_type
rails db:migrate

# 2. Create controllers
rails generate controller Home index
rails generate controller Bills index show new create approve reject

# 3. Test the application
rails server
```

---

## Summary

This guide covers:
- ✅ Fixed database schema issues
- ✅ Complete model validations
- ✅ Authorization system
- ✅ All controllers with proper logic
- ✅ All views with rich UI
- ✅ Complete styling
- ✅ Testing steps

Follow each part sequentially and test after each major section!

