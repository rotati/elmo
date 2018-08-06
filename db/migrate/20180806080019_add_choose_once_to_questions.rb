class AddChooseOnceToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :choose_once, :boolean, default: false
  end
end
