class CreateBills < ActiveRecord::Migration[8.0]
  def change
    create_table :bills do |t|
      t.decimal :amount
      t.string :bill_type
      t.string :status
      t.references :employee, null: false, foreign_key: true
      t.string :submitted_by

      t.timestamps
    end
  end
end
