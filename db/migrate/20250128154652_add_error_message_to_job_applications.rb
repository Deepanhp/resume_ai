class AddErrorMessageToJobApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :job_applications, :error_message, :text
  end
end
