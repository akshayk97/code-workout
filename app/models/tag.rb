# == Schema Information
#
# Table name: tags
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  taggings_count :integer          default(0)
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#

# =============================================================================
# Represents a tag, used for filtering/searching exercises or workouts.
#
class Tag < ActiveRecord::Base

  #~ Relationships ............................................................

  has_and_belongs_to_many :exercises
  has_and_belongs_to_many :workouts
  has_many :tag_user_scores, inverse_of: :tag, dependent: :destroy


  #~ Hooks ....................................................................

  before_validation :standardize_tag, :standardize_tagtype


  #~ Validation ...............................................................

  validates :tag_name, presence: true, uniqueness: true

  TYPES = {
    'Misc' => 0,
    'Area' => 1,
    'Language' => 2,
    'Skill' => 3
  }


  #~ Public methods ...........................................................


  #~ Public class methods .....................................................

  # -------------------------------------------------------------
  def self.type_name(type)
    TYPES.rassoc(type).first
  end


  # -------------------------------------------------------------
  def self.normalize(name)
    return name.strip.gsub(/[\s]/,"_").downcase.titleize
  end


  # -------------------------------------------------------------
  #~ pass in an object (Exercise or Workout)
  def self.tag_this_with(obj, t_name, t_type)
    convention = self.normalize(t_name)
    duplicate = obj.tags.bsearch { |t| t.name == convention }
    if duplicate.nil?
      tagged = Tag.find_by(name: convention)

      if tagged.blank?
        tagged = Tag.new
        tagged.name = convention
        tagged.tagtype = t_type
      else        
        tagged = tagged.first
        tagged.taggings_count += 1
      end

      if obj.class.name == 'Exercise'
        tagged.total_exercises = tagged.total_exercises + 1
        tagged.total_experience += obj.experience
      end
      tagged.save
      # obj.tags << tagged

      if obj.class.name == 'Exercise'
        tagged.exercises << obj
      elsif obj.class.name == 'Workout'
        tagged.workouts << obj
      end
    end
  end


  # -------------------------------------------------------------
  def self.misc
    return TYPES['Misc']
  end


  # -------------------------------------------------------------
  def self.area
    return TYPES['Area']
  end


  # -------------------------------------------------------------
  def self.language
    return TYPES['Language']
  end


  # -------------------------------------------------------------
  def self.skill
    return TYPES['Skill']
  end


  #~ Private instance methods .................................................
  private

  # -------------------------------------------------------------
  def standardize_tag
    if self.tag_name
      # remove pre-/post- and replace in-whitespace make lower-case only
      self.tag_name = self.class.normalize(self.tag_name)
    end
  end


  # -------------------------------------------------------------
  def standardize_tagtype
    if self.tagtype.nil? || self.tagtype >= TYPES.length || self.tagtype < 0
      self.tagtype = 0
    end
  end

end
