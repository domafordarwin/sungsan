module Maskable
  extend ActiveSupport::Concern

  class_methods do
    def maskable_fields(*fields)
      @maskable_fields = fields
      fields.each do |field|
        define_method("masked_#{field}") do
          Maskable.mask_value(field, send(field), Current.user)
        end
      end
    end

    def get_maskable_fields
      @maskable_fields || []
    end
  end

  def self.mask_value(field, value, current_user)
    return value if value.blank?
    return value if current_user&.admin?

    case field
    when :phone
      mask_phone(value)
    when :email
      mask_email(value)
    when :birth_date
      mask_date(value)
    else
      "***"
    end
  end

  def self.mask_phone(phone)
    return phone if phone.blank?
    phone.gsub(/(\d{3})-(\d{3,4})-(\d{4})/, '\1-****-\3')
  end

  def self.mask_email(email)
    return email if email.blank?
    local, domain = email.split("@")
    "#{local[0..1]}***@#{domain}"
  end

  def self.mask_date(date)
    return date if date.blank?
    date.strftime("%Y-**-**")
  end
end
