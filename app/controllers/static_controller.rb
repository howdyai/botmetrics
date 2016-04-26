class StaticController < ApplicationController
  layout 'bare'

  def index
  end

  def letsencrypt
    render text: 'TVAQ1mHoZykrk40sVCNFpGIc03MSDajgp-e758SpG4w.Xxo_ImoX_5mqmLIsmpF8ecjbaPa8GmVSipNI5wpr0uo'
  end
end
