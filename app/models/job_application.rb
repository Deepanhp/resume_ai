class JobApplication < ApplicationRecord
  belongs_to :user
  has_one_attached :original_resume
  has_one_attached :customized_resume
  validates :job_url, presence: true
  validates :original_resume, presence: true
  
  # Add status for tracking the customization process
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, default: :pending
end 