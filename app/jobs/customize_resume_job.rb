class CustomizeResumeJob < ApplicationJob
  queue_as :default

  def perform(job_application_id)
    job_application = JobApplication.find(job_application_id)
    job_application.update(status: :processing)

    begin
      # Extract job description if not already present
      unless job_application.job_description.present?
        job_description = JobScraperService.extract_description(job_application.job_url)
        job_application.update!(job_description: job_description)
      end

      # Process the resume
      pdf_content = ResumeCustomizerService.customize(
        original_resume: job_application.original_resume,
        job_description: job_application.job_description
      )

      Rails.logger.info("PDF content size: #{pdf_content.bytesize} bytes")

      # Create a temp file for the PDF
      temp_pdf = Tempfile.new(['customized_resume', '.pdf'])
      temp_pdf.binmode
      temp_pdf.write(pdf_content)
      temp_pdf.rewind

      # Attach the customized resume
      job_application.customized_resume.attach(
        io: temp_pdf,
        filename: "customized_resume.pdf",
        content_type: "application/pdf"
      )

      job_application.update!(status: :completed)
    rescue => e
      job_application.update!(
        status: :failed,
        error_message: e.message
      )
      Rails.logger.error("Resume customization failed: #{e.full_message}")
      raise e
    ensure
      # Clean up temp file
      temp_pdf&.close
      temp_pdf&.unlink
    end
  end
end 