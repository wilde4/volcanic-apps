class CreateLikesLikes < ActiveRecord::Migration
  def change
    create_table :likes_likes do |t|
      t.integer :like_id, index: true
      t.integer :user_id
      t.references :likeable, polymorphic: true, index: true
      t.text :extra
      t.boolean :match, default: false

      t.timestamps
    end
  end
end
