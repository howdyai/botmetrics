class InviteToSlackJob < Job
  def perform(user_id)
    User.with_advisory_lock("invite-to-slack-#{user_id}") do
      user = User.find_by_id(user_id)
      if user.present? && user.invited_to_slack_at.blank?
        response = SlackInviter.invite(user.email, user.full_name)

        if response['ok'] == true
          user.update_attributes(invited_to_slack_at: Time.now,
                                 slack_invite_response: response)
        else
          user.update_attributes(slack_invite_response: response)
        end
      end
    end
  end
end
