class AddLinkBetweenCategoriesAndShops < ActiveRecord::Migration[5.1]
  def change
    create_table :categories_shops, id: false do |t|
      t.belongs_to :category, index: true
      t.belongs_to :shop, index: true
    end
  end
end
