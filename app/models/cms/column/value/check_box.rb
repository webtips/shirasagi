class Cms::Column::Value::CheckBox < Cms::Column::Value::Base
  field :values, type: SS::Extensions::Words

  permit_values values: []

  liquidize do
    export :value
    export :values
  end

  def value
    values.join(', ')
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:values)
        self.values = value.to_s.split(",").map(&:strip)
      end
    end
  end

  def import_csv_cell(value)
    self.values = value.to_s.split("\n").filter_map { |v| v.strip }
  end

  def export_csv_cell
    values.join("\n")
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && values.blank?
      self.errors.add(:values, :blank)
    end

    return if values.blank?

    diff = values - column.select_options
    if diff.present?
      self.errors.add(:values, :inclusion, value: diff.join(', '))
    end
  end
end
