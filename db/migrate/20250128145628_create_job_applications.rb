class CreateJobApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :job_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_url
      t.integer :status
      t.text :job_description

      t.timestamps
    end
  end
end
