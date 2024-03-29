module ApplicationHelper
  include Pagy::Frontend

  # Generates button tags for Turbo disable with
  # Preserve opacity-25 opacity-75 during purge
  def button_text(text = nil, disable_with: t("processing"), &block)
    text = capture(&block) if block

    tag.span(text, class: "when-enabled") +
      tag.span(class: "when-disabled") do
        render_svg("icons/spinner", styles: "animate-spin inline-block h-4 w-4 mr-2") + disable_with
      end
  end

  def disable_with(text)
    "<i class=\"far fa-spinner-third fa-spin\"></i> #{text}".html_safe
  end

  def render_svg(name, options = {})
    options[:title] ||= name.underscore.humanize
    options[:aria] = true
    options[:nocomment] = true
    options[:class] = options.fetch(:styles, "fill-current text-gray-500")

    filename = "#{name}.svg"
    inline_svg_tag(filename, options)
  end

  # fa_icon "thumbs-up", weight: "fa-solid"
  # <i class="fa-solid fa-thumbs-up"></i>
  def fa_icon(name, options = {})
    weight = options.delete(:weight) || "fa-regular"
    options[:class] = [weight, "fa-#{name}", options.delete(:class)]
    tag.i(nil, **options)
  end

  def badge(text, options = {})
    base = options.delete(:base) || "rounded py-0.5 px-2 text-xs inline-block font-semibold leading-normal mr-2"
    color = options.delete(:color) || "bg-gray-100 text-gray-800"
    options[:class] = Array.wrap(options[:class]) + [base, color]
    tag.div(text, **options)
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def viewport_meta_tag(content: "width=device-width, initial-scale=1", turbo_native: "maximum-scale=1.0, user-scalable=0")
    full_content = [content, (turbo_native if turbo_native_app?)].compact.join(", ")
    tag.meta name: "viewport", content: full_content
  end

  def first_page?
    @pagy.page == 1
  end

  def yes_no(a_boolean)
    a_boolean ? "yes" : "no"
  end

  def int_appointment_hightlight?
    if current_page?("/interpreters/public") || current_page?("/interpreters/my_assigned") || current_page?("/interpreters/my_scheduled") || current_page?("/interpreters/appointments")
      highlighted
    else
      unhighlighted
    end
  end

  def int_appointment_highlight_icon?
    if current_page?(root_path) || current_page?(appointments_interpreters_path)
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def highlighted_classes_lookup
    {
      highlighted: {
        link: highlighted,
        icon: highlighted_icon
      },
      unhighlighted: {
        link: unhighlighted,
        icon: unhighlighted_icon
      }
    }.with_indifferent_access
  end

  def sidenav_highlight? controller_name, action_names = nil, options = {}
    nav_type = options[:type]
    action_names = "index" if action_names.blank?
    current_controller_action = Array.wrap(action_names).include?(controller.action_name) unless action_names.blank?

    if controller_name == controller.controller_name && current_controller_action
      highlighted_classes_lookup[:highlighted][nav_type]
    else
      highlighted_classes_lookup[:unhighlighted][nav_type]
    end
  end

  def sidenav_highlight_icon?(controller_name)
    if controller_name == controller.controller_name
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def dashboard_highlight?
    if current_page?("/dashboard") || current_page?(root_path) || current_page?(agencies_path) || current_page?(agency_detail_form_path) || current_page?(interpreter_dashboard_path)
      highlighted
    else
      unhighlighted
    end
  end

  def int_dashboard_highlight?
    if current_page?(root_path) || current_page?(interpreter_dashboard_path)
      highlighted
    else
      unhighlighted
    end
  end

  def int_time_off_highlight?
    if current_page?(root_path) || current_page?(interpreters_time_off_path)
      highlighted
    else
      unhighlighted
    end
  end

  def int_income_hightlight?
    if current_page?(income_interpreters_path)
      highlighted
    else
      unhighlighted
    end
  end

  def dashboard_highlight_icon?
    if current_page?("/dashboard") || current_page?(root_path) || controller_name == "agencies" || current_page?(interpreter_dashboard_path)
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def int_dashboard_highlight_icon?
    if current_page?(root_path) || current_page?(interpreter_dashboard_path)
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def system_admin_highlight?
    if controller_name == "sites" || controller_name == "customers" || controller_name == "languages" || controller_name == "customer_categories" ||
        controller_name == "checklist_types"
      highlighted
    else
      unhighlighted
    end
  end

  def system_admin_highlight_icon?
    if controller_name == "sites" || controller_name == "customers" || controller_name == "languages" || controller_name == "customer_categories" ||
        controller_name == "checklist_types"
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def accounts_mgmt_highlight?
    if controller_name == "requestors" || controller_name == "interpreters" || controller_name == "providers" || controller_name == "recipients" ||
        controller_name == "checklist_items"
      highlighted
    else
      unhighlighted
    end
  end

  def accounts_mgmt_highlight_icon?
    if controller_name == "requestors" || controller_name == "interpreters" || controller_name == "providers" || controller_name == "recipients" ||
        controller_name == "checklist_items"
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def accounting_highlight?
    if controller_name == "process_batches" && action_name == "new"
      highlighted
    elsif controller_name == "process_batches" && action_name == "index"
      highlighted
    else
      unhighlighted
    end
  end

  def accounting_highlight_icon?
    if controller_name == "process_batches" && action_name == "new"
      highlighted_icon
    elsif controller_name == "process_batches" && action_name == "index"
      highlighted_icon
    else
      unhighlighted_icon
    end
  end

  def highlighted
    "bg-gray-100 text-gray-900"
  end

  def highlighted_icon
    "text-gray-9"
  end

  def unhighlighted
    "text-gray-100 hover:bg-gray-50 hover:text-gray-900"
  end

  def unhighlighted_icon
    "text-gray-100 group-hover:text-gray-500"
  end

  # <!-- Current: "border-indigo-500 text-indigo-600", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
  def active_tab
    "border-tokanisecondary-500 text-tokanisecondary-600"
  end

  def inactive_tab
    "border-transparent text-gray-500 hover:border-tokanisecondary-300 hover:text-tokanisecondary-700"
  end

  def appointment_start_date_and_time_in_user_time_zone(appointment, user)
    starts_at = appointment.start_time_in_zone(user.time_zone)
    starts_at.strftime("%B %-d at %l:%M %p")
  end

  def appointment_finish_time_in_user_time_zone(appointment, user)
    finish_at = appointment.finish_time.in_time_zone(user.time_zone)
    finish_at.strftime("%B %-d at %l:%M %p")
  end

  def lpad_number(number)
    return "00" if number.nil?
    format("%02d", number)
  end

  def date_displayable(date)
    date.to_date.strftime("%b. %-d %Y")
  end

  def scheduled_time_range(appointment, user)
    start_time = appointment.start_time.in_time_zone(user.time_zone)
    end_time = appointment.end_time.in_time_zone(user.time_zone)

    [start_time.strftime("%l:%M%p"), end_time.strftime("%l:%M%p")].join(" - ")
  end

  def time_zone_select_options
    [
      ["(GMT-08:00) Pacific Time (US & Canada)", "Pacific Time (US & Canada)"],
      ["(GMT-07:00) Mountain Time (US & Canada)", "Mountain Time (US & Canada)"],
      ["(GMT-06:00) Central Time (US & Canada)", "Central Time (US & Canada)"],
      ["(GMT-05:00) Eastern Time (US & Canada)", "Eastern Time (US & Canada)"],
      ["(GMT-10:00) Hawaii", "Pacific/Honolulu"],
      ["(GMT-09:00) Alaska", "America/Juneau"]
    ]
  end

  def selected_time_zones(new_agency, time_zones)
    if new_agency
      ""
    else
      "data-multiselect-selected-value='#{time_zones.to_json}'"
    end
  end

  def state_select_options
    [
      ["Select a State", ""],
      ["Alabama", "AL"],
      ["Alaska", "AK"],
      ["Arizona", "AZ"],
      ["Arkansas", "AR"],
      ["California", "CA"],
      ["Colorado", "CO"],
      ["Connecticut", "CT"],
      ["Delaware", "DE"],
      ["District Of Columbia", "DC"],
      ["Florida", "FL"],
      ["Georgia", "GA"],
      ["Hawaii", "HI"],
      ["Idaho", "ID"],
      ["Illinois", "IL"],
      ["Indiana", "IN"],
      ["Iowa", "IA"],
      ["Kansas", "KS"],
      ["Kentucky", "KY"],
      ["Louisiana", "LA"],
      ["Maine", "ME"],
      ["Maryland", "MD"],
      ["Massachusetts", "MA"],
      ["Michigan", "MI"],
      ["Minnesota", "MN"],
      ["Mississippi", "MS"],
      ["Missouri", "MO"],
      ["Montana", "MT"],
      ["Nebraska", "NE"],
      ["Nevada", "NV"],
      ["New Hampshire", "NH"],
      ["New Jersey", "NJ"],
      ["New Mexico", "NM"],
      ["New York", "NY"],
      ["North Carolina", "NC"],
      ["North Dakota", "ND"],
      ["Ohio", "OH"],
      ["Oklahoma", "OK"],
      ["Oregon", "OR"],
      ["Pennsylvania", "PA"],
      ["Rhode Island", "RI"],
      ["South Carolina", "SC"],
      ["South Dakota", "SD"],
      ["Tennessee", "TN"],
      ["Texas", "TX"],
      ["Utah", "UT"],
      ["Vermont", "VT"],
      ["Virginia", "VA"],
      ["Washington", "WA"],
      ["West Virginia", "WV"],
      ["Wisconsin", "WI"],
      ["Wyoming", "WY"]
    ]
  end

  def toggle_is_active_on_or_off(is_active)
    is_active ? "off" : "on"
  end

  def resource_classes
    {
      active: {
        btn: "bg-tokanisecondary-600 border-double border-4",
        content: "right-1",
        icon: fa_icon("circle-check", class: "text-tokanisecondary-600 h-5 flex m-auto")
      },
      inactive: {
        btn: "bg-slate-200",
        content: "left-1",
        icon: fa_icon("circle-xmark", class: "text-slate-400 h-5 flex m-auto")
      }
    }
  end

  def toggle_is_active_button_for resource, path
    btn_class = resource.is_active ? resource_classes[:active][:btn] : resource_classes[:inactive][:btn]
    content_class = resource.is_active ? resource_classes[:active][:content] : resource_classes[:inactive][:content]
    icon_class = resource.is_active ? resource_classes[:active][:icon] : resource_classes[:inactive][:icon]

    button_to(
      path,
      method: :patch,
      data: {
        turbo_confirm: "Are you sure you want to turn #{resource.try(:name) || "this"} #{toggle_is_active_on_or_off(resource.is_active)}?",
        turbo: true
      },
      class: "#{btn_class} block w-14 h-8 rounded-full"
    ) do
      content_tag(:div, class: " absolute #{content_class} top-1 bg-white w-6 h-6 rounded-full transition flex") do
        icon_class
      end
    end
  end

  def appointment_info(appointment, time_zone)
    "#{appointment&.ref_number} - #{appointment&.start_datetime_string_in_zone(time_zone)} - #{appointment&.language&.name} - #{appointment&.customer&.name}"
  end

  def format_date_time(date_time)
    date_time.strftime("%B %-d at %I:%M %p (%Z)")
  end
end
