Chartkick.options = {
  height: '400px',
  colors: ['#3bafda']
}


Chartkick.options[:content_for] = :charts_js if Rails.env.development?
