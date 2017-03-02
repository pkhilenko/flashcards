class Card < ApplicationRecord

  has_attached_file :image, styles: { medium: "360x360>" }, default_url: "/images/:style/missing.png"     
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  validates :original, :translated, :user_id, presence: true 
  validates :original, :translated, uniqueness: { scope: :user, case_sensitive: false }
  validate  :on_review, on: :create
  validate  :no_equal, on: [:create, :update]

  belongs_to :user
  belongs_to :pack
  
  scope :for_review, -> { where( 'review <= ?', Time.now.localtime ) }

  def comparison(txt)
    q = Text::Levenshtein.distance(self.original, txt)
    original == txt
  end

  def right_answer!
    self.update_attributes(review: date_review(self.term_review += 1), counter_review: 0) 
  end

  def wrong_answer!
    if self.counter_review > 2
      update(counter_review: self.counter_review += 1, term_review: 0)
    else
      update(counter_review: self.counter_review += 1)
    end
  end

  protected

  def date_review term
    case term
    when 0 then Time.now
    when 1 then Time.now + 12.hours
    when 2 then 3.days.from_now
    when 3 then 7.days.from_now
    when 4 then 14.days.from_now
    when 5 then 30.days.from_now
    else 30.days.from_now
    end
  end

  def on_review 
    self.review = -3.days.from_now
  end

  def no_equal
    if self.original.downcase == self.translated.downcase
      self.errors.add( :original, 'Оригинальный и переведённый тексты не должны быть равны друг другу')
    end
  end
end
