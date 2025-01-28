module ApplicationHelper
  def status_color(status)
    case status
    when 'pending'
      'text-yellow-600'
    when 'processing'
      'text-blue-600'
    when 'completed'
      'text-green-600'
    when 'failed'
      'text-red-600'
    end
  end
end
