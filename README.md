# Employee Reimbursement Portal

A Ruby on Rails web application for managing employee reimbursement claims.

## Features

- **Employee Role**: Submit bills, track reimbursement status, view summary statistics
- **Admin Role**: Manage employees, departments, approve/reject bills, view dashboard

## Tech Stack

- Ruby 3.4.7
- Rails 8.0.4
- SQLite3 (Development) / PostgreSQL (Production)
- Devise (Authentication)

## Setup

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Start server
rails server
```

## Usage

1. Sign up as Admin or Employee
2. Employees can submit bills for reimbursement
3. Admins can approve/reject bills and manage employees
4. Admin-created employees receive temporary passwords for login

## Deployment

Configured for Render. See `render.yaml` for deployment settings.
