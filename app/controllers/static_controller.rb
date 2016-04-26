class StaticController < ApplicationController
  layout 'bare'

  def index
    if current_user.present?
      redirect_to(team_path(current_user.teams.first)) && return
    end
  end

  def letsencrypt
    render text: 'TVAQ1mHoZykrk40sVCNFpGIc03MSDajgp-e758SpG4w.Xxo_ImoX_5mqmLIsmpF8ecjbaPa8GmVSipNI5wpr0uo'
  end
end
