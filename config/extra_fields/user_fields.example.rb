# Configures extra user fields
group 'Other' do
  html('<p>Please provide your full name if ...</p>')
  field({
    :name => 'full_name',
    :field_type => 'text',
    :label => 'First and Last name',
    :show_in_participant_list => true
  })
end