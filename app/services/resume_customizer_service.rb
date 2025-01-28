class ResumeCustomizerService
  MAX_RETRIES = 3
  RETRY_DELAY = 5 # seconds
  
  def self.customize(original_resume:, job_description:)
    require 'httparty'

    # Extract text from the original resume
    resume_text = extract_text_from_resume(original_resume)
    Rails.logger.info("\n=== Extracted Resume Text ===\n#{resume_text}\n===================")

    begin
      # Create a structured prompt for GPT
      prompt = {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are a professional resume writer. Your task is to rewrite resumes to match job descriptions while keeping all information truthful and maintaining the original structure."
          },
          {
            role: "user",
            content: <<~PROMPT
              Please customize this resume for the job description provided.
              
              Guidelines:
              - Keep all information truthful and based on the original resume
              - Maintain the same sections and structure
              - Highlight relevant skills and experiences
              - Use clear, professional language
              - Keep bullet points concise and impactful
              - Output only the customized resume content
              
              Original Resume:
              #{resume_text}
              
              Job Description:
              #{job_description}
            PROMPT
          }
        ],
        temperature: 0.7
      }

      Rails.logger.info("\n=== Sending request to OpenAI ===")
      
      response = HTTParty.post(
        'https://api.openai.com/v1/chat/completions',
        headers: {
          'Authorization' => "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}",
          'Content-Type' => 'application/json'
        },
        body: prompt.to_json,
        timeout: 30
      )

      Rails.logger.info("\n=== Response Status: #{response.code} ===")

      if response.code != 200
        error_message = "API Error: #{response.body}"
        Rails.logger.error(error_message)
        raise error_message
      end

      customized_text = response.parsed_response.dig('choices', 0, 'message', 'content').to_s

      # Clean up the response
      customized_text = customized_text
        .gsub(/^(As an AI|I am an AI|Note:|Disclaimer:|Consider|Include|Links?:).*$/i, '')
        .gsub(/\bhttps?:\/\/\S+\b/, '')
        .gsub(/\n{3,}/, "\n\n")
        .gsub(/^[\s\-\•\*]+/, '')
        .strip

      if customized_text.blank?
        Rails.logger.error("Response was blank after cleanup")
        raise "Failed to generate customized resume content"
      end

      # Generate PDF with improved formatting
      pdf = Prawn::Document.new(margin: 50) do |doc|
        doc.font "Helvetica"
        
        # Split content into lines and process each
        customized_text.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          if line.upcase == line && line.length > 3  # Section header
            doc.move_down 15
            doc.font("Helvetica", style: :bold) { doc.text line, size: 14 }
            doc.move_down 5
          elsif line.start_with?("-", "•", "*")  # Bullet point
            doc.indent(10) do
              doc.text line.gsub(/^[-•*]\s*/, "• "), size: 10, leading: 4
            end
          else  # Regular text
            doc.text line, size: 10, leading: 4
          end
        end

        # Add page numbers
        doc.number_pages "Page <page> of <total>",
                        at: [doc.bounds.right - 150, 0],
                        width: 150,
                        align: :right,
                        size: 8
      end

      pdf.render
    rescue => e
      error_message = "Resume customization error: #{e.full_message}"
      Rails.logger.error(error_message)
      raise error_message
    end
  end

  private

  def self.extract_text_from_resume(resume)
    content_type = resume.content_type
    
    case content_type
    when 'application/pdf'
      extract_text_from_pdf(resume)
    when 'text/plain'
      resume.download.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    else
      raise "Unsupported file type: #{content_type}"
    end
  end

  def self.extract_text_from_pdf(resume)
    require 'pdf-reader'
    
    pdf_content = resume.download
    reader = PDF::Reader.new(StringIO.new(pdf_content))
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.error("PDF extraction error: #{e.message}")
    raise "Could not read PDF file: #{e.message}"
  end

  def self.split_resume_into_sections(text)
    # Split on common section headers
    sections = text.split(/^(EDUCATION|EXPERIENCE|SKILLS|SUMMARY):/i)
    sections.map(&:strip).reject(&:empty?)
  end

  def self.process_section(prompt)
    response = HTTParty.post(
      'https://api-inference.huggingface.co/models/facebook/bart-large-cnn',
      headers: {
        'Authorization' => "Bearer #{Rails.application.credentials.dig(:huggingface, :api_key)}",
        'Content-Type' => 'application/json'
      },
      body: {
        inputs: prompt,
        parameters: {
          max_new_tokens: 256,
          temperature: 0.7,
          return_full_text: false
        }
      }.to_json,
      timeout: 30
    )

    if response.code == 200
      response.parsed_response[0]['generated_text'].to_s
    else
      Rails.logger.error("API Error for section: #{response.body}")
      raise "Failed to process section"
    end
  end
end 