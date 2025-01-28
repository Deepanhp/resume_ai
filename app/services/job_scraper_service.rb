class JobScraperService
  def self.extract_description(url)
    require 'nokogiri'
    require 'open-uri'
    
    begin
      doc = Nokogiri::HTML(URI.open(url))
      
      # Try different common selectors for job descriptions
      description = find_description(doc)
      
      if description.blank?
        # If we can't find the description, return a user-friendly message
        raise "Could not automatically extract job description. Please paste the job description manually."
      end

      description
    rescue OpenURI::HTTPError => e
      Rails.logger.error("Failed to access URL: #{e.message}")
      raise "Could not access the job posting URL. Please check if the URL is correct and accessible."
    rescue StandardError => e
      Rails.logger.error("Job scraping error: #{e.message}")
      raise e.message
    end
  end

  private

  def self.find_description(doc)
    # Try different common selectors used by job sites
    selectors = [
      '.job-description',
      '#job-description',
      '[data-test="job-description"]',
      '.description',
      '.posting-description',
      'article',
      '.details',
      'section.description'
    ]

    selectors.each do |selector|
      content = doc.css(selector).text.strip
      return content if content.present?
    end

    # If no specific selector works, try to find content by common keywords
    doc.text.scan(/Job Description.*?Requirements/m).first ||
    doc.text.scan(/About the Role.*?Requirements/m).first ||
    doc.text.scan(/Position Description.*?Qualifications/m).first
  end
end 