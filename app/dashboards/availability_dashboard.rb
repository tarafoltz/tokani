require "administrate/base_dashboard"

class AvailabilityDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    backport_id: Field::Number,
    end_seconds: Field::Number,
    in_person: Field::Boolean,
    interpreter: Field::BelongsTo,
    phone: Field::Boolean,
    start_seconds: Field::Number,
    time_zone: Field::String,
    user_id: Field::String,
    video: Field::Boolean,
    wday: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    backport_id
    end_seconds
    in_person
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    backport_id
    end_seconds
    in_person
    interpreter
    phone
    start_seconds
    time_zone
    user_id
    video
    wday
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    backport_id
    end_seconds
    in_person
    interpreter
    phone
    start_seconds
    time_zone
    user_id
    video
    wday
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how availabilities are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(availability)
  #   "Availability ##{availability.id}"
  # end
end
