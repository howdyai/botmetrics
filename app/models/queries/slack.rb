module Queries
  class Slack < Base
    FIELDS  = {
      'nickname'          => 'Nickname',
      'email'             => 'Email',
      'full_name'         => 'Full Name',
      'followed_link'     => 'Followed Link',
      'interaction_count' => 'Number of Interactions with Bot',
      'interacted_at'     => 'Last Interacted With Bot',
      'user_created_at'   => 'Signed Up',
    }

    def is_string_query?(field)
      field.in?(['nickname', 'email', 'full_name', 'followed_link'])
    end
  end
end
