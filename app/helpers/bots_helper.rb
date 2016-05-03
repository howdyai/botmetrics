module BotsHelper
  def formatted_growth(growth)
    if growth.present?
      growth = growth * 100
      klass = growth > 0 ? 'positive' : 'negative'

      icon = if growth.to_i == 0
               "<i class='fa fa-arrows-h'></i>"
             elsif growth.to_i > 0
               "<i class='fa fa-arrow-up'></i>"
             else
               "<i class='fa fa-arrow-down'></i>"
             end

      "<p class='growth #{klass}'>#{icon}#{number_to_percentage(growth, precision: 0)}</p>".html_safe
    else
      nil
    end
  end
end
