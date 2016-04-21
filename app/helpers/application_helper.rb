module ApplicationHelper
  def body_classes(classes=nil)
    ary = [Rails.application.class.to_s.split("::").first.downcase]
    ary << controller.controller_name
    ary << controller.action_name

    unless classes.nil?
      method = classes.is_a?(Array) ? :concat : :<<
      ary.send method, classes
    end

    ary.join(' ').strip
  end
end
