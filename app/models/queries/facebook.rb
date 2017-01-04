module Queries
  class Facebook < Base
    FIELDS  = {
      'first_name'        => 'First Name',
      'last_name'         => 'Last Name',
      'gender'            => 'Gender',
      'ref'               => 'Referrer',
      'followed_link'     => 'Followed Link',
      'interaction_count' => 'Number of Interactions with Bot',
      'interacted_at'     => 'Last Interacted With Bot',
      'user_created_at'   => 'Signed Up'
    }

    def is_string_query?(field)
      field.in?(['first_name', 'last_name', 'gender', 'ref', 'followed_link'])
    end
  end
end
