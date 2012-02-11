# Configures extra user fields
group 'Suoritusaikeet' do
  field({
    :name => 'koko_nimi',
    :field_type => 'text',
    :label => 'Etu- ja sukunimi',
  })
  field({
    :name => 'hakee_yliopistoon',
    :field_type => 'boolean',
    :label => 'Aion hakea tänä keväänä yliopistoon MOOC:in avulla.',
  })
  field({
    :name => 'osasuorituskoe1_hy',
    :field_type => 'boolean',
    :label => 'Osallistun osasuorituskokeeseen 1 HY:n tiloissa.',
  })
  field({
    :name => 'osasuorituskoe1_lukio',
    :field_type => 'boolean',
    :label => 'Osallistun osasuorituskokeeseen 1 omassa lukiossa ja olen sopinut, että opettajani ottaa yhteyttä mooc-henkilökuntaan.',
  })
end
