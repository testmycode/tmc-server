class ChangeCoursePasteVisibility < ActiveRecord::Migration
  def up
    change_column :courses, :paste_visibility, "integer USING (CASE paste_visibility WHEN 'open' THEN '0'::integer WHEN 'protected' THEN '1'::integer WHEN 'no-tests-public' THEN '2'::integer ELSE NULL END)"
  end

  def down
    change_column :courses, :paste_visibility, "varchar USING (CASE paste_visibility WHEN '0' THEN 'open'::varchar WHEN '1' THEN 'protected'::varchar WHEN '2' THEN 'no-tests-public'::varchar ELSE NULL END)"
  end
end
